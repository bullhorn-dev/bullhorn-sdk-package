
import Foundation
import SDWebImage

protocol BHHybridPlayerListener: ObserverProtocol {

    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem)
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags)
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double)
    func hybridPlayerDidChangeBulletin(_ player: BHHybridPlayer)
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer)
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?)
    func hybridPlayerDidClose(_ player: BHHybridPlayer)

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

    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings) {}
    func hybridPlayer(_ player: BHHybridPlayer, sleepTimerUpdated sleepTimer: Double) {}
    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {}
}

class BHHybridPlayer {
    
    static let shared: BHHybridPlayer = BHHybridPlayer.init()
    
    let trackTimerInterval: Double = 0.9
    let nowPlayingInfoUpdateInterval: Double = 5.0

    enum PlayerType: Int {
        case systemAudio = 0
        case systemVideo
    }
    
    enum SkipDirection: Int {
        case backward = 0
        case forward
    }
        
    internal let observersContainer: ObserversContainerNotifyingOnQueue<BHHybridPlayerListener>
    internal let workingQueue = DispatchQueue.init(label: "BHHybridPlayer.Working", target: .global())

    var post: BHPost? {
        didSet {
            BHBulletinManager.shared.reset()
            fetchInteractive() { _ in }
        }
    }
    
    var playlist: [BHPost]?
    
    var playerItem: BHPlayerItem?

    var bulletin: BHBulletin? {
        return bulletinManager.bulletin
    }
    
    var bulletinLayout: BHBulletinLayout? {
        return bulletinManager.layout
    }

    var state: PlayerState = .idle
    var stateFlags: PlayerStateFlags = .initial

    var isVideoAvailable = false {
        didSet {
            if oldValue == isVideoAvailable { return }
            onStateUpdated()
        }
    }
    
    fileprivate var prevPlayerState: BHPlayerState?

    internal var mediaPlayer: BHMediaPlayerBase?
    fileprivate var trackTimer: Timer?
    fileprivate var sleepTimer: Timer?
    var sleepTimerInterval: TimeInterval = 0
    
    fileprivate var nowPlayingInfoUpdateCounter: Double = 0.0

    var lastSentPosition: TimeInterval = 0
    var lastSentDuration: TimeInterval = 0

    fileprivate var isSilent = false
    fileprivate var isSeek = false
    
    var isSliding: Bool = false
    
    internal var bulletinManager = BHBulletinManager.shared
    internal var postsManager = BHPostsManager()

    fileprivate var settings = BHPlayerItem.PlaybackSettings.initial {
        didSet {
            
            settings.debugDescription()
            
            mediaPlayer?.rate = settings.playbackSpeed

            BHRemoteCommandCenterManager.shared.updateTimeIntervals(withPrefferedBackwardIntervals: [settings.backwardLength], prefferedForwardIntervals: [settings.forwardLength])
            BHRemoteCommandCenterManager.shared.updatePlaybackRates(withSupportedPlaybackRates: settings.supportedPlaybackRates())
        }
    }
    

    // MARK: - Lifecycle

    init() {
        observersContainer = .init(notifyQueue: workingQueue)
        
        UserDefaults.standard.register(defaults: [
            UserDefaults.playNextEnabledDefaultsKey : true,
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(_:)), name: BHAccountManager.AccountChangedNotification, object: nil)
    }

    deinit {
        stop()
    }
    
    // MARK: - Public listener

