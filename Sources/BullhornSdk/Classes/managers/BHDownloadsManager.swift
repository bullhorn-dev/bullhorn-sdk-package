import Foundation
import UserNotifications
import AVFoundation

// MARK: - UI grouping (unchanged)

enum DownloadDate: Int, Comparable {
    case today = 0
    case yesterday
    case week
    case month
    case year
    case earlier

    func prettyString() -> String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        case .earlier: return "Earlier"
        }
    }

    static func < (lhs: DownloadDate, rhs: DownloadDate) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct UIDownloadsModel {
    let date: DownloadDate
    let posts: [BHPost]
}

protocol BHDownloadsManagerListener: ObserverProtocol {
    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem)
    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem)
    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool)
    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager)
}

// MARK: - BHDownloadsManager
//
// Threading: main-confined. The in-memory `downloadsQueue` is a cache for sync
// reads (getFileUrl / isPostDownloaded / item(for:)); the source of truth is the
// DB, because the process can be killed and relaunched mid-download. All public
// mutations and all URLSession delegate callbacks run on main (delegate callbacks
// hop via DispatchQueue.main.async). Debug builds assert the contract.
//
// Download model: ONE active background download at a time (variant A). The rest
// stay `.pending` in the DB; the next is started from the completion callback, so
// the sequence survives a process restart. Manual downloads take priority over
// auto in selection but never preempt the active one. Auto downloads run on WiFi
// only (per-request allowsCellularAccess = false + a WiFi gate in selection).

final class BHDownloadsManager: NSObject {

    static let shared = BHDownloadsManager()

    private(set) var isLoaded = false

    private let autoDownloadsMaxCount = 10

    /// Set from AppDelegate's handleEventsForBackgroundURLSession(_:completionHandler:).
    var backgroundCompletionHandler: (() -> Void)?

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHDownloadsManagerListener>
    private let workingQueue = DispatchQueue(label: "BHDownloadsManager.Working", target: .global())

    /// Main-confined cache (see class note).
    private var downloadsQueue = [BHDownloadItem]()

    /// ids of currently-running session tasks (0 or 1 under variant A).
    private var activeDownloadIds = Set<String>()

    /// Last progress value forwarded to the main thread, per task id. Confined to
    /// the URLSession delegate queue (serial), so didWriteData can throttle BEFORE
    /// hopping to main instead of dispatching every byte-level callback. NOT main.
    private var lastReportedProgress = [String: Double]()

    private static let sessionIdentifier = "com.bullhorn.downloads.background"

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        cfg.sessionSendsLaunchEvents = true
        cfg.isDiscretionary = false
        cfg.allowsCellularAccess = true   // real gate is per-request (auto = false)
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    // MARK: Init

    override init() {
        observersContainer = .init(notifyQueue: workingQueue)
        super.init()

        NotificationCenter.default.addObserver(
            self, selector: #selector(onConnectionChangedNotification(notification:)),
            name: BHReachabilityManager.ConnectionChangedNotification, object: nil)

        // Touch the session so it reconnects to any tasks still running from a
        // previous launch and begins delivering their delegate callbacks.
        _ = session
    }

