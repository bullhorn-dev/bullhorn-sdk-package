
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
    
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var topVideoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: BHMediaVideoView!
    @IBOutlet weak var imageLayerView: UIView!
    @IBOutlet weak var liveTagLabel: UILabel!
    @IBOutlet weak var overlayView: UIView!
    
    // MARK: - Outlet Collections
    
    @IBOutlet var closeButtons: [UIButton]!
    @IBOutlet var optionsButtons: [UIButton]!
    @IBOutlet var routePickerViews: [BHRoutePickerView]!
    @IBOutlet var queueButtons: [UIButton]!
    @IBOutlet var fullScreenButtons: [UIButton]!
    @IBOutlet var playButtons: [UIButton]!
    @IBOutlet var forwardButtons: [UIButton]!
    @IBOutlet var backwardButtons: [UIButton]!
    @IBOutlet var sleepTimerButtons: [UIButton]!
    @IBOutlet var playbackSpeedButtons: [UIButton]!
    @IBOutlet var positionLabels: [UILabel]!
    @IBOutlet var durationLabels: [UILabel]!
    @IBOutlet var sliders: [UISlider]!

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
    
    internal var isFullscreen: Bool = false

    internal var selectedIndexPaths = Set<IndexPath>()

    internal let hideOverlayInterval: Double = 5.0
    internal var overlayTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .playerDisplayBackground()

        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        self.imageLayerView.clipsToBounds = false
        self.imageLayerView.layer.masksToBounds = false
        
        self.liveTagLabel.isHidden = true
        self.liveTagLabel.layer.cornerRadius = 6
        self.liveTagLabel.layer.masksToBounds = true
        self.liveTagLabel.layer.borderWidth = 2
        self.liveTagLabel.layer.borderColor = UIColor.playerDisplayBackground().cgColor
        
        self.positionLabels.forEach({ $0.adjustsFontForContentSizeCategory = true })
        self.positionLabels.forEach({ $0.font = .primaryText() })
        self.durationLabels.forEach({ $0.adjustsFontForContentSizeCategory = true })
        self.durationLabels.forEach({ $0.font = .primaryText() })
        
        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        self.playbackSpeedButtons.forEach({ $0.setTitle("1x", for: .normal) })
        self.playbackSpeedButtons.forEach({ $0.titleLabel?.font = font })
        
        let config = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .medium, scale: .large)
        let image = UIImage(systemName: "timer")?.withConfiguration(config)
        self.sleepTimerButtons.forEach({ $0.setImage(image, for: .normal) })

        self.videoView.isHidden = true
        
        self.sliders.forEach({ $0.isContinuous = true })

        queueButtons.forEach({ $0.isHidden = !BHHybridPlayer.shared.shouldShowQueueButton() })

        if type == .waitingRoom {
            playButtons.forEach({ $0.isHidden = true })
            backwardButtons.forEach({ $0.isHidden = true })
            forwardButtons.forEach({ $0.isHidden = true })
            playbackSpeedButtons.forEach({ $0.isHidden = true })
            sleepTimerButtons.forEach({ $0.isHidden = true })
            routePickerViews.forEach({ $0.isHidden = true })
            sliders.forEach({ $0.isHidden = true })
            positionLabels.forEach({ $0.isHidden = true })
            durationLabels.forEach({ $0.isHidden = true })
        }
        
        if type == .stream || post?.isLiveStream() == true {
            backwardButtons.forEach({ $0.isHidden = true })
            forwardButtons.forEach({ $0.isHidden = true })
            playbackSpeedButtons.forEach({ $0.isHidden = true })
            sleepTimerButtons.forEach({ $0.isHidden = true })
            optionsButtons.forEach({ $0.isHidden = true })
            sliders.forEach({ $0.isHidden = true })
            positionLabels.forEach({ $0.isHidden = true })
            durationLabels.forEach({ $0.isHidden = true })
            liveTagLabel.isHidden = false
        }
        
        BHHybridPlayer.shared.isFullScreen = false
        showOverlay(false)

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)

        let tapOverlayViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOverlayView(_:)))
        overlayView.addGestureRecognizer(tapOverlayViewGestureRecognizer)

        setupAccessibility()
                
        BHHybridPlayer.shared.addListener(self, withDuplicates: true)
