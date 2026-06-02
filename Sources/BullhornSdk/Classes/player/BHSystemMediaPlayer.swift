import Foundation
import AVFoundation
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

    private let player: AVPlayer
    private var playerItem: AVPlayerItem
    private let isVideoContent: Bool
    private var layerView: BHPlayerLayerView?
    private let mediaURL: URL

    private var isIntentionalPause = false

    /// Subscriptions tied to the current AVPlayer (survive item replacement).
    private var playerCancellables = Set<AnyCancellable>()
    /// Subscriptions tied to the current AVPlayerItem (recreated on item replacement).
    private var itemCancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(withUrl url: URL, coverUrl: URL? = nil, isVideo: Bool = false) {
        mediaURL    = url
        playerItem  = AVPlayerItem(url: url)
        player      = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        isVideoContent = isVideo

        super.init()

        BHLog.p("Init SystemMediaPlayer url:\(url.absoluteString) isVideo:\(isVideo)")

        subscribeToPlayer()
        subscribeToPlayerItem()
        configurePlayerNotifications()   // AVAudioSession notifications from base class

        layerView = BHPlayerLayerView(isVideo: isVideo)
        layerView?.setCover(url: coverUrl)

        if isVideo {
            layerView?.connect(to: player)
            subscribeToAppLifecycle()
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
        if forceResume {
            player.rate = playbackRate
        }
    }

    override func playerSeek(to time: CMTime, forceResume: Bool = false,
                             completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time) { [weak self] finished in
            guard let self else { return }
            if forceResume {
                self.player.rate = self.playbackRate
            }
            completionHandler(finished)
        }
    }

    override func playerCurrentTime() -> TimeInterval {
        let t = player.currentTime().toTimeInterval()
        return t.isNaN ? 0 : t
    }

    override func playerDuration() -> TimeInterval {
        guard let item = player.currentItem else { return 0 }
        let d = TimeInterval(CMTimeGetSeconds(item.duration))
        return d > 0 ? d : 0
    }

    override func retryConnection() -> Bool {
        guard case .failed = playbackState else { return false }

        if !BHReachabilityManager.shared.isConnected() {
            delegate?.mediaPlayer(self, stateUpdated: .failed(e: NSError.error(
                with: NSError.LocalCodes.common,
                description: "The Internet connection is lost.")))
            return false
        }

        let position = playerCurrentTime()

        // Cancel item subscriptions, replace item, resubscribe.
        itemCancellables.removeAll()
        playerItem = AVPlayerItem(url: mediaURL)
        player.replaceCurrentItem(with: playerItem)
        subscribeToPlayerItem()

        layerView?.reset()
        playbackState = .loading(intent: .play(from: position))

        return true
    }

    // MARK: - Video

    override func hasVideo()      -> Bool    { isVideoContent }
    override func getVideoLayer() -> UIView? { layerView }
}

// MARK: - Combine Subscriptions

extension BHSystemMediaPlayer {

    /// Subscribe to AVPlayer-level publishers (survive item replacement).
    private func subscribeToPlayer() {
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onTimeControlStatusChanged() }
            .store(in: &playerCancellables)
    }

    /// Subscribe to the current AVPlayerItem publishers.
    /// Call again after replacing the item.
    private func subscribeToPlayerItem() {
        // Item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemStatusChanged() }
            .store(in: &itemCancellables)

        // Played to end
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemDidPlayToEnd() }
            .store(in: &itemCancellables)

        // Failed to play to end
        NotificationCenter.default
            .publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onItemFailedToPlayToEnd() }
            .store(in: &itemCancellables)
    }

    /// Subscribe to app lifecycle for video layer management.
    private func subscribeToAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.layerView?.disconnect() }
            .store(in: &playerCancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
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

    private func onTimeControlStatusChanged() {
        guard playbackState.isEngineReady else { return }
        guard case .seeking = playbackState else {
            switch player.timeControlStatus {

            case .playing:
                playbackState = .playing

            case .paused:
                if isIntentionalPause {
                    isIntentionalPause = false
                    if case .playing = playbackState { playbackState = .paused }
                } else if case .playing = playbackState {
                    // Not our pause — restore playback (e.g. layer left hierarchy).
                    player.play()
                    player.rate = playbackRate
                }

            case .waitingToPlayAtSpecifiedRate:
                // Guard against re-entering from .failed state.
                if case .failed = playbackState { return }
                guard case .playing = playbackState else { return }

                if BHReachabilityManager.shared.isConnected() {
                    playbackState = .stalled(reason: .buffering)
                } else {
                    player.pause()
                    playbackState = .failed(NSError.error(
                        with: NSError.LocalCodes.common,
                        description: "The Internet connection is lost."))
                }

            @unknown default:
                break
            }
            return
        }
        // Seeking in flight — completion handler owns the transition.
    }

    private func onItemDidPlayToEnd() {
        BHLog.p("\(#function)")
        playbackState = .ended
        delegate?.mediaPlayerDidPlayToEndTime(self)
    }

    private func onItemFailedToPlayToEnd() {
        BHLog.p("\(#function)")
        playbackState = .ended
        delegate?.mediaPlayerFailedToPlayToEndTime(self)
    }
}

