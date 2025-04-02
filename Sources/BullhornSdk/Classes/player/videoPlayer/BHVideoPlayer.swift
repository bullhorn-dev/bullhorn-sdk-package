
import UIKit
import Foundation
import MediaPlayer

protocol BHVideoPlayerDelegate : AnyObject {

    func bhVideoPlayer(player: BHVideoPlayer, playerStateDidChange state: BHVideoPlayerState)
    func bhVideoPlayer(player: BHVideoPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func bhVideoPlayer(player: BHVideoPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
    func bhVideoPlayer(player: BHVideoPlayer, playerIsPlaying playing: Bool)
    func bhVideoPlayer(player: BHVideoPlayer, playerOrientChanged isFullscreen: Bool)
}

class BHVideoPlayer: UIView {
    
    weak var delegate: BHVideoPlayerDelegate?
    
    var backBlock:((Bool) -> Void)?
        
    var videoGravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            self.playerLayer?.videoGravity = videoGravity
        }
    }
    
    var isPlaying: Bool {
        get {
            return playerLayer?.isPlaying ?? false
        }
    }
    
    var playTimeDidChange:((TimeInterval, TimeInterval) -> Void)?

    var playOrientChanged:((Bool) -> Void)?

    var isPlayingStateChanged:((Bool) -> Void)?

    var playStateChanged:((BHVideoPlayerState) -> Void)?
    
    var avPlayer: AVPlayer? {
        return playerLayer?.player
    }
    
    var playerLayer: BHVideoPlayerLayerView?
    
    fileprivate var resource: BHVideoPlayerResource!
    
    fileprivate var currentDefinition = 0
    
    fileprivate var controlView: BHVideoPlayerControlView!
    
    fileprivate var customControlView: BHVideoPlayerControlView?
                    
    fileprivate var totalDuration   : TimeInterval = 0
    fileprivate var currentPosition : TimeInterval = 0
    fileprivate var shouldSeekTo    : TimeInterval = 0
    
    fileprivate var isURLSet        = false
    fileprivate var isPauseByUser   = false
    fileprivate var isPlayToTheEnd  = false

    fileprivate var aspectRatio: BHVideoPlayerAspectRatio = .default
    
    fileprivate var isPlayingCache: Bool? = nil
    
    // MARK: - Player
    
    func setVideo(resource: BHVideoPlayerResource, definitionIndex: Int = 0) {
        isURLSet = false
        self.resource = resource
        
        currentDefinition = definitionIndex
        controlView.prepareUI(for: resource, selectedIndex: definitionIndex)
        
        if BHVideoPlayerConf.shouldAutoPlay {
            isURLSet = true
            let asset = resource.definitions[definitionIndex]
            playerLayer?.playAsset(asset: asset.avURLAsset)
        } else {
            controlView.showCover(url: resource.cover)
            controlView.hideLoader()
        }
    }
    
    func autoPlay() {
        if !isPauseByUser && isURLSet && !isPlayToTheEnd {
            play()
        }
    }
    
    func play() {
        guard resource != nil else { return }
        
        if !isURLSet {
            let asset = resource.definitions[currentDefinition]
            playerLayer?.playAsset(asset: asset.avURLAsset)
            isURLSet = true
        }
        
        playerLayer?.play()
        isPauseByUser = false
    }
    
    func pause(allowAutoPlay allow: Bool = false) {
        playerLayer?.pause()
        isPauseByUser = !allow
    }
    
    func seek(_ to:TimeInterval, completion: (()->Void)? = nil) {
        playerLayer?.seek(to: to, completion: completion)
    }

    func disableVideoTracks() {
        playerLayer?.disableVideoTracks()
    }

    func enableVideoTracks() {
        playerLayer?.enableVideoTracks()
    }

    // MARK: - Utils

    func updateUI() {
//        controlView.updateUI()
    }
        
    func prepareToDealloc() {
        playerLayer?.prepareToDeinit()
        controlView.prepareToDealloc()
    }
    
    func storyBoardCustomControl() -> BHVideoPlayerControlView? {
        return nil
    }
    
    // MARK: - Deinit

    deinit {
        playerLayer?.pause()
        playerLayer?.prepareToDeinit()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    // MARK: - Public initializers

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let customControlView = storyBoardCustomControl() {
            self.customControlView = customControlView
        }
        initUI()
        preparePlayer()
    }
    
    public init(customControlView: BHVideoPlayerControlView?) {
        super.init(frame: .zero)

        self.customControlView = customControlView
        initUI()
        preparePlayer()
    }
    
