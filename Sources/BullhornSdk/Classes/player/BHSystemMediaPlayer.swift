import Foundation
import AVFoundation
import AVKit
import Combine
import UIKit

final class BHSystemMediaPlayer: BHMediaPlayerBase {

    // MARK: - Rate

    override var rate: Float {
        get { playbackRate }
        set {
            playbackRate = newValue
            if player.timeControlStatus == .playing { player.rate = newValue }
            updateNowPlayingInfo()
        }
    }

    // MARK: - Private

    private var player: AVQueuePlayer
    private var playerItem: AVPlayerItem
    private let isVideoContent: Bool
    private var layerView: BHPlayerLayerView?
    private let mediaURL: URL

    private var isIntentionalPause = false
    private var lastKnownPosition: TimeInterval = 0

    // Picture in Picture
    private var pipController: AVPictureInPictureController?
    private(set) var isPiPActive = false

    // Seamless queue support
    private var nextPlayerItem: AVPlayerItem?
    private var nextItemURL: URL?

    private var currentMediaURL: URL

    /// Subscriptions tied to AVPlayer (recreated when player is recreated).
    private var playerCancellables = Set<AnyCancellable>()
    /// Subscriptions tied to AVPlayerItem (recreated on item replacement).
    private var itemCancellables   = Set<AnyCancellable>()

    // MARK: - Init

    init(withUrl url: URL, coverUrl: URL? = nil, isVideo: Bool = false) {
        mediaURL        = url
        currentMediaURL = url
        playerItem      = AVPlayerItem(url: url)
        player          = BHSystemMediaPlayer.makePlayer(with: AVPlayerItem(url: url))
        isVideoContent  = isVideo

        super.init()

        BHLog.p("Init SystemMediaPlayer url:\(url.absoluteString) isVideo:\(isVideo)")

        // Replace the player item reference with the one inside the player
        playerItem = player.currentItem ?? playerItem

        subscribeToPlayer()
        subscribeToPlayerItem()
        configurePlayerNotifications()

        layerView = BHPlayerLayerView(isVideo: isVideo)
        layerView?.setCover(url: coverUrl)

        if isVideo {
            layerView?.connect(to: player)
            subscribeToAppLifecycle()
            setupPictureInPicture()
        }
    }

    override convenience init(withUrl url: URL, coverUrl: URL? = nil, autoPlay: Bool = true) {
        self.init(withUrl: url, coverUrl: coverUrl, isVideo: false)
    }

    // MARK: - Engine hooks

    override func playerResume() {
        player.play()
        player.rate = playbackRate
    }

    override func playerRestartPlaying() {
        player.play()
        player.rate = playbackRate
    }

    override func playerPause() {
        isIntentionalPause = true
        player.pause()
    }

    override func playerSeek(to time: CMTime, forceResume: Bool = false) {
        player.seek(to: time)
        if forceResume { player.rate = playbackRate }
    }

