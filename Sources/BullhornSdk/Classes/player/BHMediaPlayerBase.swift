
import Foundation
import AVFoundation
import MediaPlayer

protocol BHMediaPlayerDelegate: AnyObject {
    func mediaPlayer(_ player: BHMediaPlayerBase, stateUpdated state: BHMediaPlayerBase.State)
    func mediaPlayerDidFinishPlaying(_ player: BHMediaPlayerBase)
    func mediaPlayerDidStallPlaying(_ player: BHMediaPlayerBase)
    func mediaPlayerServicesWereLost(_ player: BHMediaPlayerBase)
    func mediaPlayerServicesWereReset(_ player: BHMediaPlayerBase)
    func mediaPlayerDidRequestNowPlayingItemInfo(_ player: BHMediaPlayerBase) -> BHNowPlayingItemInfo
}

class BHMediaPlayerBase: NSObject {

    enum State: Equatable {
        case idle
        case waiting
        case ready
        case playing
        case paused
        case ended
        case failed(e: Error?)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.waiting, .waiting): return true
            case (.ready, .ready): return true
            case (.playing, .playing): return true
            case (.paused, .paused): return true
            case (.ended, .ended): return true
            case (.failed(_), .failed(_)): return true
            default: return false
            }
        }
    }

    weak var delegate: BHMediaPlayerDelegate? {
        didSet {
            delegate?.mediaPlayer(self, stateUpdated: state)
        }
    }

    var startTime: TimeInterval = 0

    var rate = Constants.defaultPlaybackRate
    
    internal var state = State.idle {
        didSet {
            if !(oldValue == state) {
                delegate?.mediaPlayer(self, stateUpdated: state)
                updateNowPlayingItemInfo()
            }
        }
    }
    
    internal var nowPlayingItemInfo = BHNowPlayingItemInfo.invalid

    lazy internal var nowPlayingItemPlaybackState = MPNowPlayingPlaybackState.unknown

    fileprivate let timeScale = TimeInterval(USEC_PER_SEC)
    internal var playbackRate = Constants.defaultPlaybackRate
    internal var lastSeekPosition = CMTime.invalid

    internal var readyToPlayFlag: Bool = false
    internal var commandToPlayFlag: Bool = true

    // MARK: - Initialization
    
    override init() {
        super.init()

        configureAudioSession()
    }
    
    init(withUrl url: URL, coverUrl: URL? = nil, autoPlay: Bool = true) {
        super.init()

        configureAudioSession()
    }
    
    deinit {

        delegate = nil
        _ = stop()
        clearNowPlayingInfo()
        removePlayerItemNotifications()
        removePlayerNotifications()
        stopAudioSession()
    }
    
    // MARK: - methods to override
    
    internal func configurePlayerNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(onInterruptionNotification(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMediaServicesWereLostNotification(_:)), name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMediaServicesWereResetNotification(_:)), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRouteChangeNotification(_:)),name: AVAudioSession.routeChangeNotification, object: nil)
    }

    internal func removePlayerNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    internal func configurePlayerItemNotifications() {}
    
    internal func removePlayerItemNotifications() {}
    
    internal func playerResume() {}

    internal func playerRestartPlaying() {}

    internal func playerSeek(to timeInterval: TimeInterval, forceResume: Bool) {}

    internal func playerSeek(to time: CMTime, forceResume: Bool) {}

    internal func playerSeek(to time: CMTime, forceResume: Bool, completionHandler: @escaping (Bool) -> Void) {}
    
    internal func playerPause() {}
    
    internal func playerCurrentTime() -> TimeInterval { return 0 }
    
    internal func playerDuration() -> TimeInterval { return 0 }

    internal func playerBaseRate() -> Float { return rate }

    internal func updateState() {

        if case(.failed(_)) = state {
            return
        }
    }
    
    // MARK: - Public
    
    func resume() -> Bool {
        
        BHLog.p("\(#function)")
        
        commandToPlayFlag = true
        startTime = playerCurrentTime()

        playerResume()
        
        updateState()
        
        return true
    }

    func play(at time: TimeInterval, forceResume: Bool = false) -> Bool {

        BHLog.p("\(#function) - time = \(time)")

        commandToPlayFlag = true
        startTime = time
        
        if readyToPlayFlag {
            lastSeekPosition = CMTime.init(value: CMTimeValue(time * timeScale), timescale: CMTimeScale(timeScale))
            playerSeek(to: lastSeekPosition, forceResume: forceResume) { finished in
                if finished {
                    self.lastSeekPosition = .invalid
                }
                self.updateState()
            }

            if playbackRate.isZero {
                playbackRate = 1
            }
            rate = playbackRate
        }

        return true
    }
    
    func stop() -> Bool {
        
        BHLog.p("\(#function)")

        playerPause()
        commandToPlayFlag = false

        lastSeekPosition = .negativeInfinity

        updateState()

        return true
    }
    
    func pause() -> Bool {
        
        BHLog.p("\(#function)")

        playerPause()
        commandToPlayFlag = false

        updateState()

        return true
    }
    
    func currentTime() -> TimeInterval {

        let time: TimeInterval
        if !readyToPlayFlag {
            time = startTime
        }
        else if lastSeekPosition.isValid && !lastSeekPosition.isNegativeInfinity {
            time = lastSeekPosition.toTimeInterval()
        }
        else {
            time = playerCurrentTime()
        }
        
        return time.isNaN ? 0 : time.rounded()
    }

    func duration() -> TimeInterval {
        return playerDuration()
    }

    func isReady() -> Bool {
        
        if case .ready = state {
            return true
        }
        return false
    }

    func isPlaying() -> Bool {

        if case .playing = state {
            return true
        }
        return false
    }
    
    func isEnded() -> Bool {

        if case .ended = state {
            return true
        }
        return false
    }
    
    
    // MARK: - Video

    func hasVideo() -> Bool { return false }

    func getVideoLayer() -> UIView? { return nil }
}

