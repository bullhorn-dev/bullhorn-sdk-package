import Foundation
import AVFoundation
import MediaPlayer

// MARK: - Delegate
// All methods use `any BHPlaybackEngine` so BHHybridPlayer doesn't need to
// know about the concrete player class.

protocol BHMediaPlayerDelegate: AnyObject {
    func mediaPlayer(_ player: any BHPlaybackEngine, stateUpdated state: BHMediaPlayerBase.State)
    func mediaPlayerDidPlayToEndTime(_ player: any BHPlaybackEngine)
    func mediaPlayerDidStall(_ player: any BHPlaybackEngine, reason: BHPlaybackState.StalledReason)
    func mediaPlayerFailedToPlayToEndTime(_ player: any BHPlaybackEngine)
    func mediaPlayerServicesWereLost(_ player: any BHPlaybackEngine)
    func mediaPlayerServicesWereReset(_ player: any BHPlaybackEngine)
    func mediaPlayerDidRequestNowPlayingItemInfo(_ player: any BHPlaybackEngine) -> BHNowPlayingItemInfo
    func mediaPlayerDidAdvanceToNextItem(_ player: any BHPlaybackEngine, completedItemPosition: TimeInterval)
}

// MARK: - BHMediaPlayerBase

class BHMediaPlayerBase: NSObject, BHPlaybackEngine,
                         BHAudioSessionManaging,
                         BHNowPlayingManaging,
                         BHSystemNotificationHandling {

    // MARK: - External State (delegate-facing)

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

    internal var state: State { playbackState.asExternalState }

    // MARK: - BHPlaybackEngine

    weak var delegate: BHMediaPlayerDelegate? {
        didSet { delegate?.mediaPlayer(self, stateUpdated: state) }
    }

    var rate: Float {
        get { playbackRate }
        set { playbackRate = newValue }
    }

    // MARK: - Shared internal state

    internal let timeScale    = TimeInterval(USEC_PER_SEC)
    internal var playbackRate = Constants.defaultPlaybackRate

    // MARK: - Now Playing Item Info
    
    var nowPlayingItemInfo: BHNowPlayingItemInfo = .invalid
    internal lazy var nowPlayingItemPlaybackState = MPNowPlayingPlaybackState.unknown

    // MARK: - Init

    override init() {
        super.init()
        startAudioSession()
    }

    init(withUrl url: URL, coverUrl: URL? = nil, autoPlay: Bool = true) {
        super.init()
        startAudioSession()
    }

    deinit {
        delegate = nil
        _ = stop()
        clearNowPlayingInfo()
        removePlayerNotifications()
        stopAudioSession()
    }

    // MARK: - Engine hooks (override in subclasses)

    internal func playerResume()         {}
    internal func playerRestartPlaying() {}
    internal func playerPause()          {}
    internal func playerCurrentTime() -> TimeInterval { 0 }
    internal func playerDuration()    -> TimeInterval { 0 }

    internal func playerSeek(to time: CMTime, forceResume: Bool) {}
    internal func playerSeek(to time: CMTime, forceResume: Bool,
                             completionHandler: @escaping (Bool) -> Void) {}
    
    func preloadNextItem(url: URL?)          {}
    func clearNextItem()                     {}
    @discardableResult func skipToNextItem() -> Bool { return false }

    // MARK: - BHPlaybackEngine — Playback Control

    @discardableResult
    func play(at time: TimeInterval, forceResume: Bool = false) -> Bool {
        BHLog.p("\(#function) time=\(time)")
        if playbackState.isEngineReady {
            seekAndPlay(to: time, resume: true)
        } else {
            playbackState = .loading(intent: .play(from: time))
        }
        return true
    }

    @discardableResult
    func restore(at time: TimeInterval) -> Bool {
        BHLog.p("\(#function) time=\(time)")
        if playbackState.isEngineReady {
            seekAndPlay(to: time, resume: false)
        } else {
            playbackState = .loading(intent: .restore(at: time))
        }
        return true
    }

    @discardableResult
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

    @discardableResult
    func pause() -> Bool {
        BHLog.p("\(#function)")
        playerPause()
        switch playbackState {
        case .seeking(let to, _): playbackState = .seeking(to: to, resume: false)
        default:                  playbackState = .paused
        }
        return true
    }

    @discardableResult
    func stop() -> Bool {
        BHLog.p("\(#function)")
        playerPause()
        playbackState = .ended
        return true
    }

    // MARK: - BHPlaybackEngine — Seeking

    func seek(to time: TimeInterval) {
        guard playbackState.isEngineReady else { return }
        seekAndPlay(to: time, resume: isPlaying())
    }

    // MARK: - BHPlaybackEngine — Queries

    func currentTime() -> TimeInterval {
        if let pending = playbackState.pendingPosition { return pending }
        let t = playerCurrentTime()
        return t.isNaN ? 0 : t.rounded()
    }

    func duration() -> TimeInterval { playerDuration() }

    func isReady()   -> Bool { if case .ready   = playbackState { return true }; return false }
    func isPlaying() -> Bool { if case .playing = playbackState { return true }; return false }
    func isEnded()   -> Bool { if case .ended   = playbackState { return true }; return false }

    // MARK: - BHPlaybackEngine — Video

    func hasVideo()      -> Bool    { false }
    func getVideoLayer() -> UIView? { nil   }

    // MARK: - Internal helpers

    internal func seekAndPlay(to time: TimeInterval, resume: Bool) {
        let target = max(0, time)
        let needsSeek = abs(playerCurrentTime() - target) > 0.5

        if needsSeek {
            let cmTime = CMTime(value: CMTimeValue(target * timeScale),
                                timescale: CMTimeScale(timeScale))
            playbackState = .seeking(to: target, resume: resume)
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

// MARK: - BHAudioSessionManaging

extension BHMediaPlayerBase {

    func startAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback)
        } catch {
            BHLog.w("\(#function) setCategory: \(error)")
        }
        
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            BHLog.w("\(#function) setActive: \(error)")
        }
    }

    func stopAudioSession() {
        do {
            try AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            BHLog.w("\(#function): \(error)")
        }
    }
}

// MARK: - BHSystemNotificationHandling

extension BHMediaPlayerBase {

    func configurePlayerNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onInterruptionNotification(_:)),
            name: AVAudioSession.interruptionNotification, object: nil)
        nc.addObserver(self, selector: #selector(onMediaServicesWereLostNotification(_:)),
            name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        nc.addObserver(self, selector: #selector(onMediaServicesWereResetNotification(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        nc.addObserver(self, selector: #selector(onRouteChangeNotification(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    func removePlayerNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onInterruptionNotification(_ notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        let shouldResume: Bool = {
            guard let v = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            else { return false }
            return AVAudioSession.InterruptionOptions(rawValue: v).contains(.shouldResume)
        }()
        let wasSuspended = (notification.userInfo?[AVAudioSessionInterruptionWasSuspendedKey]
            as? NSNumber)?.boolValue ?? false

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

    @objc private func onMediaServicesWereLostNotification(_ notification: Notification) {
        delegate?.mediaPlayerServicesWereLost(self)
    }

    @objc private func onMediaServicesWereResetNotification(_ notification: Notification) {
        delegate?.mediaPlayerServicesWereReset(self)
    }

    @objc private func onRouteChangeNotification(_ notification: NSNotification) {
        guard let v = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: v) else { return }
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