    override func playerSeek(to time: CMTime, forceResume: Bool = false,
                             completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time) { [weak self] finished in
            guard let self else { return }
            if forceResume { self.player.rate = self.playbackRate }
            completionHandler(finished)
        }
    }

    override func playerCurrentTime() -> TimeInterval {
        let t = player.currentTime().toTimeInterval()
        let result = t.isNaN ? 0 : t
        if result > 0 { lastKnownPosition = result }
        return result
    }

    override func playerDuration() -> TimeInterval {
        guard let item = player.currentItem else { return 0 }
        let d = TimeInterval(CMTimeGetSeconds(item.duration))
        return d > 0 ? d : 0
    }

    // MARK: - Video

    override func hasVideo()      -> Bool    { isVideoContent }
    override func getVideoLayer() -> UIView? { layerView }

    // MARK: - Picture in Picture

    private func setupPictureInPicture() {
        // PiP is under development — enabled only in developer mode for now.
        guard UserDefaults.standard.isPictureInPictureFeatureEnabled else { return }
        guard isVideoContent,
              AVPictureInPictureController.isPictureInPictureSupported(),
              let layer = layerView?.avPlayerLayer else { return }

        let pip = AVPictureInPictureController(playerLayer: layer)
        pip?.delegate = self
        pip?.canStartPictureInPictureAutomaticallyFromInline = true
        pipController = pip
        BHLog.p("PiP controller created")
    }

    override func isPictureInPicturePossible() -> Bool {
        pipController?.isPictureInPicturePossible ?? false
    }

    override func isPictureInPictureActive() -> Bool { isPiPActive }

    override func startPictureInPicture() {
        guard let pip = pipController, !pip.isPictureInPictureActive else { return }
        pip.startPictureInPicture()
    }

    override func stopPictureInPicture() {
        guard let pip = pipController, pip.isPictureInPictureActive else { return }
        pip.stopPictureInPicture()
    }

    // MARK: - Seamless Queue

    override func preloadNextItem(url: URL?) {
        guard let url else {
            clearNextItem()
            return
        }
        
        if nextItemURL == url { return }
        clearNextItem()
        let item = AVPlayerItem(url: url)
        nextPlayerItem = item
        nextItemURL    = url
        player.insert(item, after: nil)
        BHLog.p("Preloaded next item: \(url.lastPathComponent)")
    }

    override func clearNextItem() {
        if let item = nextPlayerItem { player.remove(item) }
        nextPlayerItem = nil
        nextItemURL    = nil
    }

    @discardableResult
    override func skipToNextItem() -> Bool {
        guard nextPlayerItem != nil else { return false }
        player.advanceToNextItem()
        return true
    }

    // MARK: - Private factory

    private static func makePlayer(with item: AVPlayerItem) -> AVQueuePlayer {
        let p = AVQueuePlayer(playerItem: item)
        p.volume = 1.0
        p.actionAtItemEnd = .advance
        return p
    }
}

// MARK: - Combine Subscriptions

extension BHSystemMediaPlayer {

    private func subscribeToPlayer() {
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onTimeControlStatusChanged() }
            .store(in: &playerCancellables)

        player.publisher(for: \.currentItem)
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in self?.onCurrentItemChanged(item) }
            .store(in: &playerCancellables)
    }

    private func subscribeToPlayerItem() {
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemStatusChanged() }
            .store(in: &itemCancellables)

        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemDidPlayToEnd() }
            .store(in: &itemCancellables)

        NotificationCenter.default
            .publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemFailedToPlayToEnd() }
            .store(in: &itemCancellables)
    }

    private func subscribeToAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.isPiPActive else { return } // don't disconnect when PiP is active
                self.layerView?.disconnect()
            }
            .store(in: &playerCancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.isPiPActive else { return } // don't connect after PiP was active
                self.layerView?.connect(to: self.player)
                self.layerView?.setNeedsDisplay()
            }
            .store(in: &playerCancellables)
    }
}

// MARK: - State Handlers

extension BHSystemMediaPlayer {

