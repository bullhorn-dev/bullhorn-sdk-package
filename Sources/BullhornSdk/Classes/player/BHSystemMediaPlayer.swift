import Foundation
import AVFoundation
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

    // MARK: - Init

    init(withUrl url: URL, coverUrl: URL? = nil, isVideo: Bool = false) {
        
        mediaURL = url

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 1.0
        isVideoContent = isVideo

        super.init()

        BHLog.p("Init SystemMediaPlayer url:\(url.absoluteString) isVideo:\(isVideo)")

        configurePlayerItemNotifications()
        configurePlayerNotifications()

        layerView = BHPlayerLayerView(isVideo: isVideo)
        layerView?.setCover(url: coverUrl)
        if isVideo {
            layerView?.connect(to: player)
            addBackgroundObservers()
        }
    }

    override convenience init(withUrl url: URL, coverUrl: URL? = nil, autoPlay: Bool = true) {
        self.init(withUrl: url, coverUrl: coverUrl, isVideo: false)
    }

    deinit { removeBackgroundObservers() }

    // MARK: - Notification setup

    override func configurePlayerNotifications() {
        super.configurePlayerNotifications()
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                           options: [.old, .new], context: nil)
    }

    override func removePlayerNotifications() {
        super.removePlayerNotifications()
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }

    override func configurePlayerItemNotifications() {
        super.configurePlayerItemNotifications()
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemDidPlayToEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemFailedToPlayToEnd(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
    }

    override func removePlayerItemNotifications() {
        super.removePlayerItemNotifications()
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime,      object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
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
        player.rate = playbackRate
    }

    override func playerSeek(to time: CMTime, forceResume: Bool = false,
                             completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time) { [weak self] finished in
            guard let self else { return }
            self.player.rate = self.playbackRate
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

        removePlayerItemNotifications()
        playerItem = AVPlayerItem(url: mediaURL)
        player.replaceCurrentItem(with: playerItem)
        configurePlayerItemNotifications()
        
        layerView?.reset()

        playbackState = .loading(intent: .play(from: position))

        return true
    }

    // MARK: - Video

    override func hasVideo()      -> Bool    { isVideoContent }
    override func getVideoLayer() -> UIView? { layerView }
}

// MARK: - KVO

extension BHSystemMediaPlayer {

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(AVPlayerItem.status) where object is AVPlayerItem:
            DispatchQueue.main.async { self.onItemStatusChanged() }
        case #keyPath(AVPlayer.timeControlStatus) where object is AVPlayer:
            DispatchQueue.main.async { self.onTimeControlStatusChanged() }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func onItemStatusChanged() {
        switch playerItem.status {

        case .readyToPlay:
            switch playbackState {
            case .loading(let intent):
                seekAndPlay(to: intent.startPosition, resume: intent.shouldAutoPlay)

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
                    player.play()
                    player.rate = playbackRate
                }

            case .waitingToPlayAtSpecifiedRate:
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

            @unknown default: break
            }
            return
        }
    }
}

// MARK: - Item Notifications

extension BHSystemMediaPlayer {

    @objc private func onItemDidPlayToEnd(_ notification: Notification) {
        BHLog.p("\(#function)")
        playbackState = .ended
        delegate?.mediaPlayerDidPlayToEndTime(self)
    }

    @objc private func onItemFailedToPlayToEnd(_ notification: Notification) {
        BHLog.p("\(#function)")
        playbackState = .ended
        delegate?.mediaPlayerFailedToPlayToEndTime(self)
    }
}

// MARK: - Background / Foreground

extension BHSystemMediaPlayer {

    private func addBackgroundObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,  object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func removeBackgroundObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification,  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appDidEnterBackground() {
        layerView?.disconnect()
    }

    @objc private func appWillEnterForeground() {
        layerView?.connect(to: player)
        layerView?.setNeedsDisplay()
    }
}
