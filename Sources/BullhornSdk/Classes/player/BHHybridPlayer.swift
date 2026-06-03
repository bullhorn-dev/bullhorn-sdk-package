import Foundation
import SDWebImage

// MARK: - Listener Protocol

protocol BHHybridPlayerListener: ObserverProtocol {

    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem)
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags)
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double)
    func hybridPlayerDidChangeBulletin(_ player: BHHybridPlayer)
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer)
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?)
    func hybridPlayerDidClose(_ player: BHHybridPlayer)
    func hybridPlayerDidChangeTranscript(_ player: BHHybridPlayer, transcript: BHTranscript)
    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings)
    func hybridPlayer(_ player: BHHybridPlayer, sleepTimerUpdated sleepTimer: Double)
    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool)
}

extension BHHybridPlayerListener {
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {}
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {}
    func hybridPlayerDidChangeBulletin(_ player: BHHybridPlayer) {}
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {}
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {}
    func hybridPlayerDidClose(_ player: BHHybridPlayer) {}
    func hybridPlayerDidChangeTranscript(_ player: BHHybridPlayer, transcript: BHTranscript) {}
    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings) {}
    func hybridPlayer(_ player: BHHybridPlayer, sleepTimerUpdated sleepTimer: Double) {}
    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {}
}

// MARK: - BHHybridPlayer

/// Public facade for all player interaction.
/// All other parts of the app communicate with the player only through this class.
class BHHybridPlayer {

    static let shared = BHHybridPlayer()

    // MARK: - Internal infrastructure

    internal let observersContainer: ObserversContainerNotifyingOnQueue<BHHybridPlayerListener>
    internal let workingQueue = DispatchQueue(label: "BHHybridPlayer.Working", target: .global())

    // MARK: - Public state

    var state: PlayerState = .idle
    var stateFlags: PlayerStateFlags = .initial

    var isVideoAvailable = false {
        didSet {
            guard oldValue != isVideoAvailable else { return }
            onStateUpdated()
        }
    }

    // MARK: - Content

    var post: BHPost? {
        didSet {
            BHBulletinManager.shared.reset()
            fetchInteractive() { _ in }
            fetchTranscript()
        }
    }

    var playerItem: BHPlayerItem?

    var bulletin: BHBulletin?       { bulletinManager.bulletin }
    var bulletinLayout: BHBulletinLayout? { bulletinManager.layout }

    internal var transcript: BHTranscript?
    internal var transcriptSegments: [BHSegment] { transcript?.segments ?? [] }
    
    internal var playbackQueue: [BHQueueItem] = []

    // MARK: - UI flags

    var isFullScreen: Bool = false
    var isTranscriptActive: Bool = false
    var isSliding: Bool = false

    // MARK: - Internal state

    internal var mediaPlayer: (any BHPlaybackEngine)?
    internal var manualPosition: Double = 0
    internal var shouldPlayAutomatically: Bool = true
    internal var context: BHPlayerContext = .app

    // Position tracking
    var lastSentPosition: TimeInterval = 0
    var lastSentDuration: TimeInterval = 0

    // Deduplication
    internal var prevPlayerState: BHPlayerState?
    internal var isSilent = false
    internal var isSeek = false

    // MARK: - Managers

    internal var bulletinManager = BHBulletinManager.shared
    internal var postsManager = BHPostsManager()

    // MARK: - Settings

    internal var settings = BHPlayerItem.PlaybackSettings.initial {
        didSet {
            settings.debugDescription()
            mediaPlayer?.rate = settings.playbackSpeed
            BHRemoteCommandCenterManager.shared.updateTimeIntervals(
                withPrefferedBackwardIntervals: [settings.backwardLength],
                prefferedForwardIntervals: [settings.forwardLength])
            BHRemoteCommandCenterManager.shared.updatePlaybackRates(
                withSupportedPlaybackRates: settings.supportedPlaybackRates())
        }
    }