//        BHLivePlayer.shared.addListener(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
        updateSettingsControls()
        
        BHOrientationManager.shared.landscapeSupported = true
        onDeviceOrientationChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideTopMessageView()
        showOverlay(false)
        invalidateOverlayTimer()
        BHOrientationManager.shared.landscapeSupported = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        BHHybridPlayer.shared.removeListener(self)
//        BHLivePlayer.shared.removeListener(self)
        super.viewDidDisappear(animated)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return isFullscreen ? .landscape : .allButUpsideDown
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return isFullscreen ? .landscapeRight : .portrait
    }
 
    func setupAccessibility() {
        playButtons.forEach({ $0.isAccessibilityElement = true })
        playButtons.forEach({ $0.accessibilityLabel = "Play" })
        forwardButtons.forEach({ $0.isAccessibilityElement = true })
        forwardButtons.forEach({ $0.accessibilityLabel = "Forward 15 seconds" })
        backwardButtons.forEach({ $0.isAccessibilityElement = true })
        backwardButtons.forEach({ $0.accessibilityLabel = "Backward 15 seconds" })
        optionsButtons.forEach({ $0.isAccessibilityElement = true })
        optionsButtons.forEach({ $0.accessibilityLabel = "More options" })
        closeButtons.forEach({ $0.isAccessibilityElement = true })
        closeButtons.forEach({ $0.accessibilityLabel = "Collapse Player" })
        queueButtons.forEach({ $0.accessibilityLabel = "Show playback queue" })
        positionLabels.forEach({ $0.accessibilityTraits = .updatesFrequently })
        durationLabels.forEach({ $0.accessibilityTraits = .updatesFrequently })
                
        fullScreenButtons.forEach({ $0.isAccessibilityElement = true })
        fullScreenButtons.forEach({ $0.accessibilityTraits = .button })
        fullScreenButtons.forEach({ $0.accessibilityLabel = "Full Screen" })

        updateSettingsControls()
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
            imageView.sd_setImage(with: item.post.coverUrl)
        }
    }
    
    func updateAfterExpand() {}
    
    func refreshTranscriptForPosition(_ position: Double = 0) {}
    
    func updateAfterSettingsChanged() {
        queueButtons.forEach({ $0.isHidden = !BHHybridPlayer.shared.shouldShowQueueButton() })
    }
    
    func updateSettingsControls() {
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }

        playbackSpeedButtons.forEach({ $0.setTitle(playerItem.playbackSettings.playbackSpeedString(), for: .normal) })
        playbackSpeedButtons.forEach({ $0.isAccessibilityElement = true })
        playbackSpeedButtons.forEach({ $0.accessibilityLabel = "Playback speed \(playerItem.playbackSettings.playbackSpeedString())" })

        let sleepTimerEnabled = BHHybridPlayer.shared.getSleepTimerInterval() > 0
        let sleepTimerStatus = sleepTimerEnabled ? "On" : "Off"
        sleepTimerButtons.forEach({ $0.isAccessibilityElement = true })
        sleepTimerButtons.forEach({ $0.accessibilityLabel = "Sleep timer \(sleepTimerStatus)" })
    }
    
    func onUserInterfaceRotated() {
        if UIDevice.current.orientation.isFlat { return }
        
        if isFullscreen {
            showOverlay(true)
            startOverlayTimer()
        } else {
            showOverlay(false)
            invalidateOverlayTimer()
        }
        
        updateFullscreenButton()
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onUserInterfaceStyleChangedNotification(notification: Notification) {
        guard let dict = notification.userInfo as? NSDictionary else { return }
        guard let value = dict["style"] as? Int else { return }
        
        let style = UIUserInterfaceStyle(rawValue: value) ?? .light

        overrideUserInterfaceStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc fileprivate func onDeviceOrientationChanged() {
        let deviceOrientation = UIDevice.current.orientation

        switch deviceOrientation {
        case .landscapeLeft:
            isFullscreen = true
            rotate(to: .landscapeLeft)

        case .landscapeRight:
            isFullscreen = true
            rotate(to: .landscapeRight)

        case .portrait:
            isFullscreen = false
            rotate(to: .portrait)

        default:
            break
        }
        
        BHHybridPlayer.shared.isFullScreen = isFullscreen
    }

    @objc internal func didTapRegularView(_ sender: UITapGestureRecognizer) {
        if isFullscreen {
            showOverlay(true)
            startOverlayTimer()
        }
    }
    
    @objc internal func didTapInteractiveView(_ sender: UITapGestureRecognizer) {
        showOverlay(true)
        startOverlayTimer()
    }
    
    @objc internal func didTapOverlayView(_ sender: UITapGestureRecognizer) {
        showOverlay(false)
        invalidateOverlayTimer()
    }
    
    // MARK: - Rotation helper

    private func rotate(to orientation: UIInterfaceOrientation) {

        if #available(iOS 16.0, *) {

            guard let scene = view.window?.windowScene else { return }

            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: UIInterfaceOrientationMask(rawValue: UInt(orientation.rawValue)))
            
            scene.requestGeometryUpdate(preferences)
            setNeedsUpdateOfSupportedInterfaceOrientations()

        } else {

            UIDevice.current.setValue(
                orientation.rawValue,
                forKey: "orientation"
            )

            UIViewController.attemptRotationToDeviceOrientation()
        }
        
        onUserInterfaceRotated()
        updateLayers()
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
        } else {
            BHHybridPlayer.shared.resume()            
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
    
    @IBAction func onPlaybackSpeedButton() {
        let optionsSheet = BHPlaybackSpeedBottomSheet()
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true
        optionsSheet.sheetTitle = NSLocalizedString("PLAYBACK SPEED", comment: "")
        present(optionsSheet, animated: true)
    }
    
    @IBAction func onSleepTimerButton() {
        let optionsSheet = BHSleepTimerBottomSheet()
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true
        optionsSheet.sheetTitle = NSLocalizedString("SLEEP TIMER", comment: "")
        present(optionsSheet, animated: true)
    }

    @IBAction func onOptionsButton() {
        let optionsVC = BHPlayerOptionsBottomSheet()
        optionsVC.preferredSheetSizing = .fit
        optionsVC.panToDismissEnabled = true
        optionsVC.type = type
        present(optionsVC, animated: true)
    }
    
    @IBAction func onQueueButton() {
        let queueVC = BHPlayerQueueBottomSheet()

        if let sheetPresentationController = queueVC.presentationController as? UISheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = false
        }

        present(queueVC, animated: true, completion: nil)
    }
    
    @IBAction func onFullScreenButton() {
        isFullscreen.toggle()

        BHHybridPlayer.shared.isFullScreen = isFullscreen
        
        let target: UIInterfaceOrientation = isFullscreen
            ? .landscapeRight
            : .portrait

        rotate(to: target)
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
        guard let post = BHHybridPlayer.shared.post else { return }

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
            playButtons.forEach({ $0.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal) })
            playButtons.forEach({ $0.accessibilityLabel = "Pause" })

        case .paused:
            controlsEnabled = true
            playButtons.forEach({ $0.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal) })
            playButtons.forEach({ $0.accessibilityLabel = "Play" })

        case .ended:
            controlsEnabled = true
            playButtons.forEach({ $0.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal) })

        case .failed:
            showRefresh = true
            playButtons.forEach({ $0.setBackgroundImage(UIImage(systemName: "arrow.clockwise"), for: .normal) })
            playButtons.forEach({ $0.accessibilityLabel = "Retry" })
        }

        if showIndicator {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            playButtons.forEach({ $0.isHidden = true })
            backwardButtons.forEach({ $0.isHidden = true })
            forwardButtons.forEach({ $0.isHidden = true })
            playbackSpeedButtons.forEach({ $0.isHidden = true })
            sleepTimerButtons.forEach({ $0.isHidden = true })
            routePickerViews.forEach({ $0.isHidden = true })
        } else if showRefresh {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            playButtons.forEach({ $0.isHidden = false })
            backwardButtons.forEach({ $0.isHidden = true })
            forwardButtons.forEach({ $0.isHidden = true })
            playbackSpeedButtons.forEach({ $0.isHidden = true })
            sleepTimerButtons.forEach({ $0.isHidden = true })
            playButtons.forEach({ $0.isEnabled = true })
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            playButtons.forEach({ $0.isHidden = false })
            backwardButtons.forEach({ $0.isHidden = false })
            forwardButtons.forEach({ $0.isHidden = false })
            playbackSpeedButtons.forEach({ $0.isHidden = false })
            sleepTimerButtons.forEach({ $0.isHidden = false })
            playButtons.forEach({ $0.isEnabled = true })
            backwardButtons.forEach({ $0.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive() })
            forwardButtons.forEach({ $0.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive() })
            playbackSpeedButtons.forEach({ $0.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive() })
            sleepTimerButtons.forEach({ $0.isEnabled = controlsEnabled && BHHybridPlayer.shared.isActive() })
            routePickerViews.forEach({ $0.isHidden = !controlsEnabled })
        }
                
        if playerItem.isStream || post.isLiveStream() || type == .waitingRoom {
            backwardButtons.forEach({ $0.isHidden = true })
            forwardButtons.forEach({ $0.isHidden = true })
            optionsButtons.forEach({ $0.isHidden = true })
            playbackSpeedButtons.forEach({ $0.isHidden = true })
            sleepTimerButtons.forEach({ $0.isHidden = true })
            sliders.forEach({ $0.isHidden = true })
            sliders.forEach({ $0.isEnabled = false })
            positionLabels.forEach({ $0.isHidden = true })
            durationLabels.forEach({ $0.isHidden = true })
            liveTagLabel.isHidden = false
            optionsButtons.forEach({ $0.isEnabled = controlsEnabled })
        } else {
            sliders.forEach({ $0.isHidden = false })
            positionLabels.forEach({ $0.isHidden = false })
            durationLabels.forEach({ $0.isHidden = false })
            liveTagLabel.isHidden = true
            sliders.forEach({ $0.isEnabled = controlsEnabled })
            queueButtons.forEach({ $0.isEnabled = controlsEnabled })
            optionsButtons.forEach({ $0.isEnabled = controlsEnabled })
        }
    }
    
    func onPositionChanged(_ position: Double, duration: Double) {
        if  duration > 0 && !self.isSliding {
            let pos = position.stringFormatted()
            let dur = (duration-position).stringFormatted()
            self.sliders.forEach({ $0.setValue(Float(position/duration), animated: true) })
            self.positionLabels.forEach({ $0.text = pos })
            self.durationLabels.forEach({ $0.text = "-\(dur)" })
            self.positionLabels.forEach({ $0.accessibilityLabel = "Position is \(pos)" })
            self.durationLabels.forEach({ $0.accessibilityLabel = "Remain \(dur)" })
        }
        refreshTranscriptForPosition(position)
//        nextButton.isEnabled = BHHybridPlayer.shared.hasNext()
//        previousButton.isEnabled = position > 30 || BHHybridPlayer.shared.hasPrevious()
    }
    
    func onTranscriptChanged() {}
    
    func resetUI() {
        playButtons.forEach({ $0.isEnabled = true })
        backwardButtons.forEach({ $0.isEnabled = false })
        forwardButtons.forEach({ $0.isEnabled = false })
        playbackSpeedButtons.forEach({ $0.isEnabled = false })
        sleepTimerButtons.forEach({ $0.isEnabled = false })
        routePickerViews.forEach({ $0.isHidden = true })
        sliders.forEach({ $0.isEnabled = false })
        hasVideo = false
        videoView.reset()
    }
    
    func resetProgressUI() {
        positionLabels.forEach({ $0.text = "00:00" })
        durationLabels.forEach({ $0.text = "00:00" })
        sliders.forEach({ $0.setValue(0, animated: true) })
    }

    func updateVideoLayer(_ isVideoAvailable: Bool) {
        self.videoView.configureVideoLayer()
        self.hasVideo = isVideoAvailable
    }
    
    func updateLayers() {
        if BHHybridPlayer.shared.isEnded() || BHHybridPlayer.shared.isFailed() {
            imageView.isHidden = false
        } else {
            imageView.isHidden = hasVideo || hasTile
        }
    }
    
    func updateLayout(_ useLayout: Bool, position: Double) {
        if post?.isLiveStream() == true {
            self.videoView.emptySpaces = BHEmptySpaces.initial()
        } else {
            if useLayout && !isFullscreen {
                let layoutEvent = BHHybridPlayer.shared.bulletinLayout?.getLayoutEvent(position)
                
                if let validEvent = layoutEvent {
                    self.videoView.emptySpaces = validEvent.getEmptySpaces(!isFullscreen)
                }
            } else {
                self.videoView.emptySpaces = BHEmptySpaces.initial()
            }
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
    
    internal func updateFullscreenButton() {
        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let config = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular, scale: .large)
        
        if isFullscreen {
            fullScreenButtons.forEach({ $0.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward.circle")?.withConfiguration(config), for: .normal) })
            fullScreenButtons.forEach({ $0.accessibilityLabel = "Disable full screen" })
        } else {
            fullScreenButtons.forEach({ $0.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward.circle")?.withConfiguration(config), for: .normal) })
            fullScreenButtons.forEach({ $0.accessibilityLabel = "Enable full screen" })
        }
    }
    
    // MARK: - Overlay
    
    internal func showOverlay(_ value: Bool = false) {
        overlayView.isHidden = !value
    }
    
    fileprivate func startOverlayTimer() {

        invalidateOverlayTimer()

        let timer = Timer.init(timeInterval: hideOverlayInterval, target: self, selector: #selector(overlayTimerHandler(_:)), userInfo: nil, repeats: true)
        timer.tolerance = hideOverlayInterval
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        overlayTimer = timer
    }
    
    fileprivate func invalidateOverlayTimer() {

        guard let timer = overlayTimer else { return }

        timer.invalidate()
        overlayTimer = nil
    }

    @objc fileprivate func overlayTimerHandler(_ timer: Timer) {

        guard timer.isValid else { return }

        overlayView.isHidden = true
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
            self.resetProgressUI()
            self.reloadData()
            self.updateAfterSettingsChanged()
        }
    }

    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {
        DispatchQueue.main.async {
            var message = "Failed to play episode. "

            if BHReachabilityManager.shared.isConnected() {
                if let validError = error {
                    message += " \(validError.localizedDescription)"
                }
            } else {
                message += "The Internet connection is lost."
            }
            self.showError(message)
            self.refreshTranscriptForPosition(-1)
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
                self.updateSettingsControls()
            }
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.hasTile = false
            self.hasVideo = false
            self.videoView.reset()
            self.refreshTranscriptForPosition(-1)
            self.resetUI()
        }
    }
    
    func hybridPlayerDidChangeTranscript(_ player: BHHybridPlayer, transcript: BHTranscript) {
        DispatchQueue.main.async {
            self.onTranscriptChanged()
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings) {
        DispatchQueue.main.async {
            self.updateAfterSettingsChanged()
            self.updateSettingsControls()
        }
    }    
}

// MARK: - BHLivePlayerListener

extension BHPlayerBaseViewController: BHLivePlayerListener {
        
    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.resetUI()
            self.resetProgressUI()
            self.reloadData()
            self.updateAfterSettingsChanged()
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
            var message = "Failed to play live episode. "

            if BHReachabilityManager.shared.isConnected() {
                if let validError = error {
                    message += " \(validError.localizedDescription)"
                }
            } else {
                message += "The Internet connection is lost."
            }
            self.showError(message)
        }
    }
}
