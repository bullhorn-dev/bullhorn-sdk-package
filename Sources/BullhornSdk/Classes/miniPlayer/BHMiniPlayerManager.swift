
import UIKit
import Foundation

/// Single app-wide mini player.
///
/// Owns one `BHMiniPlayerView` installed directly into the app's main window,
/// above the root view controller's view. Because UIKit places presentation
/// containers (sheets, share dialog, SFSafariViewController, alerts, the full
/// player itself) on top of the window's existing subviews, any presented
/// content naturally covers the mini player — no show/hide bookkeeping is
/// needed for modals.

public final class BHMiniPlayerManager: NSObject {

    public static let shared = BHMiniPlayerManager()

    // MARK: - Public API (host app)

    /// Installs the mini player into the app's main window.
    /// - Parameters:
    ///   - window: the main application window.
    ///   - tabBar: the app's tab bar. The mini player docks right above it while
    ///     it is on screen, and falls back to the bottom safe area when the tab
    ///     bar is hidden (e.g. hidesBottomBarWhenPushed).
    public func attach(to window: UIWindow, tabBar: UITabBar?) {
        guard self.window == nil else { return }

        Movin.isDebugPrintEnabled = false
        self.window = window
        self.tabBar = tabBar

        installMiniPlayer()
        observeTabBar()

        miniPlayerView.overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle

        NotificationCenter.default.addObserver(self,
            selector: #selector(onUserInterfaceStyleChangedNotification(_:)),
            name: BullhornSdk.UserInterfaceStyleChangedNotification,
            object: nil)

        BHHybridPlayer.shared.addListener(self)

        // Returning from PiP lands on the full player.
        BHHybridPlayer.shared.pipRestoreUIHandler = { [weak self] completion in
            self?.presentPlayer()
            completion(true)
        }

        refresh()
    }

    public func updateBottomOffset(_ offset: CGFloat, animated: Bool = true) {
        applyBottomOffset(offset, animated: animated)
    }

    public func applyTheme() {
        miniPlayerView.applyTheme()
    }

    // MARK: - Internal API (package)

    weak var navigationRouter: BHPlayerBaseViewControllerDelegate?

    func containingScreenWillAppear() {
        containingScreensCount += 1
        updateVisibility()
    }

    func containingScreenDidDisappear() {
        containingScreensCount = max(0, containingScreensCount - 1)
        updateVisibility()
    }

    func presentPlayer() {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        guard modalVC == nil else { return }

        setupTransition()

        guard let modal = modalVC else { return }
        if !modal.isBeingPresented {
            topMostViewController()?.present(modal, animated: true, completion: nil)
        }
    }

    func dismissPlayer() {
        modalVC?.dismiss(animated: true)
    }

    // MARK: - Private

    private weak var window: UIWindow?
    private weak var tabBar: UITabBar?
    private var tabBarObservations = [NSKeyValueObservation]()

    private let miniPlayerView = BHMiniPlayerView()
    private var bottomConstraint: NSLayoutConstraint?

    private var containingScreensCount = 0

    private var movin: Movin?
    private var modalVC: UIViewController?

    private override init() {
        super.init()
    }

    private func topMostViewController() -> UIViewController? {
        guard var top = window?.rootViewController else { return nil }
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }

    @objc private func onUserInterfaceStyleChangedNotification(_ notification: Notification) {
        guard let dict = notification.userInfo as? NSDictionary,
              let value = dict["style"] as? Int else { return }

        let style = UIUserInterfaceStyle(rawValue: value) ?? .unspecified
        miniPlayerView.overrideUserInterfaceStyle = style
    }

    private func installMiniPlayer() {
        guard let window else { return }

        miniPlayerView.isHidden = true
        miniPlayerView.delegate = self
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(miniPlayerView)

        let bottom = miniPlayerView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        bottomConstraint = bottom

        NSLayoutConstraint.activate([
            miniPlayerView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: Constants.playerHeight),
            bottom
        ])

