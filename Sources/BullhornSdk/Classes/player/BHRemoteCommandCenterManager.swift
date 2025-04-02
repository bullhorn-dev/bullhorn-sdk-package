
import Foundation
import AVFoundation
import MediaPlayer

protocol BHRemoteCommandCenterDelegate: AnyObject {

    func configureRemoteCommandCenter(_ configureBlock: (BHRemoteCommandCenterManager.Mode) -> Void)

    func onRemoteCommandPlay() -> Bool
    func onRemoteCommandPause() -> Bool
    func onRemoteCommandTogglePlayPause() -> Bool
    func onRemoteCommandSkipBackward() -> Bool
    func onRemoteCommandSkipForward() -> Bool
    func onRemoteCommandPreviousTrack() -> Bool
    func onRemoteCommandNextTrack() -> Bool
    func onRemoteCommandChangePlaybackPosition(_ position: TimeInterval) -> Bool
    func onChangePlaybackRateCommand(_ playbackRate: Float) -> Bool
}

class BHRemoteCommandCenterManager: NSObject {

    enum Mode {
        case singleTrack(backwardTimeIntervals: [TimeInterval], forwardTimeIntervals: [TimeInterval], supportedPlaybackRates: [Float])
        case trackList(backwardTimeIntervals: [TimeInterval], forwardTimeIntervals: [TimeInterval], supportedPlaybackRates: [Float])
        case liveRadioStream
    }

    static let shared: BHRemoteCommandCenterManager = BHRemoteCommandCenterManager()

    weak var delegate: BHRemoteCommandCenterDelegate? {
        didSet {
            delegate?.configureRemoteCommandCenter { mode in
                switch mode {
                case .singleTrack(let backwardTimeIntervals, let forwardTimeIntervals, let supportedPlaybackRates): self.composeSingleTrackButtons(withPrefferedBackwardIntervals: backwardTimeIntervals, prefferedForwardIntervals: forwardTimeIntervals, supportedPlaybackRates: supportedPlaybackRates)
                case .trackList(let backwardTimeIntervals, let forwardTimeIntervals, let supportedPlaybackRates): self.composeTrackListButtons(withPrefferedBackwardIntervals: backwardTimeIntervals, prefferedForwardIntervals: forwardTimeIntervals, supportedPlaybackRates: supportedPlaybackRates)
                case .liveRadioStream:
                    self.composeLiveRadioStreamButtons()
                }
            }
        }
    }

    let playButton = MPRemoteCommandCenter.shared().playCommand
    let pauseButton = MPRemoteCommandCenter.shared().pauseCommand
    
    let toggleButton = MPRemoteCommandCenter.shared().togglePlayPauseCommand

    let skipBackwardButton = MPRemoteCommandCenter.shared().skipBackwardCommand
    let skipForwardButton = MPRemoteCommandCenter.shared().skipForwardCommand

    let previousTrackButton = MPRemoteCommandCenter.shared().previousTrackCommand
    let nextTrackButton = MPRemoteCommandCenter.shared().nextTrackCommand

    let changePlaybackPosition = MPRemoteCommandCenter.shared().changePlaybackPositionCommand
    let changePlaybackRateButton = MPRemoteCommandCenter.shared().changePlaybackRateCommand
    
    // MARK: - Initialization

