
import Foundation
import SDWebImage

protocol BHLivePlayerListener: ObserverProtocol {

    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem)
    func livePlayer(_ player: BHLivePlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags)
    func livePlayer(_ player: BHLivePlayer, positionChanged position: Double, duration: Double)
    func livePlayer(_ player: BHLivePlayer, bulletinDidChange bulletin: BHBulletin)
    func livePlayerDidFinishPlaying(_ player: BHLivePlayer)
    func livePlayerDidFailedToPlay(_ player: BHLivePlayer, error: Error?)
}

extension BHLivePlayerListener {
    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem) {}
    func livePlayer(_ player: BHLivePlayer, positionChanged position: Double, duration: Double) {}
    func livePlayer(_ player: BHLivePlayer, bulletinDidChange bulletin: BHBulletin) {}
    func livePlayerDidFinishPlaying(_ player: BHLivePlayer) {}
    func livePlayerDidFailedToPlay(_ player: BHLivePlayer, error: Error?) {}
}

class BHLivePlayer {
    
    static let shared: BHLivePlayer = BHLivePlayer.init()
            
    private let observersContainer: ObserversContainerNotifyingOnQueue<BHLivePlayerListener>
    private let workingQueue = DispatchQueue.init(label: "BHLivePlayer.Working", target: .global())

    var post: BHPost? {
        didSet {
            bulletin = nil
            fetchBulletin()
        }
    }

    var bulletin: BHBulletin?
    var playerItem: BHPlayerItem?

    var state: PlayerState = .idle
    var stateFlags: PlayerStateFlags = .initial
    
    var isVideoAvailable = false {
        didSet {
            if oldValue == isVideoAvailable { return }
//            onStateUpdated()
        }
    }

    var postsManager = BHPostsManager()

    // MARK: - Lifecycle

    init() {
        observersContainer = .init(notifyQueue: workingQueue)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
    }

    deinit {
        stop()
    }
    
    // MARK: - Public listener

    func addListener(_ listener: BHLivePlayerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHLivePlayerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - SDK Public
    
    func hasActivePlaying() -> Bool {
        return isActive()
    }
        
    // MARK: - Public

    func playRequest(with post: BHPost) {
        
        BHLog.p("\(#function)")

        BHHybridPlayer.shared.close()

        if BHReachabilityManager.shared.isConnected() {
            
            let p = BHPlayerItem.Post(postId: post.id, title: post.title, userId: post.user.id, userName: post.user.fullName, userImageUrl: post.user.coverUrl, url: post.recording?.publishUrl, file: nil)
            let settings: BHPlayerItem.PlaybackSettings = .initial
            let playerItem = BHPlayerItem(post: p, playbackSettings: settings, position: 0, duration: Double(post.recording?.duration ?? 0), shouldPlay: true, isStream: false)
            
            start(with: playerItem, post: post)
        } else {
            let vc = BHConnectionLostBottomSheet()
            vc.preferredSheetSizing = .fit
            vc.panToDismissEnabled = true
            
            UIApplication.topNavigationController()?.present(vc, animated: true)
        }
        
        BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
    }
    
    func close() {
        playerItem = nil
        post = nil
        bulletin = nil
        
        observersContainer.notifyObserversAsync {
            $0.livePlayerDidFinishPlaying(self)
        }
    }
    
    func stop() {
        
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
    
    @discardableResult func isInitializing() -> Bool { state.isInitializing() }
    
    @discardableResult func isActive() -> Bool { state.isActive() }
    
    // MARK: - Private methods
    
    fileprivate func start(with item: BHPlayerItem?, post: BHPost?) {
        
        guard let validItem = item else {
            BHLog.w("\(#function) - empty player item")
            return
        }
                
        playerItem = validItem
        self.post = post
        
        observersContainer.notifyObserversAsync {
            $0.livePlayer(self, initializedWith: validItem)
        }
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onApplicationWillTerminate(_ notification: Notification) {
        if isActive() {
            stop()
        }
    }

}

// MARK: Bulletin

extension BHLivePlayer {
    
    func fetchBulletin() {
        guard let bulletin = post?.bulletin else {
            BHLog.p("post bulletin is empty. Nothing to load")
            return
        }

        BHLog.p("\(#function)")

        BHBulletinManager.shared.getBulletin(bulletin.id, allIncludes: true) { response in
            switch response {
            case .success(bulletin: let b):
                self.bulletin = b
                self.observersContainer.notifyObserversAsync {
                    $0.livePlayer(self, bulletinDidChange: b)
                }
            case .failure(error: let e):
                BHLog.w("Bulletin load failed \(e.localizedDescription)")
            }
        }
    }
}