    @inline(__always)
    private func assertMain() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }

    // MARK: - Listeners

    func addListener(_ listener: BHDownloadsManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHDownloadsManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    private func notifyState(_ item: BHDownloadItem) {
        observersContainer.notifyObserversAsync { $0.downloadsManager(self, itemStateUpdated: item) }
    }

    private func notifyProgress(_ item: BHDownloadItem) {
        observersContainer.notifyObserversAsync { $0.downloadsManager(self, itemProgressUpdated: item) }
    }

    private func notifyItemsUpdated() {
        observersContainer.notifyObserversAsync { $0.downloadsManagerItemsUpdated(self) }
    }

    // MARK: - Reads (main-confined)

    var items: [BHDownloadItem] {
        assertMain()
        return downloadsQueue.sorted { $0.time > $1.time }
    }

    var completedItems: [BHDownloadItem] {
        assertMain()
        return downloadsQueue.filter { $0.status.isSuccess() }.sorted { $0.time > $1.time }
    }

    func item(for postId: String) -> BHDownloadItem? {
        assertMain()
        return cachedItem(postId)
    }

    func hasActiveDownloads() -> Bool {
        assertMain()
        return !activeDownloadIds.isEmpty
    }

    func isPostDownloaded(_ postId: String) -> Bool {
        assertMain()
        return getFileUrl(postId) != nil   // single source of truth: file must exist
    }

    /// Resolves the local file by rebuilding from the *current* Documents dir,
    /// because the sandbox container prefix changes between launches and a stored
    /// absolute path goes stale.
    func getFileUrl(_ postId: String) -> URL? {
        assertMain()
        return resolvedFileURL(for: cachedItem(postId)?.file)
    }

    /// Single place that maps a stored file URL to its current on-disk location.
    /// Rebuilds the path against the *current* Documents dir (the sandbox prefix
    /// changes between launches) and returns it only if the file actually exists.
    private func resolvedFileURL(for stored: URL?) -> URL? {
        guard let stored else { return nil }
        let fileName = stored.lastPathComponent
        guard let resolved = FileManager.default.documentsDirectory()?.appendingPathComponent(fileName),
              FileManager.default.fileExists(atPath: resolved.path) else {
            return nil
        }
        return resolved
    }

    private func cachedItem(_ id: String) -> BHDownloadItem? {
        downloadsQueue.first { $0.id == id }
    }

    // MARK: - Loading & reconciliation

    func updateItems(completion: (() -> Void)? = nil) {
        if isLoaded {
            groupItems()
            completion?()
        } else {
            load(completion: completion)
        }
    }

    func load(completion: (() -> Void)? = nil) {
        DataBaseManager.shared.fetchDownloads { [weak self] items in
            DispatchQueue.main.async {
                guard let self else { return }
                self.downloadsQueue = items
                self.groupItems()
                self.isLoaded = true
                self.reconcileWithSession {
                    completion?()
                    self.pumpQueue()
                }
            }
        }
    }

    /// After a relaunch, items the DB marked `.progress` whose background task is
    /// no longer alive (process was killed before it finished) must be demoted to
    /// `.pending` so the pump restarts them.
    private func reconcileWithSession(_ completion: @escaping () -> Void) {
        session.getAllTasks { [weak self] tasks in
            DispatchQueue.main.async {
                guard let self else { return }
                let liveIds = Set(tasks.compactMap { $0.taskDescription })
                self.activeDownloadIds = liveIds

                for item in self.downloadsQueue where item.status == .progress && !liveIds.contains(item.id) {
                    item.status = .pending
                    self.updateStorageItem(item)
                }
                completion()
            }
        }
    }

    // MARK: - Sequential queue

    private func pumpQueue() {
        assertMain()
        guard activeDownloadIds.isEmpty else { return }       // one at a time
        guard let next = nextPending() else { return }
        startDownload(next)
    }

    private func nextPending() -> BHDownloadItem? {
        let connected = BHReachabilityManager.shared.isConnected()
        let onWifi = connected && !BHReachabilityManager.shared.isConnectedExpensive()

        let candidates = downloadsQueue.filter { item in
            guard item.status.isPending() else { return false }
            // auto only on WiFi; manual on any connection
            return item.reason == .auto ? onWifi : connected
        }

        // manual before auto; within a group, oldest queued first (FIFO)
        return candidates.sorted { lhs, rhs in
            if lhs.reason != rhs.reason { return lhs.reason == .manually }
            return lhs.time < rhs.time
        }.first
    }

    private func startDownload(_ item: BHDownloadItem) {
        assertMain()

        var request = URLRequest(url: item.url)
        request.allowsCellularAccess = (item.reason == .manually)   // auto = WiFi only

        let task = session.downloadTask(with: request)
        task.taskDescription = item.id

        activeDownloadIds.insert(item.id)
        item.status = .progress
        item.prevStatus = .pending
        item.progress = 0
        updateStorageItem(item)
        groupItems()
        notifyState(item)

        showActiveDownloadNotification(for: item)

        BHLog.p("Start download \(item.id) reason:\(item.reason) cellular:\(request.allowsCellularAccess)")
        task.resume()
    }

    // MARK: - Active download notification
    //
    // One persistent local notification tracks the single active download (variant
    // A). It's shown at 0% on start, its body is updated on each throttled progress
    // tick (~5% steps), and it's removed when the active download finishes and no
    // other download takes its place. A stable identifier in BHNotificationsManager
    // makes every update replace the same notification in place.

    /// Start path: request authorization once, then show the notification at 0%.
    /// Start path: show at 0% if notifications are already allowed; if the user
    /// hasn't decided yet, opt in *provisionally* (no system prompt, quiet
    /// delivery) and then show. Never re-prompts and never shows when denied.
    private func showActiveDownloadNotification(for item: BHDownloadItem) {
        guard UserDefaults.standard.isPushNotificationsFeatureEnabled else { return }
        let post = item.post
        let itemId = item.id
        let center = UNUserNotificationCenter.current()

        // The auth check is async; by the time it returns the download may already
        // have finished (e.g. a fast/cached file). Only show if it's still active —
        // otherwise we'd publish a notification with nothing left to remove it.
        let presentIfStillActive = { [weak self] in
            DispatchQueue.main.async {
                guard let self, self.activeDownloadIds.contains(itemId) else { return }
                BHNotificationsManager.shared.showDownloadEpisodeNotification(for: post, progress: 0)
            }
        }

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                presentIfStillActive()
            case .notDetermined:
                center.requestAuthorization(options: [.provisional]) { granted, _ in
                    guard granted else { return }
                    presentIfStillActive()
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    /// Progress path: silent in-place update, no authorization round-trip.
    private func updateActiveDownloadNotification(for item: BHDownloadItem) {
        guard UserDefaults.standard.isPushNotificationsFeatureEnabled else { return }
        BHNotificationsManager.shared.showDownloadEpisodeNotification(for: item.post, progress: item.progress)
    }

    private func removeActiveDownloadNotification() {
        guard UserDefaults.standard.isPushNotificationsFeatureEnabled else { return }
        BHNotificationsManager.shared.removeDownloadEpisodeNotification()
    }

    /// Removes the notification with a short guarded retry. Immediate-trigger
    /// notifications deliver asynchronously, so a show submitted moments earlier
    /// (e.g. the last progress tick) can land just AFTER the removal and linger.
    /// The retry only fires if nothing became active in the meantime, so it never
    /// clobbers a freshly started download's notification.
    private func clearActiveDownloadNotification() {
        removeActiveDownloadNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, self.activeDownloadIds.isEmpty else { return }
            self.removeActiveDownloadNotification()
        }
    }

    // MARK: - Public: download / remove

    func download(_ post: BHPost, reason: DownloadReason = .manually) {
        assertMain()

        guard let recordingUrl = post.recording?.publishUrl else {
            BHLog.w("Download failed: recording url is empty")
            return
        }

        if reason == .auto { enforceAutoLimit() }

        if let existing = cachedItem(post.id) {
            // re-download (typically from .failure): reset to pending
            existing.prevStatus = existing.status
            existing.status = .pending
            existing.progress = 0
            existing.file = nil
            updateStorageItem(existing)
            notifyState(existing)
        } else {
            let item = BHDownloadItem(
                id: post.id, post: post, status: .pending, prevStatus: .start,
                reason: reason, progress: 0, url: recordingUrl, file: nil,
                time: Date().timeIntervalSince1970)
            downloadsQueue.append(item)
            insertStorageItem(item)
            notifyState(item)
        }

        groupItems()

        let request = BHTrackEventRequest.createRequest(
            category: .explore, action: .ui, banner: .downloadEpisode,
            context: post.shareLink.absoluteString,
            podcastId: post.user.id, podcastTitle: post.user.fullName,
            episodeId: post.id, episodeTitle: post.title)
        BHTracker.shared.trackEvent(with: request)

        pumpQueue()
    }

    func removeFromDownloads(_ post: BHPost) {
        assertMain()
        BHLog.p("Remove post from downloads: \(post.id)")
        guard let item = cachedItem(post.id) else { return }
        remove(item, resetStateForListeners: true)
    }

    func removeAutoDownloads(for user: BHUser) {
        assertMain()
        BHLog.p("Remove auto downloads for user id: \(user.id)")
        let toRemove = downloadsQueue.filter { $0.post.user.id == user.id && $0.reason == .auto }
        toRemove.forEach { remove($0, resetStateForListeners: true) }
    }

    func removeAll() {
        assertMain()
        BHLog.p("Remove all downloads")

        cancelAll()
        for item in downloadsQueue { performRemoveDownload(item) }
        downloadsQueue.removeAll()
        activeDownloadIds.removeAll()
        groupItems()
        clearActiveDownloadNotification()

        observersContainer.notifyObserversAsync { $0.downloadsManager(self, allRemoved: true) }
    }

    /// Removes a single item: cancels its task if active (fixes the "zombie"
    /// re-appearing download), deletes the file, removes from DB and cache, then
    /// pumps in case a slot freed.
    private func remove(_ item: BHDownloadItem, resetStateForListeners: Bool) {
        cancelTask(for: item.id)
        performRemoveDownload(item)
        downloadsQueue.removeAll { $0.id == item.id }
        activeDownloadIds.remove(item.id)

        if resetStateForListeners {
            item.status = .start
            item.file = nil
            notifyState(item)
        }
        groupItems()
        pumpQueue()

        // If the removed item was the active download and nothing replaced it,
        // drop its notification (otherwise the new startDownload already replaced it).
        if activeDownloadIds.isEmpty {
            clearActiveDownloadNotification()
        }
    }

    /// Evicts the oldest auto downloads so a new auto fits under the limit.
    /// Counts ALL auto items (pending / in-progress / success).
    private func enforceAutoLimit() {
        assertMain()
        let autos = downloadsQueue.filter { $0.reason == .auto }
        guard autos.count >= autoDownloadsMaxCount else { return }

        let overflow = autos.count - autoDownloadsMaxCount + 1   // room for the incoming one
        let oldest = autos.sorted { $0.time < $1.time }.prefix(overflow)
        oldest.forEach { remove($0, resetStateForListeners: true) }
    }

    // MARK: - Auto downloads

    func autoDownloadNewEpisodeIfNeeded(_ post: BHPost) {
        assertMain()
        BHLog.p("\(#function), postId: \(post.id)")
        guard UserDefaults.standard.isAutoDownloadsFeatureEnabled else { return }
        guard post.user.autoDownload, !post.isDownloaded else { return }
        // No reachability check here: auto tasks are WiFi-gated per-request and in
        // selection, so they simply sit pending until WiFi is available.
        download(post, reason: .auto)
    }

    func autoDownloadNewEpisodesIfNeeded() {
        assertMain()
        BHLog.p("\(#function)")
        guard UserDefaults.standard.isAutoDownloadsFeatureEnabled else { return }

        BHFeedManager.shared.getFeedActualPosts { [weak self] response in
            DispatchQueue.main.async {
                guard let self else { return }
                switch response {
                case .success(posts: let posts):
                    for post in posts where post.user.autoDownload && !post.isDownloaded {
                        self.download(post, reason: .auto)   // enforceAutoLimit runs inside
                    }
                case .failure(error: let error):
                    BHLog.w("\(#function) - \(error)")
                }
            }
        }
    }

    func restartFailedItemsIfNeeded() {
        assertMain()
        BHLog.p("\(#function)")
        guard BHReachabilityManager.shared.isConnected() else { return }

        for item in downloadsQueue where item.status.isFailed() {
            item.prevStatus = item.status
            item.status = .pending
            updateStorageItem(item)
            notifyState(item)
        }
        pumpQueue()
    }

    // MARK: - Post updates

    func updatePost(_ post: BHPost) {
        assertMain()
        guard let item = cachedItem(post.id) else { return }
        item.post = post
        updateStorageItem(item)
        groupItems()
        notifyItemsUpdated()
    }

    /// `BHDownloadItem` is a reference type, so mutating `item.post` already
    /// updates the cached element; only persistence needs an explicit call.
    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        assertMain()
        guard let item = cachedItem(postId) else { return }
        item.post.updatePlaybackOffset(offset, completed: completed)
        updateStorageItem(item)
    }

    // MARK: - Task cancellation

    private func cancelTask(for id: String) {
        session.getAllTasks { tasks in
            tasks.first { $0.taskDescription == id }?.cancel()
        }
    }

    private func cancelAll() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    private func performRemoveDownload(_ item: BHDownloadItem) {
        if let resolved = resolvedFileURL(for: item.file) {
            try? FileManager.default.removeItem(at: resolved)
        }
        removeStorageItem(item.id)
    }

    // MARK: - UI grouping

    let calendar = Calendar.current
    var groupedItems: [UIDownloadsModel] = []

    func groupItems() {
        assertMain()
        let sorted = downloadsQueue.sorted { $0.time > $1.time }
        let now = Date()
        var grouped: [DownloadDate: [BHDownloadItem]] = [:]

        for item in sorted {
            let date = Date(timeIntervalSince1970: item.time)
            let key: DownloadDate
            if calendar.isDateInToday(date) { key = .today }
            else if calendar.isDateInYesterday(date) { key = .yesterday }
            else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) { key = .week }
            else if calendar.isDate(date, equalTo: now, toGranularity: .month) { key = .month }
            else if calendar.isDate(date, equalTo: now, toGranularity: .year) { key = .year }
            else { key = .earlier }
            grouped[key, default: []].append(item)
        }

        groupedItems = grouped
            .map { UIDownloadsModel(date: $0.key, posts: $0.value.map { $0.post }) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Notifications

    @objc private func onConnectionChangedNotification(notification: Notification) {
        guard let info = (notification.userInfo as? [String: BHReachabilityManager.ConnectionChangedNotificationInfo])?[BHReachabilityManager.NotificationInfoKey] else { return }
        switch info.type {
        case .connected:
            DispatchQueue.main.async {
                self.restartFailedItemsIfNeeded()   // demotes failures → pending, then pumps
                self.pumpQueue()                    // also picks up auto waiting for WiFi
            }
        default:
            break
        }
    }

    // MARK: - Storage Providers

    private func insertStorageItem(_ item: BHDownloadItem) {
        if !DataBaseManager.shared.insertOrUpdateDownloadItem(with: item) {
            BHLog.w("\(#function) - failed to insert download item")
        }
    }

    private func updateStorageItem(_ item: BHDownloadItem) {
        if !DataBaseManager.shared.updateDownloadItem(with: item) {
            BHLog.w("\(#function) - failed to update download item")
        }
    }

    private func removeStorageItem(_ id: String) {
        if !DataBaseManager.shared.removeDownloadItem(with: id) {
            BHLog.w("\(#function) - failed to remove download item")
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BHDownloadsManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        guard let id = downloadTask.taskDescription else { return }

        // Throttle on the (serial) delegate queue. didWriteData fires per chunk —
        // dispatching each one to main floods the run loop and janks anything
        // animating there (e.g. an options dialog). Only cross to main on a real
        // ~5% step (or the final tick).
        let last = lastReportedProgress[id] ?? 0
        guard progress - last > 0.05 || progress >= 1 else { return }
        lastReportedProgress[id] = progress

        DispatchQueue.main.async { [weak self] in
            guard let self, let item = self.cachedItem(id) else { return }
            item.progress = progress
            self.notifyProgress(item)
            // Skip the 100% tick: it would sit right before the completion
            // removal and, delivering asynchronously, could outlive it.
            if progress < 1 {
                self.updateActiveDownloadNotification(for: item)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Runs on the URLSession delegate queue (background). The temp file at
        // `location` is deleted right after this returns, so everything here is
        // synchronous. We:
        //   1. move the temp file to a staging path named with a best-guess
        //      container extension (so AVAsset can parse it),
        //   2. inspect it for a video track (ground truth — works offline, off-main),
        //   3. finalize the name (.mp4 for video) so the player recognizes the type.
        guard let id = downloadTask.taskDescription else { return }
        guard let docs = FileManager.default.documentsDirectory() else { return }

        let sourceExt = downloadTask.originalRequest?.url?.pathExtension
        let mime = downloadTask.response?.mimeType

        let guessExt = containerExtension(sourceExt: sourceExt, mime: mime)
        let staging = docs.appendingPathComponent("\(id).\(guessExt)")
        do {
            if FileManager.default.fileExists(atPath: staging.path) {
                try FileManager.default.removeItem(at: staging)
            }
            try FileManager.default.moveItem(at: location, to: staging)
        } catch {
            BHLog.w("Failed to stage downloaded file for \(id): \(error)")
            return
        }

        // Safe to block here: this is the background delegate queue, not main.
        let hasVideo = Self.hasVideoTrack(at: staging)
        let videoExts = ["mp4", "m4v", "mov"]
        let finalExt = hasVideo ? (videoExts.contains(guessExt) ? guessExt : "mp4") : guessExt

        var movedURL: URL? = staging
        if finalExt != guessExt {
            let dest = docs.appendingPathComponent("\(id).\(finalExt)")
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.moveItem(at: staging, to: dest)
                movedURL = dest
            } catch {
                BHLog.w("Failed to finalize downloaded file for \(id): \(error)")
            }
        }

        let resolved = movedURL
        DispatchQueue.main.async { [weak self] in
            guard let self, let item = self.cachedItem(id) else {
                if let resolved { try? FileManager.default.removeItem(at: resolved) }
                return
            }
            item.file = resolved   // nil never happens here; didComplete reads it
        }
    }

    /// Best-guess container extension from the source URL / MIME, used to name the
    /// staging file so AVAsset can parse it. Audio stays as-is; the final video
    /// decision is made by hasVideoTrack(at:).
    private func containerExtension(sourceExt: String?, mime: String?) -> String {
        let known = ["mp4", "m4v", "mov", "mp3", "m4a", "aac", "wav"]
        if let src = sourceExt?.lowercased(), known.contains(src) { return src }
        if let mime = mime?.lowercased() {
            if mime.contains("video") { return "mp4" }
            if mime.contains("audio") { return "mp3" }
        }
        return "mp4"   // permissive default: ISO container parses, audio falls back below
    }

    /// Ground-truth audio/video classification from the downloaded file itself.
    /// Blocks until the (local) asset's tracks load — call only off the main thread.
    private static func hasVideoTrack(at url: URL) -> Bool {
        let asset = AVURLAsset(url: url)
        let semaphore = DispatchSemaphore(value: 0)
        var result = false

        if #available(iOS 15.0, *) {
            asset.loadTracks(withMediaType: .video) { tracks, _ in
                result = !(tracks?.isEmpty ?? true)
                semaphore.signal()
            }
        } else {
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                if asset.statusOfValue(forKey: "tracks", error: nil) == .loaded {
                    result = !asset.tracks(withMediaType: .video).isEmpty
                }
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .now() + 5)   // local file: returns quickly
        return result
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        let id = task.taskDescription

        // Delegate-queue cleanup of the throttle state before hopping to main.
        if let id { lastReportedProgress[id] = nil }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let id { self.activeDownloadIds.remove(id) }

            if let id, let item = self.cachedItem(id) {
                if let error {
                    // A cancel (manual removal) also lands here — the item is
                    // already gone from the cache, so this branch is skipped.
                    item.prevStatus = .progress
                    item.status = .failure
                    BHLog.w("Download failed \(id): \(error)")

                    let request = BHTrackEventRequest.createRequest(
                        category: .explore, action: .error, banner: .downloadFailed,
                        context: error.localizedDescription,
                        podcastId: item.post.user.id, podcastTitle: item.post.user.fullName,
                        episodeId: item.post.id, episodeTitle: item.post.title)
                    BHTracker.shared.trackEvent(with: request)
                } else if item.file != nil {
                    item.prevStatus = .progress
                    item.status = .success
                    item.progress = 1
                } else {
                    // completed without error but the file move failed
                    item.prevStatus = .progress
                    item.status = .failure
                }

                self.updateStorageItem(item)
                self.groupItems()
                self.notifyState(item)
            }

            // variant A: the next pending download starts here. If one does,
            // startDownload re-shows the notification for the new active item (same
            // identifier => replaced in place). If nothing is left running, drop it.
            self.pumpQueue()

            if self.activeDownloadIds.isEmpty {
                self.clearActiveDownloadNotification()
            }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}