    // MARK: - Init

    init() {
        observersContainer = .init(notifyQueue: workingQueue)

        UserDefaults.standard.register(defaults: [
            UserDefaults.playNextEnabledDefaultsKey: true
        ])

        NotificationCenter.default.addObserver(self,
            selector: #selector(onApplicationWillTerminate(_:)),
            name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(onAccountChangedNotification(_:)),
            name: BHAccountManager.AccountChangedNotification, object: nil)
    }

    deinit {
        stop()
    }

    // MARK: - Listeners

    func addListener(_ listener: BHHybridPlayerListener, withDuplicates: Bool = false) {
        workingQueue.async { self.observersContainer.addObserver(listener, withDuplicates: withDuplicates) }
    }

    func removeListener(_ listener: BHHybridPlayerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public API

    func playRequest(with post: BHPost,
                     playlist: [BHPost]?,
                     context: BHPlayerContext = .app,
                     autoplayContext: BHAutoplayContext?,
                     position: Double = 0,
                     clearQueue: Bool = true) {

        BHLog.p("PlayRequest id: \(post.id), title: \(post.title), position: \(post.playbackOffset)")

        BHLivePlayer.shared.close()

        if isPostActive(post.id) {
            if isPlaying() {
                pause()
            } else {
                resume()
            }
            return
        }

        if let previousPost = self.post { removeFromPlaybackQueue(previousPost.id) }
        if clearQueue { removeQueue() }
        if post.isRadioStream() { updatePlaybackSpeed(.normal) }

        self.isTranscriptActive = false
        self.context = context
        self.manualPosition = position

        let localOffset = BHOffsetsManager.shared.offset(for: post.id)
        let startPosition = position > 0 ? position : localOffset?.offset ?? 0

        let type = post.isLiveStream() ? "live-stream" : post.isRadioStream() ? "radio" : "pre-recorded"
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerOpen,
            context: context.rawValue, podcastId: post.user.id, podcastTitle: post.user.fullName,
            episodeId: post.id, episodeTitle: post.title, episodeType: type)
        BHTracker.shared.trackEvent(with: request)

        let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(post.id)

        if fileUrl != nil {
            let item = makePlayerItem(post: post, fileUrl: fileUrl, position: startPosition, autoplayContext: autoplayContext)
            start(with: item, post: post, playlist: playlist)
            BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()

        } else if BHReachabilityManager.shared.isConnected() {
            BHPostsManager.shared.getPost(post.id, context: nil) { result in
                let resolvedPost: BHPost
                switch result {
                case .success(post: let p): resolvedPost = p
                case .failure: resolvedPost = post
                }
                self.post = resolvedPost
                let item = self.makePlayerItem(post: resolvedPost, fileUrl: nil, position: startPosition, autoplayContext: autoplayContext)
                self.start(with: item, post: resolvedPost, playlist: playlist)
                BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
            }
        } else {
            let item = makePlayerItem(post: post, fileUrl: nil, position: startPosition, autoplayContext: autoplayContext)
            start(with: item, post: post, playlist: playlist)
            BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        }
    }