// MARK: - Notifications

extension BHMediaPlayerBase {
    
    @objc fileprivate func onInterruptionNotification(_ notification: Notification) {
        BHLog.p("\(#function)")
        
        guard let interruptionTypeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        guard let interruptionType = AVAudioSession.InterruptionType.init(rawValue: interruptionTypeValue) else { return }

        let shouldResume: Bool
        if let interruptionOptionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
            let interruptionOptions = AVAudioSession.InterruptionOptions.init(rawValue: interruptionOptionsValue)
            shouldResume = interruptionOptions.contains(.shouldResume)
        }
        else {
            shouldResume = false
        }

        let wasSuspended: Bool
        let wasSuspendedNumber = notification.userInfo?[AVAudioSessionInterruptionWasSuspendedKey] as? NSNumber
        wasSuspended = wasSuspendedNumber?.boolValue ?? false

        let isInterrupted: Bool
        switch interruptionType {
        case .began: isInterrupted = !wasSuspended
        case .ended: isInterrupted = false
        @unknown default:
            isInterrupted = false
        }

        updateNowPlayingItemState(isInterrupted: isInterrupted)
        updateNowPlayingItemInfo()

        if isInterrupted {
            _ = pause()
        }
        else if shouldResume {
            _ = resume()
        }
    }

    @objc fileprivate func onMediaServicesWereLostNotification(_ notification: Notification) {
        BHLog.p("\(#function)")
        delegate?.mediaPlayerServicesWereLost(self)
    }

    @objc fileprivate func onMediaServicesWereResetNotification(_ notification: Notification) {
        BHLog.p("\(#function)")
        delegate?.mediaPlayerServicesWereReset(self)
    }

    @objc fileprivate func onRouteChangeNotification(_ notification: NSNotification) {

        guard let routeChangeReasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else { return }
        guard let routeChangeReason = AVAudioSession.RouteChangeReason.init(rawValue: routeChangeReasonValue) else { return }

        switch routeChangeReason {
        case .oldDeviceUnavailable: _ = pause()
        case .newDeviceAvailable:
            if isPlaying() {
                DispatchQueue.main.async {
                    self.playerRestartPlaying()
                }
            }
        default: break
        }
    }
}

extension BHMediaPlayerBase {
    
    fileprivate func configureAudioSession() {
        BHLog.p("\(#function)")

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback)
        } catch let error as NSError {
            BHLog.w("\(#function) - Unable to set category:  \(error.localizedDescription)")
        }

        do {
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let error as NSError {
            BHLog.w("\(#function) - Unable to activate:  \(error.localizedDescription)")
        }
    }
    
    fileprivate func stopAudioSession() {
        BHLog.p("\(#function)")
        
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch let error as NSError {
            BHLog.w("\(#function) - Unable to stop:  \(error.localizedDescription)")
        }
    }
}