    func addListener(_ listener: BHHybridPlayerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHHybridPlayerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - SDK Public
    
    func hasActivePlaying() -> Bool {
        return isActive()
    }
    
    func getTimelineEvent() -> BHBulletinEvent? {
        guard let validBulletin = bulletinManager.bulletin else { return nil }
        guard let player = mediaPlayer else { return nil }

        return validBulletin.getTimelineEvent(player.currentTime())
    }
    
    func getBulletinTiles() -> [BHBulletinTile] {
        guard let validBulletin = bulletinManager.bulletin else { return [] }
        guard let player = mediaPlayer else { return [] }

        var tiles: [BHBulletinTile] = []

        if let event = validBulletin.getTimelineEvent(player.currentTime()) {
            tiles.append(event.bulletinTile)
        }
        
        return tiles
    }
    
    func hasInteractive() -> Bool {
        if isActive() {
            return getBulletinTiles().count > 0
        }
        return false
    }
    
    func getLayoutEvent() -> BHBulletinLayoutEvent? {
        guard post != nil else { return nil }
        guard let validLayout = bulletinManager.layout else { return nil }
        guard let player = mediaPlayer else { return nil }

        return validLayout.getLayoutEvent(player.currentTime())
    }
        
    // MARK: - Public

    func playRequest(with post: BHPost, playlist: [BHPost]?) {
        
        BHLog.p("\(#function) id: \(post.id), title: \(post.title), position: \(post.playbackOffset)")
        
        BHLivePlayer.shared.close()
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openPlayer, context: post.shareLink.absoluteString, podcastId: post.user.id, podcastTitle: post.user.fullName, episodeId: post.id, episodeTitle: post.title, extraParams: ["type" : post.postType.rawValue])
        BHTracker.shared.trackEvent(with: request)

        if isPostActive(post.id) {
            if isPlaying() {
                pause()
            } else {
                resume()
            }
        } else {
            
            let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(post.id)
            
            if fileUrl != nil {
                let postItem = BHPlayerItem.Post(postId: post.id, title: post.title, userId: post.user.id, userName: post.user.fullName, userImageUrl: post.user.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
                let playerItem = BHPlayerItem(post: postItem, playbackSettings: settings, position: 0, duration: Double(post.recording?.duration ?? 0), shouldPlay: true, isStream: post.isRadioStream() || post.isLiveStream())
                             
                start(with: playerItem, post: post, playlist: playlist)
                             
                BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
            } else if BHReachabilityManager.shared.isConnected() {

                BHPostsManager.shared.getPost(post.id, context: nil) { result in
                    switch result {
                    case .success(post: let post):
                        self.post = post
                    case .failure(error: _):
                        self.post = post
                        break
                    }

                    let postItem = BHPlayerItem.Post(postId: post.id, title: post.title, userId: post.user.id, userName: post.user.fullName, userImageUrl: post.user.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
                    let playerItem = BHPlayerItem(post: postItem, playbackSettings: self.settings, position: 0, duration: Double(post.recording?.duration ?? 0), shouldPlay: true, isStream: post.isRadioStream() || post.isLiveStream())

                    self.start(with: playerItem, post: post, playlist: playlist)

                    BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
                }
            } else {
                let vc = BHConnectionLostBottomSheet()
                vc.preferredSheetSizing = .fit
                vc.panToDismissEnabled = true
                    
                UIApplication.topNavigationController()?.present(vc, animated: true)
            }
        }
    }
    
    func updatePlayingItemInfo(with post: BHPost) {
        BHLog.p("\(#function)")

        if isActive() {
            let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(post.id)
            let postItem = BHPlayerItem.Post(postId: post.id, title: post.title, userId: post.user.id, userName: post.user.fullName, userImageUrl: post.user.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
            
            let playerItem = BHPlayerItem(post: postItem, playbackSettings: settings, position: post.playbackOffset, duration: Double(post.recording?.duration ?? 0), shouldPlay: true, isStream: post.isRadioStream() || post.isLiveStream())
            
            self.playerItem = playerItem
            self.post = post
            self.mediaPlayer?.updateNowPlayingItemInfo()

        } else {
            playRequest(with: post, playlist: [])
        }
    }
    
    func close() {
        BHLog.p("\(#function)")

        performStop()
        playerItem = nil
        playlist = nil
        post = nil
        bulletinManager.reset()
        settings = .initial
        
        observersContainer.notifyObserversAsync {
            $0.hybridPlayerDidClose(self)
        }
    }

    func play() {
        play(at: 0.0)
    }
    
    func play(at position: Double) {
        
        if isEnded() {
            destroyMediaPlayer()
        }

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
        
    func resume() {
        
        if !isActive() {
            play(at: 0)
        } else {
            performResume()
            mediaPlayer?.rate = settings.playbackSpeed
            
            BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        }
    }

    func pause() {
        performPause()
    }
    
    func stop() {
        performStop()
    }
    
    func seek(to position: Double, resume: Bool = true) {
        isSeek = true
        performSeek(to: position.fromMs(), forceResume: resume)
    }
    
    func seekForward() {
        performForward()
    }
    
    func seekBackward() {
        performBackward()
    }
    
    func playNext() {
        BHLog.p("\(#function)")
        
        guard let validPlaylist = playlist else { return }
        guard let validPlayerItem = playerItem else { return }

        if let index = validPlaylist.firstIndex(where: { $0.id == validPlayerItem.post.postId }) {
            if index < validPlaylist.count - 1 {
                let indexAfter = validPlaylist.index(after: index)
                let nextPost = validPlaylist[indexAfter]
                
                playRequest(with: nextPost, playlist: validPlaylist)
            } else {
                BHLog.w("\(#function) - it is the last episode in playlist")
            }
        }
    }
    
    func playPrevious() {
        BHLog.p("\(#function)")

        guard let validPlaylist = playlist else { return }
        guard let validPlayerItem = playerItem else { return }
        guard let validPlayer = mediaPlayer else { return }
        
        if validPlayer.currentTime() > 30 {
            performSeek(to: 0)
        } else {
            if let index = validPlaylist.firstIndex(where: { $0.id == validPlayerItem.post.postId }) {
                if index > 0 {
                    let indexBefore = validPlaylist.index(before: index)
                    let previousPost = validPlaylist[indexBefore]
                    
                    if !performStart(with: previousPost) {
                        BHLog.w("Failed to play previous episode")
                    }
                } else {
                    performSeek(to: 0)
                }
            }
        }
    }
    
    func hasPrevious() -> Bool {

        guard let validPlaylist = playlist else { return false }
        guard let validPlayerItem = playerItem else { return false }
        guard let validPlayer = mediaPlayer else { return false }

        if let index = validPlaylist.firstIndex(where: { $0.id == validPlayerItem.post.postId }) {
            return (index > 0 || validPlayer.currentTime() > 30) && isActive()
        }
        
        return (validPlayer.currentTime() > 30) && isActive()
    }
    
    func hasNext() -> Bool {
        
        guard let validPlaylist = playlist else { return false }
        guard let validPlayerItem = playerItem else { return false }

        if let index = validPlaylist.firstIndex(where: { $0.id == validPlayerItem.post.postId }) {
            return index < validPlaylist.count - 1 ///&& isActive()
        }

        return false
    }

    // MARK: - Settings

    func updatePlaybackSpeed(_ value: Float) {
        
        playerItem?.playbackSettings.playbackSpeed = value
        settings.playbackSpeed = value
        
        ///graylog tracker
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerSpeed, context: "\(value)", podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, playbackSettingsUpdated: self.settings)
        }
    }
    
    func updateNextPlaybackSpeed() {
        guard let playerItem = playerItem else { return }
        if playerItem.isStream { return }
        if state != .playing { return }

        let nextPlaybackRate = settings.nextPlaybackSpeed()
        updatePlaybackSpeed(nextPlaybackRate)
    }
    
    func updateSleepTimer(_ value: Double) {

        if isPaused() {
            resume()
        }
        
        setSleepTimer(value)
 
        ///graylog tracker
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerSleepTimer, context: "\(value)", podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, sleepTimerUpdated: value)
        }
    }
        