    override init() {
        super.init()

        playButton.isEnabled = true
        pauseButton.isEnabled = true
        toggleButton.isEnabled = true
        changePlaybackPosition.isEnabled = true
        changePlaybackRateButton.isEnabled = true
        
        addTargets()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    deinit {

        UIApplication.shared.endReceivingRemoteControlEvents()
        removeTargets()
    }

    // MARK: Public methods
        
    func composeSingleTrackButtons(withPrefferedBackwardIntervals prefferedBackwardIntervals: [TimeInterval], prefferedForwardIntervals: [TimeInterval], supportedPlaybackRates: [Float]) {

        skipBackwardButton.isEnabled = true
        skipForwardButton.isEnabled = true
        previousTrackButton.isEnabled = false
        nextTrackButton.isEnabled = false
        changePlaybackRateButton.isEnabled = !supportedPlaybackRates.isEmpty
        
        updateTimeIntervals(withPrefferedBackwardIntervals: prefferedBackwardIntervals, prefferedForwardIntervals: prefferedForwardIntervals)
        updatePlaybackRates(withSupportedPlaybackRates: supportedPlaybackRates)
    }

    func composeTrackListButtons(withPrefferedBackwardIntervals prefferedBackwardIntervals: [TimeInterval], prefferedForwardIntervals: [TimeInterval], supportedPlaybackRates: [Float]) {

        previousTrackButton.isEnabled = true
        nextTrackButton.isEnabled = true
        skipBackwardButton.isEnabled = true
        skipForwardButton.isEnabled = true
        changePlaybackRateButton.isEnabled = !supportedPlaybackRates.isEmpty
        
        updateTimeIntervals(withPrefferedBackwardIntervals: prefferedBackwardIntervals, prefferedForwardIntervals: prefferedForwardIntervals)
        updatePlaybackRates(withSupportedPlaybackRates: supportedPlaybackRates)
    }
    
    func composeLiveRadioStreamButtons() {

        skipBackwardButton.isEnabled = false
        skipForwardButton.isEnabled = false
        previousTrackButton.isEnabled = false
        nextTrackButton.isEnabled = false
        changePlaybackRateButton.isEnabled = false
    }
    
    func enablePlaybackControls(_ value: Bool = true) {
        
        playButton.isEnabled = value
        pauseButton.isEnabled = value
        toggleButton.isEnabled = value
    }
    
    func updateTimeIntervals(withPrefferedBackwardIntervals prefferedBackwardIntervals: [TimeInterval], prefferedForwardIntervals: [TimeInterval]) {
        
        let backwardIntervals = prefferedBackwardIntervals.map { NSNumber.init(value: $0) }
        let forwardIntervals = prefferedForwardIntervals.map { NSNumber.init(value: $0) }

        skipBackwardButton.preferredIntervals = backwardIntervals
        skipForwardButton.preferredIntervals = forwardIntervals
    }

    func updatePlaybackRates(withSupportedPlaybackRates supportedPlaybackRates: [Float]) {
        
        let rates = supportedPlaybackRates.map { NSNumber.init(value: $0) }
        
        changePlaybackRateButton.supportedPlaybackRates = rates
    }

    // MARK: Private methods
    
    fileprivate func addTargets() {

        playButton.addTarget(handler: playHandler(_:))
        pauseButton.addTarget(handler: pauseHandler(_:))
        toggleButton.addTarget(handler: togglePlayPauseHandler(_:))
        skipBackwardButton.addTarget(handler: skipBackwardHandler(_:))
        skipForwardButton.addTarget(handler: skipForwardHandler(_:))
        changePlaybackPosition.addTarget(handler: changePlaybackPositionHandler(_:))
        previousTrackButton.addTarget(handler: previousTrackHandler(_:))
        nextTrackButton.addTarget(handler: nextTrackHandler(_:))
        changePlaybackRateButton.addTarget(handler: onChangePlaybackRateHandler(_:))
    }

    fileprivate func removeTargets() {

        playButton.removeTarget(nil)
        pauseButton.removeTarget(nil)
        toggleButton.removeTarget(nil)
        skipForwardButton.removeTarget(nil)
        skipBackwardButton.removeTarget(nil)
        previousTrackButton.removeTarget(nil)
        nextTrackButton.removeTarget(nil)
        changePlaybackPosition.removeTarget(nil)
        changePlaybackRateButton.removeTarget(nil)
    }

    fileprivate func playHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandPlay()
        return result ? .success : .commandFailed
    }

    fileprivate func pauseHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandPause()
        return result ? .success : .commandFailed
    }
    
    fileprivate func togglePlayPauseHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        guard let validDelegate = delegate else { return .commandFailed }
        
        let result = validDelegate.onRemoteCommandTogglePlayPause()
        return result ? .success : .commandFailed
    }

    fileprivate func skipBackwardHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard event.command is MPSkipIntervalCommand else { return .noSuchContent }
        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandSkipBackward()
        return result ? .success : .commandFailed
    }

    fileprivate func skipForwardHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard event.command is MPSkipIntervalCommand else { return .noSuchContent }
        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandSkipForward()
        return result ? .success : .commandFailed
    }

    fileprivate func changePlaybackPositionHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let changePlaybackPositionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .noSuchContent }
        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandChangePlaybackPosition(changePlaybackPositionEvent.positionTime)
        return result ? .success : .commandFailed
    }

    fileprivate func previousTrackHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandPreviousTrack()
        return result ? .success : .commandFailed
    }

    fileprivate func nextTrackHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onRemoteCommandNextTrack()
        return result ? .success : .commandFailed
    }
    
    fileprivate func onChangePlaybackRateHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {

        guard let changePlaybackRateCommandEvent = event as? MPChangePlaybackRateCommandEvent else { return .noSuchContent }
        guard let validDelegate = delegate else { return .commandFailed }

        let result = validDelegate.onChangePlaybackRateCommand(changePlaybackRateCommandEvent.playbackRate)
        return result ? .success : .commandFailed
    }
}
