
import UIKit
import Foundation
import SDWebImage

enum PlayerType: Int {
    case recording
    case interactive
    case waitingRoom
    case live
    case stream
}

protocol BHPlayerBaseViewControllerDelegate: AnyObject {
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenUser user: BHUser)
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenPost post: BHPost)
}

class BHPlayerBaseViewController: UIViewController, ActivityIndicatorSupport {

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var topVideoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: BHMediaVideoView!
    @IBOutlet weak var imageLayerView: UIView!
    @IBOutlet weak var liveTagLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var routePickerView: BHRoutePickerView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!

    weak var delegate: BHPlayerBaseViewControllerDelegate?

    var type: PlayerType = .recording
    
    var postsManager = BHPostsManager()

    var playerItem: BHPlayerItem? {
        if let playerItem = BHLivePlayer.shared.playerItem {
            return playerItem
        } else if let playerItem = BHHybridPlayer.shared.playerItem {
            return playerItem
        }
        return nil
    }
    
    var post: BHPost? {
        if BHHybridPlayer.shared.post != nil {
            return BHHybridPlayer.shared.post
        } else if BHLivePlayer.shared.post != nil {
            return BHLivePlayer.shared.post
        }
        return nil
    }

    private var isSliding = false
    
    internal var hasTile = false {
        didSet {
            updateLayers()
        }
    }

    internal var hasVideo = false {
        didSet {
            updateLayers()
        }
    }
    
    internal var isExpanded: Bool = false {
        didSet {
            self.updateAfterExpand()
        }
    }
    
    internal var isPortrait: Bool = true

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BHHybridPlayer.shared.addListener(self)
        BHLivePlayer.shared.addListener(self)
        
        self.view.backgroundColor = .playerDisplayBackground()

        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        self.isPortrait = UIDevice.current.orientation.isPortrait
        
        self.imageLayerView.clipsToBounds = false
        self.imageLayerView.layer.masksToBounds = false
        
        self.liveTagLabel.isHidden = true
        self.liveTagLabel.layer.cornerRadius = 4
        self.liveTagLabel.layer.masksToBounds = true
        
        self.videoView.isHidden = true
        
        self.slider.isContinuous = true
        
        if type == .waitingRoom {
            playButton.isHidden = true
            backwardButton.isHidden = true
            forwardButton.isHidden = true
            routePickerView.isHidden = true
            slider.isHidden = true
            positionLabel.isHidden = true
            durationLabel.isHidden = true
        }
        
        if type == .stream || post?.isLiveStream() == true {
            backwardButton.isHidden = true
            forwardButton.isHidden = true
            optionsButton.isHidden = true
            slider.isHidden = true
            positionLabel.isHidden = true
            durationLabel.isHidden = true
            liveTagLabel.isHidden = false
        }
        