    // MARK: - Video View
    
    func getVideoLayer() -> UIView? {
        return mediaPlayer?.getVideoLayer()
    }
    
    // MARK: - Player states

    @discardableResult func isPostPlaying(_ id: String) -> Bool {
        guard let p = post else { return false }

        return p.id == id && state.isPlaying()
    }

    @discardableResult func isPostActive(_ id: String) -> Bool {
        guard let p = post else { return false }

        return p.id == id && isActive()
    }

    @discardableResult func isPlaying() -> Bool { state.isPlaying() }

    @discardableResult func isPaused() -> Bool { state.isPaused() }

    @discardableResult func isEnded() -> Bool { state.isEnded() }

    @discardableResult func isDestroyed() -> Bool { state.isDestroyed() }

    @discardableResult func isInitializing() -> Bool { state.isInitializing() }
    
    @discardableResult func isActive() -> Bool { state.isActive() }

    // MARK: - Private methods
    
    fileprivate func start(with item: BHPlayerItem?, post: BHPost?, playlist: [BHPost]?) {
        
        stop()
        
        guard let validItem = item else {
            BHLog.w("\(#function) - empty player item")
            return
        }
                
        lastSentPosition = validItem.position
        lastSentDuration = validItem.duration

        settings = validItem.playbackSettings
        playerItem = validItem
        self.post = post
        self.playlist = playlist
        
        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, initializedWith: validItem)
        }

        BHRemoteCommandCenterManager.shared.delegate = self
        BHRemoteCommandCenterManager.shared.enablePlaybackControls()

        play(at: validItem.position)
    }

    fileprivate func composeMediaPlayer(with position: Double = 0) {
        
        BHLog.p("\(#function) - \(position)")
        
        guard let validPlayerItem = playerItem else { return }
        guard var urlToPlay = validPlayerItem.post.url else { return }
        guard let validPost = post else { return }

        if let cachedUrl = validPlayerItem.post.file {

            let fileName = cachedUrl.lastPathComponent
            
            if let fileURL = FileManager.default.documentsDirectory()?.appendingPathComponent(fileName) {

                if FileManager.default.fileExists(atPath: fileURL.path) {
                    urlToPlay = fileURL
                }
            }
        }

        BHID3Parser.isGoodForStream(validPlayerItem.post.url!) { isID3, isGoodForStream, isVideo in
            if isVideo || validPost.hasVideo() {
                self.createMediaPlayer(.systemVideo, url: urlToPlay, position: position)
            } else {
                self.createMediaPlayer(.systemAudio, url: urlToPlay, position: position)
            }
        }
    }
    
    fileprivate func createMediaPlayer(_ type: PlayerType, url: URL, position: Double = 0) {

        guard playerItem != nil else { return }

        var player: BHMediaPlayerBase
        
        switch type {
        case .systemAudio:
            player = BHSystemAudioPlayer(withUrl: url)
        case .systemVideo:
            player = BHSystemVideoPlayer(withUrl: url, coverUrl: playerItem?.post.userImageUrl)
        }

        player.delegate = self
        player.startTime = position
        player.rate = settings.playbackSpeed
        
        mediaPlayer = player
        isVideoAvailable = player.hasVideo()
    }
    
    fileprivate func destroyMediaPlayer() {
        
        guard let player = mediaPlayer else { return }

        switch player.state {
        case .playing, .paused: _ = player.stop()
        default: break
        }
        
        lastSentPosition = 0
        lastSentDuration = 0

        mediaPlayer = nil
    }
    
    @discardableResult fileprivate func performPlay() -> Bool {
        
        guard let player = mediaPlayer else { return false }
        guard let validPlayerItem = playerItem else { return false }
        
        return player.play(at: validPlayerItem.position)
    }
    
    @discardableResult fileprivate func performStop() -> Bool {
        
        destroyMediaPlayer()

        return true
    }
    
    @discardableResult fileprivate func performResume() -> Bool {
        
        guard let player = mediaPlayer else { return false }
        
        return player.resume()
    }

    @discardableResult fileprivate func performPause() -> Bool {

        guard let player = mediaPlayer else { return false }

        return player.pause()
    }
    
    @discardableResult fileprivate func performForward() -> Bool {

        guard let player = mediaPlayer else { return false }

        let position = player.currentTime()
        let duration = max(totalDuration(), player.currentTime())
        let resultPosition = min(duration, position + settings.forwardLength)

        return performSeek(to: resultPosition)
    }
    
    @discardableResult fileprivate func performBackward() -> Bool {

        guard let player = mediaPlayer else { return false }
        
        let position = player.currentTime()
        let resultPosition = max(0, position - settings.backwardLength)
        
        return performSeek(to: resultPosition)
    }
    
    @discardableResult fileprivate func performPrevious() -> Bool {
        
        guard mediaPlayer != nil else { return false }
        guard playerItem != nil else { return false }
        
        if hasPrevious() {
            playPrevious()
            return true
        }
        
        return false
    }

    @discardableResult fileprivate func performNext() -> Bool {
        
        guard mediaPlayer != nil else { return false }
        guard playerItem != nil else { return false }

        if hasNext() {
            playNext()
            return true
        }
        
        return false
    }
    
    @discardableResult fileprivate func performStart(with post: BHPost) -> Bool {
        
        let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(post.id)
        let postItem = BHPlayerItem.Post(postId: post.id, title: post.title, userId: post.user.id, userName: post.user.fullName, userImageUrl: post.user.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
        let settings: BHPlayerItem.PlaybackSettings = settings
            
        let playerItem = BHPlayerItem(post: postItem, playbackSettings: settings, position: 0, duration: Double(post.recording?.duration ?? 0), shouldPlay: true, isStream: post.isRadioStream() || post.isLiveStream())
            
        start(with: playerItem, post: post, playlist: playlist)
            
        return true
    }

    @discardableResult fileprivate func performSeek(to position: Double, forceResume: Bool = false) -> Bool {

        BHLog.p("\(#function) - \(position)")

        guard let player = mediaPlayer else { return false }
        
        var resultPosition = position

        if position < 0 { resultPosition = 0 }
//        if position > totalDuration() { resultPosition = totalDuration() }

        if isEnded() {
            play(at: resultPosition)
            return true
        }

        let result = player.play(at: resultPosition, forceResume: forceResume)

        if result {
            mediaPlayer?.updateNowPlayingInfo()
        }
        
        BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        
        return result
    }
        
    fileprivate func setSleepTimer(_ value: Double) {
                
        BHLog.p("\(#function) - value: \(value)")
        
        sleepTimerInterval = TimeInterval(value)
        if sleepTimerInterval.isZero {
            stopSleepTimer()
        }
        else {
            startSleepTimerIfNeeded()
        }
    }
    
    func totalDuration() -> TimeInterval {
        if let validPlayerDuration = mediaPlayer?.duration() {
            return validPlayerDuration
        } else {
            return max(TimeInterval(playerItem?.duration ?? 0), mediaPlayer?.duration() ?? 0)
        }
    }
    
    fileprivate func onStateUpdated() {

        guard playerItem != nil else { return }

        let position = state == .destroyed ? lastSentDuration : lastSentPosition

        let playerState = BHPlayerState.init(state: state, stateFlags: stateFlags, position: position, duration: lastSentDuration, isVideoAvailable: isVideoAvailable)
        
        if let validPrevPlayerState = prevPlayerState {
            if validPrevPlayerState == playerState {
                return
            }
        }
        
        prevPlayerState = playerState

        playerState.debugDescription()
        
        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, stateUpdated: self.state, stateFlags: self.stateFlags)
        }
    }
    
    fileprivate func playerPositionChanged(_ force: Bool = false) {

        if UIApplication.shared.applicationState != .active && !force { return }
        guard let player = mediaPlayer else { return }

        let position = player.currentTime()
        playerItem?.position = position

        guard lastSentPosition.rounded() != position.rounded() else { return }

        let duration = max(totalDuration(), player.currentTime())

        lastSentPosition = position.toMs()
        lastSentDuration = duration.toMs()
        
        if isSliding {
            return
        }
        
        if isSeek {
            isSeek = false
            return
        }

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, positionChanged: position, duration: duration)
        }
    }

    fileprivate func composeNowPlayingItemInfo(with image: UIImage? = nil) -> BHNowPlayingItemInfo {

        let currentItemImage = image ?? mediaPlayer?.nowPlayingItemInfo.itemImage
        let nowPlayingItemInfo = BHNowPlayingItemInfo(title: playerItem?.post.title, audioTitle: playerItem?.post.userName, authorName: playerItem?.post.userName, duration: totalDuration(), elapsedTime: nil, itemImage: currentItemImage, isLiveStream: playerItem?.isStream, rate: nil)

        return nowPlayingItemInfo
    }

    fileprivate func updateNowPlayingItemInfoImage() {

        if let profilePictureUrl = playerItem?.post.userImageUrl {
            SDWebImageDownloader.shared.downloadImage(with: profilePictureUrl, options: .useNSURLCache, progress: nil) { (image, _, error, finished) in
                guard finished else { return }

                if let validError = error {
                    BHLog.w("\(#function) - Failed to load image: \(validError)")
                }
                else if let validImage = image, profilePictureUrl == self.playerItem?.post.userImageUrl, let validPlayer = self.mediaPlayer {
                    validPlayer.updateNowPlayingItemInfo(with: self.composeNowPlayingItemInfo(with: validImage))
                }
            }
        }
    }
        
    // MARK: - Track timer
    
    fileprivate func startTrackTimer() {

        if let currentTrackTimer = trackTimer, currentTrackTimer.isValid {
            return
        }

        let timer = Timer.init(timeInterval: trackTimerInterval, target: self, selector: #selector(trackTimerHandler(_:)), userInfo: nil, repeats: true)
        timer.tolerance = trackTimerInterval
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        trackTimer = timer
    }
    
    fileprivate func stopTrackTimer() {

        guard let timer = trackTimer else { return }

        timer.invalidate()
        trackTimer = nil
    }

    @objc fileprivate func trackTimerHandler(_ timer: Timer) {

        guard timer.isValid else { return }

        playerPositionChanged()

        nowPlayingInfoUpdateCounter += trackTimerInterval
        
        if nowPlayingInfoUpdateCounter >= nowPlayingInfoUpdateInterval {
            nowPlayingInfoUpdateCounter = 0
            mediaPlayer?.updateNowPlayingItemInfo()
        }
    }
    
    // MARK: - Sleep timer
    
    fileprivate func startSleepTimerIfNeeded() {

        guard !sleepTimerInterval.isZero else { return }

        if let timer = sleepTimer, timer.isValid {
            stopSleepTimer()
        }

        let timer = Timer.init(timeInterval: sleepTimerInterval, target: self, selector: #selector(sleepTimerHandler(_:)), userInfo: nil, repeats: false)
        timer.tolerance = sleepTimerInterval * 0.1
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        sleepTimer = timer
    }
    
    fileprivate func stopSleepTimer() {
        
        guard let timer = sleepTimer else {
            return
        }

        timer.invalidate()
        sleepTimer = nil
    }
    
    func getSleepTimerInterval() -> Double {

        guard let timer = sleepTimer else {
            return 0
        }

        if timer.isValid {
            return timer.fireDate.timeIntervalSinceNow
        }
        
        return 0
    }

    @objc fileprivate func sleepTimerHandler(_ timer: Timer) {

        guard let player = mediaPlayer else { return }

        _ = player.pause()

        sleepTimerInterval = 0
    }
    
    // MARK: - Handle player state
    
    fileprivate func handlePlayerState(_ state: BHMediaPlayerBase.State) {

        let playerState: PlayerState
        var playerStateFlags: PlayerStateFlags = .initial
        var needUpdatePosition = false

        switch state {
        case .idle:
            playerState = .idle

        case .waiting:
            playerState = .initializing
            if prevPlayerState?.state == .initializing && post?.isRadioStream() != true {
                getPlaybackOffset()
            }

        case .ready:
            playerState = .initializing

        case .playing:
            playerState = .playing
            startTrackTimer()
            startSleepTimerIfNeeded()

        case .paused:
            playerState = .paused
            stopTrackTimer()
            setSleepTimer(0)
            playerPositionChanged(true)
            needUpdatePosition = self.state.isPlaying()

        case .ended:
            playerState = .ended
            playerStateFlags = .complete
            stopTrackTimer()
            setSleepTimer(0)
            observersContainer.notifyObserversAsync {
                $0.hybridPlayerDidFinishPlaying(self)
            }

        case .failed(let error):
            BHLog.w("\(#function) - Audio player error: \(String(describing: error))")

            playerState = .destroyed
            playerStateFlags = .error
            
            let request = BHTrackEventRequest.createRequest(category: .explore, action: .error, banner: .playerFailed, context: error.debugDescription, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
            BHTracker.shared.trackEvent(with: request)

            observersContainer.notifyObserversAsync {
                $0.hybridPlayerDidFailedToPlay(self, error: error)
            }
        }
        
        self.stateFlags = playerStateFlags
        self.state = playerState
        
        if needUpdatePosition && post?.isRadioStream() != true {
            postPlaybackOffset()
        }
        
        if isSeek {
            isSeek = false
            return
        }

        if isSilent { return }
        
        onStateUpdated()
        
        if self.state == .destroyed {
            destroyMediaPlayer()
        }
    }
    
    // MARK: - Cache player position
    
    fileprivate func cachePosition() {
        
        guard let validPlayer = mediaPlayer else {
            resetCachedPosition()
            return
        }
        guard let validPlayerItem = playerItem else {
            resetCachedPosition()
            return
        }

        UserDefaults.standard.playerPostId = validPlayerItem.post.postId
        UserDefaults.standard.playerPosition = validPlayer.currentTime()
        UserDefaults.standard.playerTimestamp = Date().timeIntervalSince1970.toMs()
    }
    
    fileprivate func resetCachedPosition() {
        
        UserDefaults.standard.playerPostId = ""
        UserDefaults.standard.playerPosition = Constants.invalidPosition
        UserDefaults.standard.playerTimestamp = 0
    }
    
    func getCachedPosition() -> [String : Any]? {
        
        if UserDefaults.standard.playerPostId.count > 0 && UserDefaults.standard.playerPosition != Constants.invalidPosition {
            
            let cachedPlayer = [
                BHPlayerKeys.postId.rawValue: UserDefaults.standard.playerPostId,
                BHPlayerKeys.position.rawValue: UserDefaults.standard.playerPosition,
                BHPlayerKeys.timestamp.rawValue: UserDefaults.standard.playerTimestamp
            ] as [String : Any]
            
            resetCachedPosition()

            return cachedPlayer
        }
        
        return nil
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onApplicationWillTerminate(_ notification: Notification) {
        if isActive() {
            cachePosition()
            stop()
        }
    }
    
    @objc fileprivate func onAccountChangedNotification(_ notification: Notification) {

        guard let notificationInfo = notification.userInfo as? [String : BHAccountManager.AccountChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHAccountManager.NotificationInfoKey] else { return }

        switch info.reason {
        case .update:
            fetchInteractive() { result in
                switch result {
                case .success:
                    if self.hasInteractive() && self.isPaused() {
                        self.resume()
                    }

                case .failure(error: _):
                    break
                }
            }

        default:
            break
        }
    }
}

// MARK: - MediaPlayerDelegate implementation

extension BHHybridPlayer: BHMediaPlayerDelegate {
    
    func mediaPlayer(_ player: BHMediaPlayerBase, stateUpdated state: BHMediaPlayerBase.State) {

        handlePlayerState(state)

        guard let validPlayerItem = playerItem else { return }

        if isPlaying() && !validPlayerItem.shouldPlay {
            performPause()
            playerItem?.shouldPlay = true
        }
    }
    
    func mediaPlayerDidFinishPlaying(_ player: BHMediaPlayerBase) {
        guard let validPlayerItem = playerItem else {
            stop()
            return
        }
        
        if validPlayerItem.isStream {
            mediaPlayerDidStallPlaying(player)
        } else {
            handlePlayerState(.ended)
            if hasNext() && UserDefaults.standard.playNextEnabled {
                playNext()
            }
        }
    }
    
    func mediaPlayerDidStallPlaying(_ player: BHMediaPlayerBase) {
        let error = NSError.error(with: NSError.LocalCodes.common, description: "Playing stalled because of bad network connection.")
        handlePlayerState(.failed(e: error))
    }
    
    func mediaPlayerServicesWereLost(_ player: BHMediaPlayerBase) {
        if playerItem?.isStream == true {
            mediaPlayerDidStallPlaying(player)
        } else {
            pause()
        }
    }
    
    func mediaPlayerServicesWereReset(_ player: BHMediaPlayerBase) {
        
    }

    func mediaPlayerDidRequestNowPlayingItemInfo(_ player: BHMediaPlayerBase) -> BHNowPlayingItemInfo {

        guard player === self.mediaPlayer else { return .invalid }

        let nowPlayingItemInfo = composeNowPlayingItemInfo()
        if nowPlayingItemInfo.itemImage == nil {
            updateNowPlayingItemInfoImage()
        }

        return nowPlayingItemInfo
    }
}

// MARK: - RemoteCommandCenterDelegate

extension BHHybridPlayer: BHRemoteCommandCenterDelegate {
    
    func configureRemoteCommandCenter(_ configureBlock: (BHRemoteCommandCenterManager.Mode) -> Void) {
        if let validItem = playerItem, validItem.isStream {
            configureBlock(.liveRadioStream)
        } else if let validPlaylist = playlist, validPlaylist.count > 1 {
            configureBlock(.trackList(backwardTimeIntervals: [self.settings.backwardLength], forwardTimeIntervals: [self.settings.forwardLength], supportedPlaybackRates: self.settings.supportedPlaybackRates()))
        } else {
            configureBlock(.singleTrack(backwardTimeIntervals: [self.settings.backwardLength], forwardTimeIntervals: [self.settings.forwardLength], supportedPlaybackRates: self.settings.supportedPlaybackRates()))
        }
    }
    
    func onRemoteCommandPlay() -> Bool {
        guard mediaPlayer != nil else {
            BHLog.w("\(#function) - play the last played episode")
            return true
        }
        
        return performResume()
    }

    func onRemoteCommandPause() -> Bool {
        return performPause()
    }

    func onRemoteCommandTogglePlayPause() -> Bool {
        return isPlaying() ? performPause() : performResume()
    }

    func onRemoteCommandSkipBackward() -> Bool {
        return performBackward()
    }

    func onRemoteCommandSkipForward() -> Bool {
        return performForward()
    }
    
    func onRemoteCommandChangePlaybackPosition(_ position: TimeInterval) -> Bool {
        return performSeek(to: position)
    }

    func onRemoteCommandPreviousTrack() -> Bool {
        return performPrevious()
    }

    func onRemoteCommandNextTrack() -> Bool {
        return performNext()
    }
    
    func onChangePlaybackRateCommand(_ playbackRate: Float) -> Bool {
        updatePlaybackSpeed(playbackRate)
        return true
    }

}
