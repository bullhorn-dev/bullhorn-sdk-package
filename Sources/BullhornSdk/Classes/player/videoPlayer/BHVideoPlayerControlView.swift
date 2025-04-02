
import UIKit
import Foundation
import SDWebImage

@objc protocol BHVideoPlayerControlViewDelegate: AnyObject {

    func controlView(controlView: BHVideoPlayerControlView, didChooseDefinition index: Int)
    func controlView(controlView: BHVideoPlayerControlView, didPressButton button: UIButton)
    func controlView(controlView: BHVideoPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
    @objc optional func controlView(controlView: BHVideoPlayerControlView, didChangeVideoPlaybackRate rate: Float)
}

class BHVideoPlayerControlView: UIView {
    
    weak var delegate: BHVideoPlayerControlViewDelegate?
    weak var player: BHVideoPlayer?
    
    // MARK: - Variables

    var resource: BHVideoPlayerResource?
    
    var selectedIndex = 0
    var isFullscreen  = false
    var isMaskShowing = true
    
    var totalDuration: TimeInterval = 0
    var delayItem: DispatchWorkItem?
    
    var playerLastState: BHVideoPlayerState = .notSetURL
    
    fileprivate var isSelectDefinitionViewOpened = false
    
    // MARK: - UI Components

    var mainMaskView   = UIView()
    
    var maskImageView = UIImageView()
        
    var loadingIndicator  = BHActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            
    // MARK: - Handle player state change

    func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {}
    
    func updateUI(_ isFullScreen: Bool) {}
    
    func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {}
    
    func playerStateDidChange(state: BHVideoPlayerState) {
        switch state {
        case .readyToPlay:
            hideLoader()
            hideCoverImageView()
        case .buffering:
            showLoader()
        case .bufferFinished:
            hideLoader()
            hideCoverImageView()
        case .playedToTheEnd:
            break
        default:
            break
        }
        playerLastState = state
    }
    
    func showSeekToView(to toSecound: TimeInterval, total totalDuration:TimeInterval, isAdd: Bool) {}
    
    func prepareUI(for resource: BHVideoPlayerResource, selectedIndex index: Int) {
        self.resource = resource
        self.selectedIndex = index
    }
    
    func playStateDidChange(isPlaying: Bool) {}
        
    func cancelAutoFadeOutAnimation() {
        delayItem?.cancel()
    }
            
    func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    func hideLoader() {
        loadingIndicator.isHidden = true
    }
    
    func hideSeekToView() {}
    
    func showCoverWithLink(_ cover:String) {
        self.showCover(url: URL(string: cover))
    }
    
    func showCover(url: URL?) {
        if let coverUrl = url {
            maskImageView.sd_setImage(with: coverUrl)
        }
    }
    
    func hideCoverImageView() {
        self.maskImageView.isHidden = true
    }
    
    func prepareToDealloc() {
        self.delayItem = nil
    }
        
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUIComponents()
        addConstraints()
        customizeUIComponents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupUIComponents()
        addConstraints()
        customizeUIComponents()
    }
    
    // MARK: - Private
    
    fileprivate func customizeUIComponents() {}
    
    fileprivate func setupUIComponents() {
        
        addSubview(mainMaskView)
        mainMaskView.insertSubview(maskImageView, at: 0)
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = UIColor(white: 0, alpha: 0.0 )
                
        mainMaskView.addSubview(loadingIndicator)
        
        loadingIndicator.type  = BHVideoPlayerConf.loaderType
        loadingIndicator.color = BHVideoPlayerConf.tintColor
    }
    
    fileprivate func addConstraints() {

        mainMaskView.translatesAutoresizingMaskIntoConstraints = false
        maskImageView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainMaskView.leftAnchor.constraint(equalTo: leftAnchor),
            mainMaskView.rightAnchor.constraint(equalTo: rightAnchor),
            mainMaskView.topAnchor.constraint(equalTo: topAnchor),
            mainMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
            maskImageView.heightAnchor.constraint(equalToConstant: 270),
            maskImageView.widthAnchor.constraint(equalToConstant: 270),
            maskImageView.centerXAnchor.constraint(equalTo: mainMaskView.centerXAnchor),
            maskImageView.centerYAnchor.constraint(equalTo: mainMaskView.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: mainMaskView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: mainMaskView.centerYAnchor)
        ])
    }
}

