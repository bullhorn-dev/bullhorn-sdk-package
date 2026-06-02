import Foundation
import AVFoundation
import MediaPlayer

protocol BHMediaPlayerDelegate: AnyObject {
    func mediaPlayer(_ player: BHMediaPlayerBase, stateUpdated state: BHMediaPlayerBase.State)
    func mediaPlayerDidPlayToEndTime(_ player: BHMediaPlayerBase)
    func mediaPlayerDidStall(_ player: BHMediaPlayerBase, reason: BHPlaybackState.StalledReason)
    func mediaPlayerFailedToPlayToEndTime(_ player: BHMediaPlayerBase)
    func mediaPlayerServicesWereLost(_ player: BHMediaPlayerBase)
    func mediaPlayerServicesWereReset(_ player: BHMediaPlayerBase)
    func mediaPlayerDidRequestNowPlayingItemInfo(_ player: BHMediaPlayerBase) -> BHNowPlayingItemInfo
}

class BHMediaPlayerBase: NSObject {

    // MARK: - External State (delegate-facing, unchanged API)

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
            case (.idle, .idle), (.waiting, .waiting), (.ready, .ready),
                 (.playing, .playing), (.paused, .paused), (.ended, .ended),
                 (.failed, .failed): return true
            default: return false
            }
        }
    }

    // MARK: - Internal State Machine

    /// Single source of truth.
    internal var playbackState: BHPlaybackState = .idle {
        didSet {
            let newExternal = playbackState.asExternalState
            let externalChanged = oldValue.asExternalState != newExternal

            if case .stalled = playbackState {
                updateNowPlayingItemInfo()
            } else if externalChanged {
                delegate?.mediaPlayer(self, stateUpdated: newExternal)
                updateNowPlayingItemInfo()
            }
        }
    }

    /// External state derived from internal — used by NowPlaying extension.
    internal var state: State { playbackState.asExternalState }

    // MARK: - Public properties

    weak var delegate: BHMediaPlayerDelegate? {
        didSet { delegate?.mediaPlayer(self, stateUpdated: state) }
    }

    var rate: Float {
        get { playbackRate }
        set { playbackRate = newValue }
    }

    // MARK: - Internal properties

    internal let timeScale = TimeInterval(USEC_PER_SEC)
    internal var playbackRate = Constants.defaultPlaybackRate
    internal var nowPlayingItemInfo = BHNowPlayingItemInfo.invalid
    internal lazy var nowPlayingItemPlaybackState = MPNowPlayingPlaybackState.unknown

    // MARK: - Init

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

    // MARK: - Overridable engine hooks

    internal func configurePlayerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onInterruptionNotification(_:)),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMediaServicesWereLostNotification(_:)),
            name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMediaServicesWereResetNotification(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRouteChangeNotification(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    internal func removePlayerNotifications()     { NotificationCenter.default.removeObserver(self) }
    internal func configurePlayerItemNotifications() {}
    internal func removePlayerItemNotifications()    {}

    internal func playerResume()          {}
    internal func playerRestartPlaying()  {}
    internal func playerPause()           {}
    internal func playerCurrentTime() -> TimeInterval { return 0 }
    internal func playerDuration()    -> TimeInterval { return 0 }
    internal func playerBaseRate()    -> Float        { return rate }

    internal func playerSeek(to time: CMTime, forceResume: Bool) {}
    internal func playerSeek(to time: CMTime, forceResume: Bool, completionHandler: @escaping (Bool) -> Void) {}

    // MARK: - Public API

    /// Normal launch: seek to `time`, then start playing.
    func play(at time: TimeInterval, forceResume: Bool = false) -> Bool {
        BHLog.p("\(#function) time=\(time)")

        if playbackState.isEngineReady {
            // Engine already ready (e.g. play(at:) called after item loaded) — seek & play.
            seekAndPlay(to: time, resume: true)
        } else {
            // Engine still loading — record intent; executeIntent() will pick it up.
            playbackState = .loading(intent: .play(from: time))
        }
        return true
    }

    /// Session restore: seek to `time`, then stay paused.
    func restore(at time: TimeInterval) -> Bool {
        BHLog.p("\(#function) time=\(time)")

        if playbackState.isEngineReady {
            seekAndPlay(to: time, resume: false)
        } else {
            playbackState = .loading(intent: .restore(at: time))
        }
        return true
    }

    func resume() -> Bool {
        BHLog.p("\(#function)")
        switch playbackState {
        case .paused, .ready:
            playerResume()
            playbackState = .playing
        case .ended:
            seekAndPlay(to: 0, resume: true)
        default:
            break
        }
        return true
    }

    func pause() -> Bool {
        BHLog.p("\(#function)")
        playerPause()
        switch playbackState {
        case .seeking(let to, _): playbackState = .seeking(to: to, resume: false)
        default:                  playbackState = .paused
        }
        return true
    }

    func stop() -> Bool {
        BHLog.p("\(#function)")
        playerPause()
        playbackState = .ended
        return true
    }

    func retryConnection() -> Bool {
        BHLog.p("\(#function)")
        guard case .stalled = playbackState else { return false }
        playbackState = .paused
        return true
    }

    // MARK: - Queries

    func currentTime() -> TimeInterval {
        if let pending = playbackState.pendingPosition { return pending }
        let t = playerCurrentTime()
        return t.isNaN ? 0 : t.rounded()
    }

    func duration() -> TimeInterval { playerDuration() }

    func isReady()   -> Bool { if case .ready   = playbackState { return true }; return false }
    func isPlaying() -> Bool { if case .playing = playbackState { return true }; return false }
    func isEnded()   -> Bool { if case .ended   = playbackState { return true }; return false }

    // MARK: - Video

    func hasVideo()      -> Bool    { false }
    func getVideoLayer() -> UIView? { nil   }

    // MARK: - Internal helpers

    internal func seekAndPlay(to time: TimeInterval, resume: Bool) {
        if time > 0 {
            let cmTime = CMTime(value: CMTimeValue(time * timeScale),
                                timescale: CMTimeScale(timeScale))
            playbackState = .seeking(to: time, resume: resume)
            playerSeek(to: cmTime, forceResume: false) { [weak self] finished in
                guard let self, finished else { return }
                if resume {
                    self.playerResume()
                    self.playbackState = .playing
                } else {
                    self.playbackState = .paused
                }
            }
        } else {
            if resume {
                playerResume()
                playbackState = .playing
            } else {
                playbackState = .paused
            }
        }
    }
}

// MARK: - Audio Session

extension BHMediaPlayerBase {

    fileprivate func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do { try session.setCategory(.playback) }
        catch { BHLog.w("\(#function) setCategory: \(error)") }
        do { try session.setActive(true, options: .notifyOthersOnDeactivation) }
        catch { BHLog.w("\(#function) setActive: \(error)") }
    }

    fileprivate func stopAudioSession() {
        do { try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        catch { BHLog.w("\(#function): \(error)") }
    }
}

// MARK: - System Notifications

extension BHMediaPlayerBase {

    @objc fileprivate func onInterruptionNotification(_ notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        let shouldResume = {
            guard let optValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else { return false }
            return AVAudioSession.InterruptionOptions(rawValue: optValue).contains(.shouldResume)
        }()
        let wasSuspended = (notification.userInfo?[AVAudioSessionInterruptionWasSuspendedKey] as? NSNumber)?.boolValue ?? false

        switch type {
        case .began where !wasSuspended:
            updateNowPlayingItemState(isInterrupted: true)
            updateNowPlayingItemInfo()
            _ = pause()
        case .ended where shouldResume:
            updateNowPlayingItemState(isInterrupted: false)
            updateNowPlayingItemInfo()
            _ = resume()
        default:
            break
        }
    }

    @objc fileprivate func onMediaServicesWereLostNotification(_ notification: Notification) {
        delegate?.mediaPlayerServicesWereLost(self)
    }

    @objc fileprivate func onMediaServicesWereResetNotification(_ notification: Notification) {
        delegate?.mediaPlayerServicesWereReset(self)
    }

    @objc fileprivate func onRouteChangeNotification(_ notification: NSNotification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        switch reason {
        case .oldDeviceUnavailable:
            _ = pause()
        case .newDeviceAvailable where isPlaying():
            DispatchQueue.main.async { self.playerRestartPlaying() }
        default:
            break
        }
    }
}