    func updatePlayingItemInfo(with post: BHPost) {
        BHLog.p("\(#function)")
        if isActive() {
            let fileUrl = BHDownloadsManager.shared.getFileUrl(post.id)
            let postItem = BHPlayerItem.Post(postId: post.id, title: post.title,
                userId: post.user.id, userName: post.user.fullName,
                coverUrl: post.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
            playerItem = BHPlayerItem(post: postItem, playbackSettings: settings,
                position: 0, duration: 0, shouldPlay: true,
                isStream: post.isRadioStream() || post.isLiveStream(),
                autoplayContext: playerItem?.autoplayContext)
            self.post = post
            mediaPlayer?.updateNowPlayingItemInfo(with: nil)
        } else {
            playRequest(with: post, playlist: [], autoplayContext: playerItem?.autoplayContext, clearQueue: false)
        }
    }

    func close() {
        BHLog.p("\(#function)")
        performStop()
        playerItem = nil
        post = nil
        transcript = nil
        bulletinManager.reset()
        settings = .initial
        manualPosition = 0
        isTranscriptActive = false
        isFullScreen = false
        removeQueue()
        UserDefaults.standard.playerPostId = nil
        UserDefaults.standard.playerAutoplayContext = nil
        observersContainer.notifyObserversAsync { $0.hybridPlayerDidClose(self) }
    }

    func play() { play(at: 0.0) }

    func play(at position: Double) {
        if isEnded() { destroyMediaPlayer() }

        if mediaPlayer == nil {
            state = .idle
            stateFlags = .initial
            onStateUpdated()
            composeMediaPlayer(with: position)
        } else {
            performSeek(to: position)
            mediaPlayer?.rate = settings.playbackSpeed
        }
        BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
    }

    @discardableResult func resume() -> Bool {
        if BHReachabilityManager.shared.isConnected() || playerItem?.post.file != nil {
            if mediaPlayer?.retryConnection() == true { return true }
        }

        if state == .failed {
            if BHReachabilityManager.shared.isConnected() || playerItem?.post.file != nil {
                destroyMediaPlayer()
            } else {
                let error = NSError.error(with: NSError.LocalCodes.common,
                    description: "Playback stalled because of bad network connection.")
                handlePlayerState(.failed(e: error))
                return false
            }
        }

        if !isActive() {
            let position: Double
            if isEnded() {
                position = 0
            } else {
                position = playerItem?.position ?? 0
            }
            play(at: position)
        } else {
            performResume()
            mediaPlayer?.rate = settings.playbackSpeed
            BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        }

        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerPlay,
            podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName,
            episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)

        return true
    }

