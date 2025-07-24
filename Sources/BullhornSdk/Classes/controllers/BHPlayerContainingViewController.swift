
import UIKit
import Foundation

class BHPlayerContainingViewController: UIViewController {

    @IBOutlet weak var miniPlayerView: BHMiniPlayerView!
    
    var modalVC: UIViewController?

    private var movin: Movin?

    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Movin.isDebugPrintEnabled = false
        miniPlayerView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        BHHybridPlayer.shared.addListener(self)
        BHLivePlayer.shared.addListener(self)

        updateMiniPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        miniPlayerView.hideActionView()
        hideTopMessageView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        BHHybridPlayer.shared.removeListener(self)
        BHLivePlayer.shared.removeListener(self)
    }
    
    // MARK: - Private
    
    private func isRecordingInteractive() -> Bool {
        guard let post = BHHybridPlayer.shared.post else {
            return false
        }
        return post.isInteractive()
    }
    
    private func isLiveInteractive() -> Bool {
        return BHLivePlayer.shared.post?.isLiveNow() ?? false
    }
    
    private func isRadioStream() -> Bool {
        guard let post = BHHybridPlayer.shared.post else {
            return false
        }
        return post.postType == .radioStream
    }

    private func setup() {
        
        var type: PlayerType = .recording
        let isInteractive = isRecordingInteractive() || isLiveInteractive()
        
        if isRecordingInteractive() {
            type = .interactive
        } else if isLiveInteractive() {
            let liveStatus = BHLivePlayer.shared.post?.liveStatus ?? .scheduled
            switch liveStatus {
            case .scheduled,
                 .preShow:
                type = .waitingRoom
            case .live,
                 .liveEnding,
                 .ended:
                type = .live
            }
        } else if isRadioStream() {
            type = .stream
        }

        movin = Movin(0.8, TimingCurve(curve: .easeInOut, dampingRatio: 1.0))
                
        let bundle = Bundle.module
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
        let identifier = isInteractive ? BHInteractivePlayerViewController.storyboardIndentifer : BHPlayerViewController.storyboardIndentifer
        let modal = storyboard.instantiateViewController(withIdentifier: identifier) as! BHPlayerBaseViewController
        modal.type = type
        modal.delegate = self
        modal.view.layoutIfNeeded()
        
        let startModalOrigin = CGPoint(x: 0, y: UIScreen.main.bounds.height) 
        let endModalOrigin = CGPoint(x: 0, y: 0)
        
        movin!.addAnimations([
//            containerView.mvn.cornerRadius.from(0.0).to(10.0),
//            containerView.mvn.alpha.from(1.0).to(0.6),
            modal.view.mvn.cornerRadius.from(0.0).to(10.0),
            modal.view.mvn.point.from(startModalOrigin).to(endModalOrigin),
            modal.closeButton.mvn.alpha.from(0.0).to(1.0),
            modal.routePickerView.mvn.alpha.from(0.0).to(1.0),
        ])
        
        let presentGesture = GestureAnimating(miniPlayerView, .top, view.frame.size)
        presentGesture.panCompletionThresholdRatio = 0.4
        let dismissGesture = GestureAnimating(modal.view, .bottom, modal.view.frame.size)
        dismissGesture.panCompletionThresholdRatio = 0.1
        dismissGesture.smoothness = 0.5
        
        let transition = movin!.configureTransition(self, modal, GestureTransitioning(.present, presentGesture, dismissGesture))
        transition.customContainerViewSetupHandler = { [unowned self] type, containerView in
            if type.isPresenting {
                containerView.addSubview(modal.view)
                modal.view.layoutIfNeeded()
                setNeedsStatusBarAppearanceUpdate()
                modal.beginAppearanceTransition(true, animated: false)
            } else {
                modal.beginAppearanceTransition(false, animated: false)
            }
        }
        transition.customContainerViewCompletionHandler = { [unowned self] type, didComplete, containerView in
            modal.endAppearanceTransition()
            
            if type.isDismissing {
                if didComplete {
                    modal.view.removeFromSuperview()
                    movin = nil
                    modalVC = nil
                    setNeedsStatusBarAppearanceUpdate()
                } else {
                }
            } else {
                if didComplete {
                } else {
                    modal.view.removeFromSuperview()
                    setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
        
        modalVC = modal
        modal.modalPresentationStyle = .overFullScreen
        modal.transitioningDelegate = movin!.configureCustomTransition(transition)
    }

    private func updateMiniPlayer() {
        if BHHybridPlayer.shared.playerItem == nil && BHLivePlayer.shared.playerItem == nil {
            miniPlayerView.isHidden = true
            return
        }
        miniPlayerView.isHidden = false
        miniPlayerView.update()
    }
    
    private func presentPlayer() {
        setup()
        
        guard let validModalVc = self.modalVC else { return }
        
        if !validModalVc.isBeingPresented {
            present(validModalVc, animated: true, completion: nil)
        }
    }
    
    private func dismissPlayer() {
        guard let validModalVc = self.modalVC else { return }
        
        validModalVc.dismiss(animated: true)
    }
    
    private func closePlayer() {
        BHHybridPlayer.shared.close()
        BHLivePlayer.shared.close()
    }
    
    // MARK: - Internal (to override)
    
    func openUserDetails(_ user: BHUser?) {}
    
    func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {}
    
    func onPlayerStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        updateMiniPlayer()
    }
    
    func onPlayerPositionChanged(_ position: Double, duration: Double) {}

    func onPlayerPlaybackCompleted() {}
}


// MARK: - BHMiniPlayerViewDelegate

extension BHPlayerContainingViewController: BHMiniPlayerViewDelegate {
    
    func miniPlayerViewRequestExpand(_ view: BHMiniPlayerView) {
        presentPlayer()
    }
    
    func miniPlayerViewRequestClose(_ view: BHMiniPlayerView) {
        closePlayer()
    }
}

// MARK: - BHHybridPlayerListener

extension BHPlayerContainingViewController: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.updateMiniPlayer()

            if self.isVisible() && player.post != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.movin == nil {
                        self.presentPlayer()
                    }
                }
            }
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
            self.onPlayerPlaybackCompleted()
        }
    }

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.onPlayerStateChanged(state, stateFlags: stateFlags)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async {
            self.onPlayerPositionChanged(position, duration: duration)
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.onPlayerPlaybackCompleted()
        }
    }
    
    func hybridPlayerDidClose(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.onPlayerPlaybackCompleted()
        }
    }
}

// MARK: - BHLivePlayerListener

extension BHPlayerContainingViewController : BHLivePlayerListener {

    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.updateMiniPlayer()
            if self.isVisible() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.movin == nil {
                        self.presentPlayer()
                    }
                }
            }
        }
    }
    
    func livePlayer(_ player: BHLivePlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}

    func livePlayerDidFinishPlaying(_ player: BHLivePlayer) {
        DispatchQueue.main.async { self.updateMiniPlayer() }
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

// MARK: - BHPlayerBaseViewControllerDelegate

extension BHPlayerContainingViewController: BHPlayerBaseViewControllerDelegate {
    
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenUser user: BHUser) {
        openUserDetails(user)
    }
    
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenPost post: BHPost) {
        openPostDetails(post)
    }
}