    private func onItemStatusChanged() {
        switch playerItem.status {
        case .readyToPlay:
            switch playbackState {
            case .loading(let intent):
                seekAndPlay(to: intent.startPosition, resume: intent.shouldAutoPlay)
            case .playing, .stalled:
                break
            default:
                playbackState = .ready
            }
        case .failed:
            let error: Error = BHReachabilityManager.shared.isConnected()
                ? NSError.error(with: NSError.LocalCodes.common, description: "Media failed to play.")
                : NSError.error(with: NSError.LocalCodes.common, description: "The Internet connection is lost.")
            playbackState = .failed(error)
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func onCurrentItemChanged(_ newItem: AVPlayerItem?) {
        guard let newItem, newItem === nextPlayerItem else { return }

        
        guard case .failed = playbackState else {
            BHLog.p("\(#function) — seamless advance")

            let finishedItem = playerItem
            let finishedDuration = TimeInterval(CMTimeGetSeconds(finishedItem.duration))
            let completedPosition = (finishedDuration.isFinite && finishedDuration > 0)
                ? finishedDuration
                : lastKnownPosition

            if let url = nextItemURL {
                currentMediaURL = url
            }

            itemCancellables.removeAll()
            playerItem        = newItem
            nextPlayerItem    = nil
            nextItemURL       = nil
            lastKnownPosition = 0
            subscribeToPlayerItem()
            delegate?.mediaPlayerDidAdvanceToNextItem(self, completedItemPosition: completedPosition)
            return
        }

        nextPlayerItem = nil
        nextItemURL    = nil
    }

    private func onTimeControlStatusChanged() {
        if isPiPActive, case .failed = playbackState {
            switch player.timeControlStatus {
            case .playing:
                player.rate = playbackRate
                playbackState = .playing
            case .waitingToPlayAtSpecifiedRate:
                if BHReachabilityManager.shared.isConnected() || currentMediaURL.isFileURL {
                player.rate = playbackRate
                playbackState = .playing
            } else {
                player.pause()
            }
            default:
                break
            }
            return
        }

        guard playbackState.isEngineReady else { return }
        guard case .seeking = playbackState else {
            switch player.timeControlStatus {
            case .playing:
                playbackState = .playing
            case .paused:
                if isIntentionalPause {
                    isIntentionalPause = false
                    if case .playing = playbackState { playbackState = .paused }
                } else if isPiPActive {
                    if case .playing = playbackState { playbackState = .paused }
                } else if case .playing = playbackState {
                    player.play()
                    player.rate = playbackRate
                }
            case .waitingToPlayAtSpecifiedRate:
                if case .failed = playbackState { return }
                guard case .playing = playbackState else { return }
                
                if BHReachabilityManager.shared.isConnected() || currentMediaURL.isFileURL {
                    playbackState = .stalled(reason: .buffering)
                } else {
                    player.pause()
                    clearNextItem()
                    playbackState = .failed(NSError.error(
                        with: NSError.LocalCodes.common,
                        description: "The Internet connection is lost."))
                }
            @unknown default:
                break
            }
            return
        }
    }

    private func onItemDidPlayToEnd() {
        BHLog.p("\(#function)")

        if case .failed = playbackState { return }
        if nextPlayerItem != nil { return }

        playbackState = .ended
        delegate?.mediaPlayerDidPlayToEndTime(self)
    }

    private func onItemFailedToPlayToEnd() {
        BHLog.p("\(#function)")

        playbackState = .ended
        delegate?.mediaPlayerFailedToPlayToEndTime(self)
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension BHSystemMediaPlayer: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        BHLog.p("\(#function)")
        isPiPActive = true
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        BHLog.p("\(#function)")
        delegate?.mediaPlayerDidStartPictureInPicture(self)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        BHLog.w("\(#function) - \(error)")
        isPiPActive = false
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        BHLog.p("\(#function)")
        isPiPActive = false

        if UIApplication.shared.applicationState != .active {
            layerView?.disconnect()
        }

        delegate?.mediaPlayerDidStopPictureInPicture(self)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
                                    completionHandler: @escaping (Bool) -> Void) {
        BHLog.p("\(#function)")
        delegate?.mediaPlayer(self, restorePictureInPictureUI: completionHandler)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    skipByInterval skipInterval: CMTime,
                                    completionHandler: @escaping () -> Void) {
        let delta = CMTimeGetSeconds(skipInterval)
        let target = max(0, playerCurrentTime() + delta)

        BHLog.p("\(#function) delta=\(delta) target=\(target)")

        let cmTime = CMTime(value: CMTimeValue(target * timeScale),
                            timescale: CMTimeScale(timeScale))
        playerSeek(to: cmTime, forceResume: false) { _ in
            completionHandler()
        }
    }
}



