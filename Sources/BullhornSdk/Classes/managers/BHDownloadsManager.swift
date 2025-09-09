
import Foundation
internal import Alamofire

struct UIDownloadsModel {
    let date: Date
    let posts: [BHPost]
}

protocol BHDownloadsManagerListener: ObserverProtocol {
    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem)
    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem)
    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool)
    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager)
}

class BHDownloadsManager {
 
    static let shared = BHDownloadsManager()

    private let autoDownloadsMaxCount: Int = 10

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHDownloadsManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHDownloadsManager.Working", target: .global())

    let progressQueue = DispatchQueue(label: "com.alamofire.progressQueue", qos: .utility)
    
    fileprivate var downloadsQueue = [BHDownloadItem]()
    
    var items: [BHDownloadItem] {
        return downloadsQueue.sorted(by: { $0.time > $1.time })
    }
    
    var completedItems: [BHDownloadItem] {
        return downloadsQueue
            .filter({ $0.status.isSuccess() })
            .sorted(by: { $0.time > $1.time })
    }

    // MARK: - group items for UI

    let calendar = Calendar.current
    var groupedItems: [UIDownloadsModel] = []

    func groupItems() {
        groupedItems.removeAll()
        
        let items = downloadsQueue.sorted(by: { $0.time > $1.time })
        var models: [UIDownloadsModel] = []

        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: item.date)
        }
        
        for (date, values) in grouped {
            let uiModel = UIDownloadsModel(date: date,
                                           posts: values.sorted(by: { $0.post.validPublishedDate > $1.post.validPublishedDate }).map { $0.post })
            models.append(uiModel)
        }
        
        groupedItems = models.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Initialization
    
    init() {
        observersContainer = .init(notifyQueue: workingQueue)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
    }

    deinit {
        cancelAll()
    }

    // MARK: - Public listener

    func addListener(_ listener: BHDownloadsManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHDownloadsManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }
    
    // MARK: - Public SDK
    
    func hasActiveDouwnloads() -> Bool {
        return downloadsQueue.first(where: { $0.status.isFetching() }) != nil
    }
    
    // MARK: - Public
    
    func item(for postId: String) -> BHDownloadItem? {
        return downloadsQueue.first(where: { $0.post.id == postId })
    }

    func updateItems() {
        fetchStorageItems()
    }
    
    func updatePost(_ post: BHPost) {
        if let row = downloadsQueue.firstIndex(where: {$0.post.id == post.id}) {
            self.downloadsQueue[row].post = post
            self.updateStorageItem(self.downloadsQueue[row])
            
            self.observersContainer.notifyObserversAsync {
                $0.downloadsManagerItemsUpdated(self)
            }
        }
    }
    
    func autoDownloadNewEpisodeIfNeeded(_ post: BHPost) {
        BHLog.p("\(#function), postId: \(post.id)")
        
        if !UserDefaults.standard.isAutoDownloadsFeatureEnabled { return }
        
        if BHReachabilityManager.shared.isConnectedExpensive() || !BHReachabilityManager.shared.isConnected() {
            BHLog.p("\(#function) - connection expensive. Don't download the episode.")
            return
        }
        
        if post.user.autoDownload && !post.isDownloaded {
            self.download(post, reason: .auto)
        }
    }

    func autoDownloadNewEpisodesIfNeeded() {
        BHLog.p("\(#function)")

        if !UserDefaults.standard.isAutoDownloadsFeatureEnabled { return }

        if BHReachabilityManager.shared.isConnectedExpensive() || !BHReachabilityManager.shared.isConnected() {
            BHLog.p("\(#function) - connection expensive. Stop autodownloads.")
            return
        }

        BHFeedManager.shared.getFeedActualPosts() { response in
            switch response {
            case .success(posts: let posts):
                for post in posts {
                    if post.user.autoDownload && !post.isDownloaded {
                        self.clearAutoudownloadsIfNeeded()
                        self.download(post, reason: .auto)
                    }
                }
            case .failure(error: let error):
                BHLog.w("\(#function) - \(error)")
            }
        }
    }
    
    private func clearAutoudownloadsIfNeeded() {
        BHLog.p("\(#function)")
        
        let autoDownloadedQueue = self.downloadsQueue.filter({ $0.reason == .auto })
 
        if autoDownloadedQueue.count >= autoDownloadsMaxCount, let firstItem = autoDownloadedQueue.first {
            removeFromDownloads(firstItem.post)
        }
    }
    
    func download(_ post: BHPost, reason: DownloadReason = .manually) {
        
        guard let recordingUrl = post.recording?.publishUrl else {
            BHLog.w("Download failed: recording url is empty")
            return
        }

        BHLog.p("Download post: \(post.id), reason: \(reason), url: \(recordingUrl)")
        
        let time = Date().timeIntervalSince1970
        let downloadItem = BHDownloadItem(id: post.id, post: post, status: .start, prevStatus: .start, reason: reason, progress: 0, url: recordingUrl, file: nil, time: time)
        
        performDownload(downloadItem)
        fetchStorageItems()
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .downloadEpisode, context: post.shareLink.absoluteString, podcastId: post.user.id, podcastTitle: post.user.fullName, episodeId: post.id, episodeTitle: post.title)
        BHTracker.shared.trackEvent(with: request)
    }
    
    func removeFromDownloads(_ post: BHPost) {

        BHLog.p("Remove post from downloads: \(post.id)")

        if let item = downloadsQueue.first(where: { $0.post.id == post.id }) {

            performRemoveDownload(item)
            
            item.status = .start
            item.file = nil

            observersContainer.notifyObserversAsync {
                $0.downloadsManager(self, itemStateUpdated: item)
            }
        }

        fetchStorageItems()
    }
    
    func removeAutoDownloads(for user: BHUser) {

        BHLog.p("Remove auto downloads for user id: \(user.id)")

        let items = downloadsQueue.filter({ $0.post.user.id == user.id && $0.reason == .auto })

        if items.count > 0 {
            for item in items {
                performRemoveDownload(item)
                    
                item.status = .start
                item.file = nil
                    
                observersContainer.notifyObserversAsync {
                    $0.downloadsManager(self, itemStateUpdated: item)
                }
            }

            fetchStorageItems()
        }
    }
    
    func removeAll() {
        
        BHLog.p("Remove all downloads")

        for item in downloadsQueue {
            performRemoveDownload(item)
        }
        
        observersContainer.notifyObserversAsync {
            $0.downloadsManager(self, allRemoved: true)
        }

        fetchStorageItems()
    }
    
    func restartFailedItemsIfNeeded() {
        BHLog.p("\(#function)")
        
        if BHReachabilityManager.shared.isConnectedExpensive() {
            BHLog.p("\(#function) - expensive connection. Don't start.")
            return
        } else if BHReachabilityManager.shared.isConnected() {
            
            let failedItems = downloadsQueue.filter({ $0.status.isFailed() })
            
            failedItems.forEach({ item in
                performDownload(item)
            })
        }
    }

        
    func isPostDownloaded(_ postId: String) -> Bool {
        return downloadsQueue.contains(where: { $0.post.id == postId && $0.file != nil })
    }

    func getFileUrl(_ postId: String) -> URL? {
        if let item = downloadsQueue.first(where: { $0.post.id == postId }) {
            return item.file
        }
        return nil
    }
    
    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        if let item = downloadsQueue.first(where: { $0.post.id == postId }) {
            item.post.updatePlaybackOffset(offset, completed: completed)
            
            if let row = downloadsQueue.firstIndex(where: {$0.post.id == postId}) {
                DispatchQueue.main.async {
                    self.downloadsQueue[row] = item
                    self.updateStorageItem(item)
                }
            }
        }
    }

    // MARK: - Private
        
    fileprivate func performDownload(_ item: BHDownloadItem) {
        var prevProgress: Double = 0
        
        insertStorageItem(item)
        
        observersContainer.notifyObserversAsync {
            item.status = .progress
            $0.downloadsManager(self, itemStateUpdated: item)
        }
        
        BHID3Parser.isGoodForStream(item.url) { _, _, isVideo in

            let format = isVideo ? "mp4" : "mp3"

            let destination: DownloadRequest.Destination = { _, _ in
                var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                documentsURL.appendPathComponent("\(item.post.id).\(format)")
                return (documentsURL, [.removePreviousFile])
            }
            
            AF.download(item.url, to: destination)
                .downloadProgress(queue: self.progressQueue) { progress in
                    if progress.fractionCompleted - prevProgress > 0.05 {
                        prevProgress = progress.fractionCompleted
                        item.progress = progress.fractionCompleted

                        self.observersContainer.notifyObserversAsync {
                            $0.downloadsManager(self, itemProgressUpdated: item)
                        }
                    }
                }
                .responseData { response in
                    switch response.result {
                    case .success(_):
                        BHLog.p("Download success, destinationUrl: \(String(describing: response.fileURL))")
                        
                        item.status = .success
                        item.prevStatus = .progress
                        item.file = response.fileURL
                        item.progress = 1

                    case .failure(let error):
                        BHLog.w("Download failed: \(error)")

                        item.status = .failure
                        item.prevStatus = .progress
                        
                        /// track stats
                        let request = BHTrackEventRequest.createRequest(category: .explore, action: .error, banner: .downloadFailed, context: error.localizedDescription, podcastId: item.post.user.id, podcastTitle: item.post.user.fullName, episodeId: item.post.id, episodeTitle: item.post.title)
                        BHTracker.shared.trackEvent(with: request)
                    }

                    prevProgress = 0
                    
                    self.updateStorageItem(item)
                    self.fetchStorageItems()

                    self.observersContainer.notifyObserversAsync {
                        $0.downloadsManager(self, itemStateUpdated: item)
                    }
                }
        }
    }
    
    fileprivate func performRemoveDownload(_ item: BHDownloadItem) {

        if let fileURL = item.file {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(atPath: fileURL.path)
            }
        }
        
        removeStorageItem(item.id)
    }
        
    fileprivate func cancelAll() {
        // TODO: - cancel all download requests
    }
            
    // MARK: - Notifications
    
    @objc fileprivate func onConnectionChangedNotification(notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String : BHReachabilityManager.ConnectionChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHReachabilityManager.NotificationInfoKey] else { return }
        
        switch info.type {
        case .connected:
            restartFailedItemsIfNeeded()
        default:
            break
        }
    }
    
    // MARK: - Storage Providers
    
    fileprivate func fetchStorageItems() {
        DataBaseManager.shared.fetchDownloads() { items in
            self.downloadsQueue = items
            self.groupItems()
        }
    }

    fileprivate func fetchStorageItem(_ id: String) -> BHDownloadItem? {
        return DataBaseManager.shared.fetchDownloadItem(with: id)
    }

    fileprivate func insertStorageItem(_ item: BHDownloadItem) {
        if !DataBaseManager.shared.insertOrUpdateDownloadItem(with: item) {
            BHLog.w("\(#function) - failed to insert download item")
        }
    }

    fileprivate func updateStorageItem(_ item: BHDownloadItem) {
        if !DataBaseManager.shared.updateDownloadItem(with: item) {
            BHLog.w("\(#function) - failed to update download item")
        }
    }

    fileprivate func removeStorageItem(_ id: String) {
        if !DataBaseManager.shared.removeDownloadItem(with: id) {
            BHLog.w("\(#function) - failed to remove download item")
        }
    }
}