    func pause() {
        performPause()
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerPause,
            podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName,
            episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)
    }

    func stop() { performStop() }

    func seek(to position: Double, resume: Bool = true) {
        isSeek = true
        performSeek(to: position, forceResume: resume)
    }

    func seekForward()  { performForward() }
    func seekBackward() { performBackward() }

    func playNext() {
        BHLog.p("\(#function)")

        // If next item is already preloaded in AVQueuePlayer, use seamless transition.
        // handleSeamlessAdvance() is called from the delegate when advance completes.
        if mediaPlayer?.skipToNextItem() == true {
            BHLog.p("\(#function) — seamless skip")
            return
        }

        // No preloaded item — regular transition (destroys and recreates player).
        if let validItem = playerItem,
           let index = playbackQueue.firstIndex(where: { $0.id == validItem.post.postId }),
           index < playbackQueue.count - 1 {
            playRequest(with: playbackQueue[playbackQueue.index(after: index)].post,
                playlist: [], autoplayContext: playerItem?.autoplayContext, clearQueue: false)
        } else if let nextItem = playbackQueue.first {
            playRequest(with: nextItem.post, playlist: [], autoplayContext: playerItem?.autoplayContext, clearQueue: false)
        }
    }

    func playPrevious() {
        BHLog.p("\(#function)")
        guard let validItem = playerItem, let player = mediaPlayer else { return }

        if player.currentTime() > 30 {
            performSeek(to: 0)
        } else if let index = playbackQueue.firstIndex(where: { $0.id == validItem.post.postId }), index > 0 {
            _ = performStart(with: playbackQueue[playbackQueue.index(before: index)].post)
        } else {
            performSeek(to: 0)
        }
    }

    // MARK: - Queries

    func hasActivePlaying() -> Bool { isActive() }

    func hasPrevious() -> Bool {
        guard let validItem = playerItem, let player = mediaPlayer else { return false }
        if let index = playbackQueue.firstIndex(where: { $0.id == validItem.post.postId }) {
            return (index > 0 || player.currentTime() > 30) && isActive()
        }
        return player.currentTime() > 30 && isActive()
    }

    func hasNext() -> Bool {
        guard let validItem = playerItem else { return false }
        if let index = playbackQueue.firstIndex(where: { $0.id == validItem.post.postId }) {
            return index < playbackQueue.count - 1
        }
        return false
    }

    func currentPosition() -> TimeInterval { mediaPlayer?.currentTime() ?? 0 }
    func totalDuration()   -> TimeInterval { mediaPlayer?.duration() ?? max(TimeInterval(playerItem?.duration ?? 0), 0) }

    func getVideoLayer() -> UIView? { mediaPlayer?.getVideoLayer() }

    func getTimelineEvent() -> BHBulletinEvent? {
        guard let bulletin = bulletinManager.bulletin, let player = mediaPlayer else { return nil }
        return bulletin.getTimelineEvent(player.currentTime())
    }

    func getBulletinTiles() -> [BHBulletinTile] {
        guard let bulletin = bulletinManager.bulletin, let player = mediaPlayer else { return [] }
        if let event = bulletin.getTimelineEvent(player.currentTime()) {
            return [event.bulletinTile]
        }
        return []
    }

    func hasInteractive() -> Bool { isActive() && getBulletinTiles().count > 0 }

    func getLayoutEvent() -> BHBulletinLayoutEvent? {
        guard post != nil, let layout = bulletinManager.layout, let player = mediaPlayer else { return nil }
        return layout.getLayoutEvent(player.currentTime())
    }

    // MARK: - Player state helpers

    @discardableResult func isPostPlaying(_ id: String) -> Bool {
        post?.id == id && state.isPlaying()
    }
    @discardableResult func isPostActive(_ id: String) -> Bool {
        post?.id == id && isActive()
    }
    @discardableResult func isInPlayer(_ id: String) -> Bool {
        post?.id == id
    }
    @discardableResult func isPlaying()     -> Bool { state.isPlaying() }
    @discardableResult func isPaused()      -> Bool { state.isPaused() }
    @discardableResult func isEnded()       -> Bool { state.isEnded() }
    @discardableResult func isFailed()      -> Bool { state.isFailed() }
    @discardableResult func isInitializing()-> Bool { state.isInitializing() }
    @discardableResult func isActive()      -> Bool { state.isActive() }

    // MARK: - Session stored properties (used by BHHybridPlayer+Session)
    internal var trackTimer: Timer?
    internal var sleepTimer: Timer?
    var sleepTimerInterval: TimeInterval = 0
    internal var currentPlayback: BHPostPlayback?
    internal var playbackRecreateCounter: Double = 0.0
    internal var nowPlayingInfoUpdateCounter: Double = 0.0

    // MARK: - App lifecycle

    @objc private func onApplicationWillTerminate(_ notification: Notification) {
        if isActive() { stop() }
    }

    @objc private func onAccountChangedNotification(_ notification: Notification) {
        guard let info = (notification.userInfo as? [String: BHAccountManager.AccountChangedNotificationInfo])?[BHAccountManager.NotificationInfoKey] else { return }
        switch info.reason {
        case .update:
            fetchInteractive() { result in
                if case .success = result, self.hasInteractive(), self.isPaused() {
                    self.resume()
                }
            }
        default:
            break
        }
    }

    // MARK: - Private helpers

    /// Builds a BHPlayerItem from a post.
    private func makePlayerItem(post: BHPost, fileUrl: URL?, position: Double, autoplayContext: BHAutoplayContext?) -> BHPlayerItem {
        let postItem = BHPlayerItem.Post(
            postId: post.id, title: post.title,
            userId: post.user.id, userName: post.user.fullName,
            coverUrl: post.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
        return BHPlayerItem(post: postItem, playbackSettings: settings,
            position: position, duration: 0, shouldPlay: true,
            isStream: post.isRadioStream() || post.isLiveStream(),
            autoplayContext: autoplayContext)
    }
}

