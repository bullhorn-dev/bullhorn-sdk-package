
import Foundation
import AVFoundation
import MediaPlayer

class BHSystemAudioPlayer: BHMediaPlayerBase {
    
    override var rate: Float {
        get {
            return playbackRate
        }
        set {
            playbackRate = newValue
            if player.timeControlStatus == .playing {
                player.rate = newValue
            }
            updateNowPlayingInfo()
        }
    }
    
    fileprivate var player: AVQueuePlayer!
    fileprivate var playerItem: AVPlayerItem!
    
    // MARK: - Initialization
    
    override init(withUrl url: URL, coverUrl: URL? = nil, autoPlay: Bool = true) {
        super.init()

        BHLog.p("Init SystemAudioPlayer to play url: \(url.absoluteString)")

        playerItem = AVPlayerItem(url: url)

        configurePlayerItemNotifications()

        player = AVQueuePlayer(playerItem: playerItem)
        player?.volume = 1.0
        player?.actionAtItemEnd = .advance

        configurePlayerNotifications()
    }
    
    // MARK: - Overrides
    
    override func configurePlayerNotifications() {
        super.configurePlayerNotifications()
        
        player.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.timeControlStatus), options: [.old, .new], context:nil)
    }
    
    override func removePlayerNotifications() {
        super.removePlayerNotifications()

        player.removeObserver(self, forKeyPath: #keyPath(AVQueuePlayer.timeControlStatus))
    }
    
    override func configurePlayerItemNotifications() {
        super.configurePlayerItemNotifications()

        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAVPlayerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemPlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemPlaybackStalled(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
    }
    
    override func removePlayerItemNotifications() {
        super.removePlayerItemNotifications()

        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
    }
    
    override func playerResume() {
        player.play()
        player.rate = playbackRate
    }
    
    override func playerSeek(to time: CMTime, forceResume: Bool = false) {
        player.seek(to: time)
        player.rate = playbackRate
    }
    
    override func playerSeek(to time: CMTime, forceResume: Bool = false, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time) { finished in
            self.player.rate = self.playbackRate
            completionHandler(finished)
        }
    }
    
    override func playerPause() {
        player.pause()
    }

    override func playerCurrentTime() -> TimeInterval {
        let time = player.currentTime()
        let timeInterval = time.toTimeInterval()

        return timeInterval.isNaN ? 0 : timeInterval
    }
    
    override func playerDuration() -> TimeInterval {
        
        guard let item = player.currentItem else {
            return 0
        }
        
        let durationTime = item.duration
        let duration = TimeInterval(CMTimeGetSeconds(durationTime))
        
        return duration > 0 ? duration : 0
    }
    
    override func updateState() {
        super.updateState()
        
        var newState: BHMediaPlayerBase.State = .waiting
        
        if readyToPlayFlag {
            if !commandToPlayFlag {
                newState = lastSeekPosition.isNegativeInfinity ? .ended : .paused
            }
            else {
                switch player.timeControlStatus {
                case .paused:
                    newState = .paused
                case .waitingToPlayAtSpecifiedRate:
                    newState = .waiting
                case .playing:
                    newState = .playing
                @unknown default:
                    fatalError("AudioPlayer undefined state")
                }
            }
        }
        else {
            let playerItemStatus = player.currentItem?.status ?? .unknown
            switch playerItemStatus {
            case .readyToPlay:
                readyToPlayFlag = true
                newState = .ready
            case .failed:
                readyToPlayFlag = false
                if BHReachabilityManager.shared.isConnected() {
                    newState = .failed(e: NSError.error(with: NSError.LocalCodes.common, description: "Audio failed to play."))
                } else {
                    newState = .failed(e: NSError.error(with: NSError.LocalCodes.common, description: "The Internet connection is lost."))
                }
            case .unknown:
                newState = .waiting
            @unknown default:
                fatalError("AudioPlayer undefined state")
            }
        }
        
        BHLog.p("\(#function) - state = \(newState)")
        
        updateNowPlayingItemState()
        
        state = newState
    }
}

extension BHSystemAudioPlayer {
    
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
        BHLog.p("\(#function)")
        _ = stop()
        delegate?.mediaPlayerDidFinishPlaying(self)
    }
    
    @objc func playerItemPlaybackStalled(_ notification: Notification) {
        BHLog.p("\(#function)")
        _ = stop()
        delegate?.mediaPlayerDidStallPlaying(self)
    }
    
    @objc fileprivate func onAVPlayerItemFailedToPlayToEndTime(_ notification: Notification) {
        BHLog.p("\(#function)")
        _ = stop()
        delegate?.mediaPlayerDidStallPlaying(self)
    }
}