    public convenience init() {
        self.init(customControlView:nil)
    }
    
    // MARK: - Private initializers

    fileprivate func initUI() {

        self.backgroundColor = .clear
        
        if let customView = customControlView {
            controlView = customView
        } else {
            controlView = BHVideoPlayerControlView()
        }
        
        addSubview(controlView)
        controlView.updateUI(false)
        controlView.delegate = self
        controlView.player = self
        controlView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            controlView.leftAnchor.constraint(equalTo: leftAnchor),
            controlView.rightAnchor.constraint(equalTo: rightAnchor),
            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
        
    fileprivate func preparePlayer() {

        playerLayer = BHVideoPlayerLayerView()
        
        guard let validPlayerLayer = playerLayer else {
            controlView.showLoader()
            return
        }
        
        validPlayerLayer.videoGravity = videoGravity

        insertSubview(validPlayerLayer, at: 0)

        validPlayerLayer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            validPlayerLayer.leftAnchor.constraint(equalTo: leftAnchor),
            validPlayerLayer.rightAnchor.constraint(equalTo: rightAnchor),
            validPlayerLayer.topAnchor.constraint(equalTo: topAnchor),
            validPlayerLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        validPlayerLayer.delegate = self
        controlView.showLoader()

        layoutIfNeeded()
    }
}

// MARK: - BHVideoPlayerLayerViewDelegate

extension BHVideoPlayer: BHVideoPlayerLayerViewDelegate {

    public func bhVideoPlayer(player: BHVideoPlayerLayerView, playerIsPlaying playing: Bool) {
        
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.bhVideoPlayer(player: self, playerIsPlaying: playing)
        isPlayingStateChanged?(player.isPlaying)
    }
    
    public func bhVideoPlayer(player: BHVideoPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {

        BHVideoPlayerManager.shared.log("loadedTimeDidChange - \(loadedDuration) - \(totalDuration)")

        controlView.loadedTimeDidChange(loadedDuration: loadedDuration, totalDuration: totalDuration)
        delegate?.bhVideoPlayer(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
        controlView.totalDuration = totalDuration
        self.totalDuration = totalDuration
    }
    
    public func bhVideoPlayer(player: BHVideoPlayerLayerView, playerStateDidChange state: BHVideoPlayerState) {

        BHVideoPlayerManager.shared.log("playerStateDidChange - \(state)")
        
        controlView.playerStateDidChange(state: state)
        switch state {
        case .readyToPlay:
            if !isPauseByUser {
                play()
            }
            if shouldSeekTo != 0 {
                seek(shouldSeekTo, completion: {[weak self] in
                  guard let `self` = self else { return }
                  if !self.isPauseByUser {
                      self.play()
                  } else {
                      self.pause()
                  }
                })
                shouldSeekTo = 0
            }

        case .buffering:
            controlView.showCover(url: resource.cover)

        case .bufferFinished:
            autoPlay()
            
        case .playedToTheEnd:
            isPlayToTheEnd = true
            
        default:
            break
        }

        delegate?.bhVideoPlayer(player: self, playerStateDidChange: state)
        playStateChanged?(state)
    }
    
    public func bhVideoPlayer(player: BHVideoPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {

        BHVideoPlayerManager.shared.log("playTimeDidChange - \(currentTime) - \(totalTime)")

        delegate?.bhVideoPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
        self.currentPosition = currentTime
        totalDuration = totalTime

        controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
        controlView.totalDuration = totalDuration
        playTimeDidChange?(currentTime, totalTime)
    }
}

// MARK: - BHVideoPlayerControlViewDelegate

extension BHVideoPlayer: BHVideoPlayerControlViewDelegate {

    func controlView(controlView: BHVideoPlayerControlView,
                          didChooseDefinition index: Int) {
        shouldSeekTo = currentPosition
        playerLayer?.resetPlayer()
        currentDefinition = index
        playerLayer?.playAsset(asset: resource.definitions[index].avURLAsset)
    }
    
    func controlView(controlView: BHVideoPlayerControlView,
                          didPressButton button: UIButton) {}
    
    func controlView(controlView: BHVideoPlayerControlView,
                          slider: UISlider,
                          onSliderEvent event: UIControl.Event) {}
    
    func controlView(controlView: BHVideoPlayerControlView, didChangeVideoPlaybackRate rate: Float) {
        self.playerLayer?.player?.rate = rate
    }
}
