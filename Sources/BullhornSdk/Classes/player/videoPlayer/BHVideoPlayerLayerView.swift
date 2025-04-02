
import UIKit
import Foundation
import AVFoundation

enum BHVideoPlayerState {
    case notSetURL
    case readyToPlay
    case buffering
    case bufferFinished
    case playedToTheEnd
    case error
}

enum BHVideoPlayerAspectRatio : Int {
    case `default`    = 0
    case sixteen2NINE
    case four2THREE
}

protocol BHVideoPlayerLayerViewDelegate : AnyObject {
    func bhVideoPlayer(player: BHVideoPlayerLayerView, playerStateDidChange state: BHVideoPlayerState)
    func bhVideoPlayer(player: BHVideoPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func bhVideoPlayer(player: BHVideoPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
    func bhVideoPlayer(player: BHVideoPlayerLayerView, playerIsPlaying playing: Bool)
}

class BHVideoPlayerLayerView: UIView {
    
    weak var delegate: BHVideoPlayerLayerViewDelegate?
    
    var seekTime = 0
    
    var playerItem: AVPlayerItem? {
        didSet {
            onPlayerItemChange()
        }
    }
    
    lazy var player: AVPlayer? = {
        if let item = self.playerItem {
            let player = AVPlayer(playerItem: item)
            return player
        }
        return nil
    }()
    
    
    var videoGravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            self.playerLayer?.videoGravity = videoGravity
        }
    }
    
    var isPlaying: Bool = false {
        didSet {
            if oldValue != isPlaying {
                delegate?.bhVideoPlayer(player: self, playerIsPlaying: isPlaying)
            }
        }
    }
    