        previousButton.isHidden = true
        nextButton.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideTopMessageView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        BHHybridPlayer.shared.removeListener(self)
        BHLivePlayer.shared.removeListener(self)
        super.viewDidDisappear(animated)
    }
    
    func reloadData() {

        switch type {
        case .recording,
             .interactive,
             .stream:
            let player = BHHybridPlayer.shared
            onStateChanged(player.state, stateFlags: player.stateFlags)
            onPositionChanged(player.lastSentPosition, duration: player.lastSentDuration)
            updateVideoLayer(player.isVideoAvailable)

        case .waitingRoom,
             .live:
            updateVideoLayer(BHLivePlayer.shared.isVideoAvailable)
        }
        
        if let item = playerItem {
            imageView.sd_setImage(with: item.post.userImageUrl)
        }
    }
    
    func updateAfterExpand() {}
    
    // MARK: - Notifications
    
    @objc fileprivate func onUserInterfaceStyleChangedNotification(notification: Notification) {
        guard let dict = notification.userInfo as? NSDictionary else { return }
        guard let value = dict["style"] as? Int else { return }
        
        let style = UIUserInterfaceStyle(rawValue: value) ?? .light

        overrideUserInterfaceStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
        
    // MARK: - Actions

    @IBAction func tapCloseButton() {
        
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerClose, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPlayButton() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isPlaying() {
            BHHybridPlayer.shared.pause()
            
            let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerPause, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
            BHTracker.shared.trackEvent(with: request)

        } else {
            BHHybridPlayer.shared.resume()
            
            let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerPlay, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
            BHTracker.shared.trackEvent(with: request)
        }
    }

    @IBAction func onForwardButton() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.seekForward()
        }
    }
    
    @IBAction func onBackwardButton() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.seekBackward()
        }
    }

    @IBAction func onNextButton() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.playNext()
        }
    }
    
    @IBAction func onPreviousButton() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.playPrevious()
        }
    }

    @IBAction func onOptionsButton() {
        let optionsSheet = BHPlayerOptionsBottomSheet()
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true
        optionsSheet.type = type
        present(optionsSheet, animated: true)
    }

    // MARK: - Slider actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                BHHybridPlayer.shared.isSliding = true
                isSliding = true
            case .ended:
                let seekPosition = Float(BHHybridPlayer.shared.totalDuration()) * sender.value
                BHHybridPlayer.shared.seek(to: Double(seekPosition))
                BHHybridPlayer.shared.isSliding = false
                isSliding = false
                
                let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerSeek, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
                BHTracker.shared.trackEvent(with: request)
            default:
                break
            }
        }
    }

    // MARK: - Public (override)
    
    func onStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }

        var controlsEnabled = false
        var showIndicator = false
        var showRefresh = false

        switch state {
        case .idle:
            showIndicator = true

        case .initializing:
            showIndicator = true

        case .playing:
            controlsEnabled = true
            showIndicator = stateFlags == .buffering
            playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)

        case .paused:
            controlsEnabled = true
            playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)

        case .ended:
            controlsEnabled = true
            playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)

        case .destroyed:
            showRefresh = true
            playButton.setBackgroundImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        }

        if showIndicator {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            playButton.isHidden = true
            backwardButton.isHidden = true
            forwardButton.isHidden = true
            routePickerView.isHidden = true
        } else if showRefresh {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            playButton.isHidden = false
            backwardButton.isHidden = true
            forwardButton.isHidden = true
            playButton.isEnabled = true
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            playButton.isHidden = false
            backwardButton.isHidden = false
            forwardButton.isHidden = false
            playButton.isEnabled = true
            backwardButton.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive()
            forwardButton.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive()
            routePickerView.isHidden = !controlsEnabled
        }
                
        if playerItem.isStream || post?.isLiveStream() == true {
            self.backwardButton.isHidden = true
            self.forwardButton.isHidden = true
        }

        slider.isEnabled = controlsEnabled && (type != .stream || post?.isLiveStream() == true)
    }
    
    func onPositionChanged(_ position: Double, duration: Double) {
        if  duration > 0 && !self.isSliding {
            self.slider.setValue(Float(position/duration), animated: true)
            self.positionLabel.text = position.stringFormatted()
            self.durationLabel.text = "-\((duration-position).stringFormatted())"
        }
        nextButton.isEnabled = BHHybridPlayer.shared.hasNext()
        previousButton.isEnabled = position > 30 || BHHybridPlayer.shared.hasPrevious()
    }
    
    func resetUI() {
        playButton.isEnabled = true
        backwardButton.isEnabled = false
        forwardButton.isEnabled = false
        routePickerView.isHidden = true
        slider.isEnabled = false
        positionLabel.text = "00:00"
        durationLabel.text = "00:00"
        slider.setValue(0, animated: true)
        hasVideo = false
        videoView.reset()
    }
    
    func updateVideoLayer(_ isVideoAvailable: Bool) {
        self.videoView.configureVideoLayer()
        self.hasVideo = isVideoAvailable
    }
    
    func updateLayers() {
        if BHHybridPlayer.shared.isEnded() {
            imageLayerView.isHidden = false
        } else {
            imageLayerView.isHidden = hasVideo || hasTile
        }
    }
    
    func updateLayout(_ useLayout: Bool, position: Double) {
        if useLayout && isPortrait {
            let layoutEvent = BHHybridPlayer.shared.bulletinLayout?.getLayoutEvent(position)
            
            if let validEvent = layoutEvent {
                self.videoView.emptySpaces = validEvent.getEmptySpaces(isPortrait)
            }
        } else {
            self.videoView.emptySpaces = BHEmptySpaces.initial()
        }
    }
    
    func openUser(_ user: BHUser) {
        if type == .stream { return }

        delegate?.playerViewController(self, didRequestOpenUser: user)
    }
    
    func openPost(_ post: BHPost) {
        if type == .stream { return }

        delegate?.playerViewController(self, didRequestOpenPost: post)
    }
}

// MARK: - BHHybridPlayerListener

extension BHPlayerBaseViewController: BHHybridPlayerListener {

    func hybridPlayerDidChangeBulletin(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.hasVideo = player.isVideoAvailable
            self.hasTile = player.hasInteractive()
        }
    }
        
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.resetUI()
            self.reloadData()
        }
    }

    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {
        DispatchQueue.main.async {
            var message = "Failed to play episode. "
            if let validError = error {
                message += " \(validError.localizedDescription)"
            }
            self.showError(message)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.onStateChanged(state, stateFlags: stateFlags)
            self.updateVideoLayer(player.isVideoAvailable)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async {
            if  duration > 0 && !self.isSliding {
                self.onPositionChanged(position, duration: duration)
                self.updateLayout(self.isExpanded, position: position)
            }
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.hasTile = false
            self.hasVideo = false
            self.videoView.reset()
        }
    }
}

// MARK: - BHLivePlayerListener

extension BHPlayerBaseViewController: BHLivePlayerListener {
        
    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.resetUI()
            self.reloadData()
        }
    }
    
    func livePlayer(_ player: BHLivePlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func livePlayer(_ player: BHLivePlayer, bulletinDidChange bulletin: BHBulletin) {
        DispatchQueue.main.async {
            self.hasVideo = player.isVideoAvailable
            self.hasTile = bulletin.hasTiles
        }
    }
    
    func livePlayerDidFinishPlaying(_ player: BHLivePlayer) {
        DispatchQueue.main.async {
            self.resetUI()
        }
    }
    
    func livePlayerDidFailedToPlay(_ player: BHLivePlayer, error: Error?) {
        DispatchQueue.main.async {
            var message = "Failed to play live episode."
            if let validError = error {
                message += " \(validError.localizedDescription)"
            }
            self.showError(message)
        }
    }
}