        syncBottomOffset(animated: false)
    }

    // MARK: - Visibility

    private func shouldShowMiniPlayer() -> Bool {
        return BHHybridPlayer.shared.playerItem != nil
            && containingScreensCount > 0
    }

    private func updateVisibility() {
        miniPlayerView.isHidden = !shouldShowMiniPlayer()
    }

    // MARK: - Bottom offset tracking

    private func observeTabBar() {
        guard let tabBar else { return }

        let sync: () -> Void = { [weak self] in
            DispatchQueue.main.async { self?.syncBottomOffset(animated: true) }
        }
        tabBarObservations = [
            tabBar.observe(\.isHidden) { _, _ in sync() },
            tabBar.observe(\.frame)    { _, _ in sync() },
            tabBar.observe(\.center)   { _, _ in sync() },
            tabBar.observe(\.bounds)   { _, _ in sync() }
        ]
    }

    private func currentBottomOffset() -> CGFloat {
        let safeBottom = window?.safeAreaInsets.bottom ?? 0

        guard let tabBar,
              let tabBarWindow = tabBar.window,
              !tabBar.isHidden else { return safeBottom }

        let frameInWindow = tabBar.convert(tabBar.bounds, to: nil)
        let isOnScreen = frameInWindow.intersects(tabBarWindow.bounds)

        guard isOnScreen else { return safeBottom }

        return max(safeBottom, tabBarWindow.bounds.maxY - frameInWindow.minY)
    }

    private func syncBottomOffset(animated: Bool) {
        applyBottomOffset(currentBottomOffset(), animated: animated)
    }

    private func applyBottomOffset(_ offset: CGFloat, animated: Bool) {
        guard let window else { return }
        guard bottomConstraint?.constant != -offset else { return }

        bottomConstraint?.constant = -offset

        if animated {
            UIView.animate(withDuration: 0.25) { window.layoutIfNeeded() }
        } else {
            window.layoutIfNeeded()
        }
    }

    // MARK: - State

    private func isVideoMode() -> Bool {
        return (BHHybridPlayer.shared.mediaPlayer?.hasVideo() ?? false)
            && UserDefaults.standard.isPictureInPictureFeatureEnabled
    }

    private func refresh() {
        updateVisibility()

        guard BHHybridPlayer.shared.playerItem != nil else {
            miniPlayerView.detachVideoLayer()
            return
        }

        miniPlayerView.setVideoMode(isVideoMode())
        miniPlayerView.update()
        updateVideoAttachment()
        syncBottomOffset(animated: false)
    }

    private func updateVideoAttachment() {
        guard isVideoMode() else {
            miniPlayerView.detachVideoLayer()
            return
        }
        // While the full player is up it owns the layer — hands off.
        guard modalVC == nil else { return }

        if let layerView = BHHybridPlayer.shared.getVideoLayer() {
            miniPlayerView.attachVideoLayer(layerView)
        }
    }

    // MARK: - Full player presentation

    private func isRecordingInteractive() -> Bool {
        guard let post = BHHybridPlayer.shared.post else { return false }
        return post.hasTiles() || post.hasVideo()
    }

    private func isLiveInteractive() -> Bool {
        return BHHybridPlayer.shared.post?.isLiveNow() ?? false
    }

    private func isRadioStream() -> Bool {
        guard let post = BHHybridPlayer.shared.post else { return false }
        return post.postType == .radioStream
    }

    private func setupTransition() {
        guard let presenting = topMostViewController() else { return }

        var type: PlayerType = .recording
        let isInteractive = isRecordingInteractive() || isLiveInteractive()

        if isRecordingInteractive() {
            type = .interactive
        } else if isLiveInteractive() {
            let liveStatus = BHHybridPlayer.shared.post?.liveStatus ?? .scheduled
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
        modal.view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

        let startModalOrigin = CGPoint(x: 0, y: UIScreen.main.bounds.height)
        let endModalOrigin = CGPoint(x: 0, y: 0)

        movin!.addAnimations([
            modal.view.mvn.cornerRadius.from(0.0).to(10.0),
            modal.view.mvn.point.from(startModalOrigin).to(endModalOrigin),
        ])

        let presentGesture = GestureAnimating(miniPlayerView, .top, presenting.view.frame.size)
        presentGesture.panCompletionThresholdRatio = 0.4
        let dismissGesture = GestureAnimating(modal.view, .bottom, modal.view.frame.size)
        dismissGesture.panCompletionThresholdRatio = 0.1
        dismissGesture.smoothness = 0.5

        let transition = movin!.configureTransition(presenting, modal, GestureTransitioning(.present, presentGesture, dismissGesture))
        transition.customContainerViewSetupHandler = { type, containerView in
            if type.isPresenting {
                containerView.addSubview(modal.view)
                modal.view.layoutIfNeeded()
                presenting.setNeedsStatusBarAppearanceUpdate()
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
                    presenting.setNeedsStatusBarAppearanceUpdate()
                    // The full player owned the video layer — take it back.
                    refresh()
                }
            } else {
                if didComplete {
                } else {
                    modal.view.removeFromSuperview()
                    presenting.setNeedsStatusBarAppearanceUpdate()
                    refresh()
                }
            }
        }

        modalVC = modal
        modal.modalPresentationStyle = .overFullScreen
        modal.transitioningDelegate = movin!.configureCustomTransition(transition)
    }
}

// MARK: - BHMiniPlayerViewDelegate

extension BHMiniPlayerManager: BHMiniPlayerViewDelegate {

    func miniPlayerViewRequestExpand(_ view: BHMiniPlayerView) {
        presentPlayer()
    }

    func miniPlayerViewRequestClose(_ view: BHMiniPlayerView) {
        BHHybridPlayer.shared.close()
    }
}

// MARK: - BHHybridPlayerListener

extension BHMiniPlayerManager: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            // New episode: drop the previous episode's video surface immediately
            // and fall back to the audio look until the new engine reports video.
            self.miniPlayerView.detachVideoLayer()
            self.miniPlayerView.setVideoMode(false)
            self.refresh()

            if player.post != nil && player.shouldPlayAutomatically {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.movin == nil {
                        self.presentPlayer()
                    }
                }
            }
        }
    }

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.refresh()
        }
    }

    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.refresh()
        }
    }

    func hybridPlayerDidClose(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.miniPlayerView.detachVideoLayer()
            self.updateVisibility()
        }
    }
}

// MARK: - BHPlayerBaseViewControllerDelegate

extension BHMiniPlayerManager: BHPlayerBaseViewControllerDelegate {

    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenUser user: BHUser) {
        dismissPlayer()
        navigationRouter?.playerViewController(vc, didRequestOpenUser: user)
    }

    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenPost post: BHPost) {
        dismissPlayer()
        navigationRouter?.playerViewController(vc, didRequestOpenPost: post)
    }
}