    var aspectRatio: BHVideoPlayerAspectRatio = .default {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var timer: Timer?
    
    fileprivate var urlAsset: AVURLAsset?
    
    fileprivate var lastPlayerItem: AVPlayerItem?

    fileprivate var playerLayer: AVPlayerLayer?

    fileprivate var volumeViewSlider: UISlider!

    fileprivate var state = BHVideoPlayerState.notSetURL {
        didSet {
            if state != oldValue {
              delegate?.bhVideoPlayer(player: self, playerStateDidChange: state)
            }
        }
    }

    fileprivate var isFullScreen  = false

    fileprivate var isLocked      = false

    fileprivate var isVolume      = false

    fileprivate var isLocalVideo  = false

    fileprivate var sliderLastValue: Float = 0

    fileprivate var repeatToPlay  = false

    fileprivate var playDidEnd    = false

    fileprivate var isBuffering     = false
    fileprivate var hasReadyToPlay  = false
    fileprivate var shouldSeekTo: TimeInterval = 0
    
    // MARK: - Actions

    func playURL(url: URL) {
        let asset = AVURLAsset(url: url)
        playAsset(asset: asset)
    }
    
    func playAsset(asset: AVURLAsset) {
        urlAsset = asset
        onSetVideoAsset()
        play()
    }
    
    
    func play() {
        if let player = player {
            player.play()
            setupTimer()
            isPlaying = true
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        timer?.fireDate = Date.distantFuture
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - layoutSubviews

    override func layoutSubviews() {
        super.layoutSubviews()
        switch self.aspectRatio {
        case .default:
            self.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
            self.playerLayer?.frame  = self.bounds
            break
        case .sixteen2NINE:
            self.playerLayer?.videoGravity = AVLayerVideoGravity.resize
            self.playerLayer?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/(16/9))
            break
        case .four2THREE:
            self.playerLayer?.videoGravity = AVLayerVideoGravity.resize
            let _w = self.bounds.height * 4 / 3
            self.playerLayer?.frame = CGRect(x: (self.bounds.width - _w )/2, y: 0, width: _w, height: self.bounds.height)
            break
        }
    }
    
    func resetPlayer() {

      self.playDidEnd = false
      self.playerItem = nil
      self.lastPlayerItem = nil
      self.seekTime   = 0
      
      self.timer?.invalidate()
      
      self.pause()
 
      self.playerLayer?.removeFromSuperlayer()

      self.player?.replaceCurrentItem(with: nil)
      player?.removeObserver(self, forKeyPath: "rate")
      
      self.player = nil
    }
    
    func prepareToDeinit() {
        self.resetPlayer()
    }
    
    func onTimeSliderBegan() {
        if self.player?.currentItem?.status == AVPlayerItem.Status.readyToPlay {
            self.timer?.fireDate = Date.distantFuture
        }
    }
    
    func seek(to secounds: TimeInterval, completion:(()->Void)?) {
        if secounds.isNaN {
            return
        }
        setupTimer()
        if self.player?.currentItem?.status == AVPlayerItem.Status.readyToPlay {
            let draggedTime = CMTime(value: Int64(secounds), timescale: 1)
            self.player!.seek(to: draggedTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (finished) in
                completion?()
            })
        } else {
            self.shouldSeekTo = secounds
        }
    }
    
    func disableVideoTracks() {
        
        playerLayer?.player = nil
            
        if let tracks = player?.currentItem?.tracks {
            for track in tracks {
                if (track.assetTrack?.hasMediaCharacteristic(AVMediaCharacteristic.visual))! {
                    track.isEnabled = false
                }
            }
        }
    }
    
    func enableVideoTracks() {

        playerLayer?.player = player
            
        if let tracks = player?.currentItem?.tracks {
            for track in tracks {
                if (track.assetTrack?.hasMediaCharacteristic(AVMediaCharacteristic.visual))! {
                    track.isEnabled = true
                }
            }
        }
    }
    
    
    // MARK: - Private

    fileprivate func onSetVideoAsset() {
        repeatToPlay = false
        playDidEnd   = false
        configPlayer()
    }
    
    fileprivate func onPlayerItemChange() {
        if lastPlayerItem == playerItem {
            return
        }
        
        if let item = lastPlayerItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "loadedTimeRanges")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        
        lastPlayerItem = playerItem
        
        if let item = playerItem {
            NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: playerItem)
            
            item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
        }
    }
    
    fileprivate func configPlayer(){
        player?.removeObserver(self, forKeyPath: "rate")
        playerItem = AVPlayerItem(asset: urlAsset!)
        player     = AVPlayer(playerItem: playerItem!)
        player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        self.connectPlayerLayer()
        setNeedsLayout()
        layoutIfNeeded()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.connectPlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.disconnectPlayerLayer), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
        timer?.fireDate = Date()
    }
  
    // MARK: - 计时器事件
    @objc fileprivate func playerTimerAction() {
        guard let playerItem = playerItem else { return }
        
        if playerItem.duration.timescale != 0 {
            let currentTime = CMTimeGetSeconds(self.player!.currentTime())
            let totalTime   = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
            delegate?.bhVideoPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
        }
        updateStatus(includeLoading: true)
    }
    
    fileprivate func updateStatus(includeLoading: Bool = false) {
        if let player = player {
            if let playerItem = playerItem, includeLoading {
                if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
                    self.state = .bufferFinished
                } else if playerItem.status == .failed {
                    self.state = .error
                } else {
                    self.state = .buffering
                }
            }
            if player.rate == 0.0 {
                if player.error != nil {
                    self.state = .error
                    return
                }
                if let currentItem = player.currentItem {
                    if player.currentTime() >= currentItem.duration {
                        moviePlayDidEnd()
                        return
                    }
                    if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Notification Event
    @objc fileprivate func moviePlayDidEnd() {
        if state != .playedToTheEnd {
            if let playerItem = playerItem {
                delegate?.bhVideoPlayer(player: self,
                                   playTimeDidChange: CMTimeGetSeconds(playerItem.duration),
                                   totalTime: CMTimeGetSeconds(playerItem.duration))
            }
            
            self.state = .playedToTheEnd
            self.isPlaying = false
            self.playDidEnd = true
            self.timer?.invalidate()
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let item = object as? AVPlayerItem, let keyPath = keyPath {
            if item == self.playerItem {
                switch keyPath {
                case "status":
                    if item.status == .failed || player?.status == AVPlayer.Status.failed {
                        self.state = .error
                    } else if player?.status == AVPlayer.Status.readyToPlay {
                        self.state = .buffering
                        if shouldSeekTo != 0 {
                            BHLog.p("BHVideoPlayerLayer | Should seek to \(shouldSeekTo)")
                            seek(to: shouldSeekTo, completion: { [weak self] in
                                self?.shouldSeekTo = 0
                                self?.hasReadyToPlay = true
                                self?.state = .readyToPlay
                            })
                        } else {
                            self.hasReadyToPlay = true
                            self.state = .readyToPlay
                        }
                    }
                    
                case "loadedTimeRanges":
                    if let timeInterVarl    = self.availableDuration() {
                        let duration        = item.duration
                        let totalDuration   = CMTimeGetSeconds(duration)
                        delegate?.bhVideoPlayer(player: self, loadedTimeDidChange: timeInterVarl, totalDuration: totalDuration)
                    }
                    
                case "playbackBufferEmpty":
                    if self.playerItem!.isPlaybackBufferEmpty {
                        self.state = .buffering
                        self.bufferingSomeSecond()
                    }
                case "playbackLikelyToKeepUp":
                    if item.isPlaybackBufferEmpty {
                        if state != .bufferFinished && hasReadyToPlay {
                            self.state = .bufferFinished
                            self.playDidEnd = true
                        }
                    }
                default:
                    break
                }
            }
        }
        
        if keyPath == "rate" {
            updateStatus()
        }
    }
    
    fileprivate func availableDuration() -> TimeInterval? {
        if let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSecound = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSecound
            return result
        }
        return nil
    }
    
    fileprivate func bufferingSomeSecond() {
        self.state = .buffering
        
        if isBuffering {
            return
        }
        isBuffering = true
        player?.pause()
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 1.0 )) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {[weak self] in
            guard let `self` = self else { return }
            self.isBuffering = false
            if let item = self.playerItem {
                if !item.isPlaybackLikelyToKeepUp {
                    self.bufferingSomeSecond()
                } else {
                    self.state = BHVideoPlayerState.bufferFinished
                }
            }
        }
    }
    
    @objc fileprivate func connectPlayerLayer() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.videoGravity = videoGravity
        
        layer.addSublayer(playerLayer!)
    }
    
    @objc fileprivate func disconnectPlayerLayer() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}

