
import Foundation
import AVFoundation
import UIKit

class BHSystemVideoPlayer: BHMediaPlayerBase {
    
    private var bmPlayer: BHVideoPlayer!
    private var bmState: BHVideoPlayerState = .notSetURL
    private var bmIsPlaying: Bool = false
    private var bmPosition: TimeInterval = .zero
    private var bmLoadedDuration: TimeInterval = .zero
    private var bmTotalDuration: TimeInterval = .zero
    
    override var startTime: TimeInterval {
        didSet {
            bmPlayer.seek(startTime)
        }
    }
    
    override var rate: Float {
        get {
            return playbackRate
        }
        set {
            playbackRate = newValue
            if bmPlayer.isPlaying {
                bmPlayer.avPlayer?.rate = newValue
            }
            updateNowPlayingInfo()
        }
    }
        
    // MARK: - Initialization
    
    override init(withUrl url: URL, coverUrl: URL?, autoPlay: Bool = true) {
        super.init()

        BHLog.p("Init SystemVideoPlayer to play url: \(url.absoluteString)")

        BHVideoPlayerConf.shouldAutoPlay = true
        BHVideoPlayerConf.tintColor = UIColor.accent()

        let resource = BHVideoPlayerResource(url: url, cover: coverUrl)

        bmPlayer = BHVideoPlayer()
        bmPlayer.setVideo(resource: resource)
        bmPlayer.delegate = self
        bmPlayer.autoPlay()
        
        configurePlayerNotifications()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnteredBackgound), name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    // MARK: - Overrides Video
    
    override func hasVideo() -> Bool {
        return true
    }

    override func getVideoLayer() -> UIView? {
        return bmPlayer
    }

    // MARK: - Overrides
    
    override func playerResume() {
        bmPlayer.play()
        bmPlayer.avPlayer?.rate = playbackRate
    }
    
    override func playerSeek(to time: CMTime, forceResume: Bool = false) {
        bmPlayer.seek(time.toTimeInterval())
        bmPlayer.avPlayer?.rate = playbackRate
    }
    
    override func playerSeek(to time: CMTime, forceResume: Bool = false, completionHandler: @escaping (Bool) -> Void) {
        bmPlayer.seek(time.toTimeInterval()) {
            self.bmPlayer.avPlayer?.rate = self.playbackRate
            completionHandler(true)
        }
    }
    
    override func playerPause() {
        bmPlayer.pause()
    }

    override func playerCurrentTime() -> TimeInterval {
        return bmPosition.isNaN ? 0 : bmPosition.rounded()
    }
    
    override func playerDuration() -> TimeInterval {
        return bmTotalDuration > 0 ? bmTotalDuration : 0
    }
    
    override func updateState() {
        super.updateState()
        
        var newState: BHMediaPlayerBase.State = .waiting
        
        switch bmState {
            case .notSetURL:
                newState = .idle
            case .readyToPlay:
                newState = bmPlayer.isPlaying ? .playing : .paused
                readyToPlayFlag = true
            case .buffering:
                newState = bmPlayer.isPlaying ? .playing : .paused
                readyToPlayFlag = true
            case .bufferFinished:
                newState = bmPlayer.isPlaying ? .playing : .paused
                readyToPlayFlag = true
            case .playedToTheEnd:
                newState = .ended
            case .error:
            if BHReachabilityManager.shared.isConnected() {
                newState = .failed(e: NSError.error(with: NSError.LocalCodes.common, description: "Video failed to play"))
            } else {
                newState = .failed(e: NSError.error(with: NSError.LocalCodes.common, description: "The Internet connection is lost."))
            }
                readyToPlayFlag = false
        }
        
        BHLog.p("\(#function) - state = \(newState)")
        
        updateNowPlayingItemState()
        
        state = newState
    }
}

// MARK: - Notofications

extension BHSystemVideoPlayer {
    
    @objc func appDidEnteredBackgound() {
        bmPlayer.disableVideoTracks()
    }

    @objc func appWillEnteredForeground() {
        bmPlayer.enableVideoTracks()
    }
}

extension BHSystemVideoPlayer {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVQueuePlayer.status), object is AVPlayerItem {
            
            updateState()
            
            if readyToPlayFlag {
                if commandToPlayFlag {
                    _ = play(at: startTime)
                } else {
                    _ = pause()
                }
            }
        }
        else if keyPath == #keyPath(AVQueuePlayer.timeControlStatus), object is AVQueuePlayer {
            updateState()
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc fileprivate func onAVPlayerItemDidPlayToEndTime(_ notification: Notification) {
        _ = stop()
        delegate?.mediaPlayerDidFinishPlaying(self)
    }
}

// MARK: - BMPlayerDelegate

extension BHSystemVideoPlayer: BHVideoPlayerDelegate {

    func bhVideoPlayer(player: BHVideoPlayer, playerStateDidChange state: BHVideoPlayerState) {
        bmState = state
        updateState()
        
        if state == .playedToTheEnd {
            delegate?.mediaPlayerDidFinishPlaying(self)
        }
    }
    
    func bhVideoPlayer(player: BHVideoPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        bmLoadedDuration = loadedDuration
        bmTotalDuration = totalDuration
    }
    
    func bhVideoPlayer(player: BHVideoPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        bmPosition = currentTime
        bmTotalDuration = totalTime
    }
    
    func bhVideoPlayer(player: BHVideoPlayer, playerIsPlaying playing: Bool) {
        bmIsPlaying = playing
        updateState()
    }
    
    func bhVideoPlayer(player: BHVideoPlayer, playerOrientChanged isFullscreen: Bool) {
        //
    }
}
