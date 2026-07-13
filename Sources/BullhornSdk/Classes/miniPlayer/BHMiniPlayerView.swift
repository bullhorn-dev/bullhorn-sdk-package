import UIKit
import Foundation

protocol BHMiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewRequestExpand(_ view: BHMiniPlayerView)
    func miniPlayerViewRequestClose(_ view: BHMiniPlayerView)
}

// MARK: - Video container

/// Hosts the shared BHPlayerLayerView inside the mini player.
/// Frame-based on purpose: the layer view is reparented between the full
/// player, the mini player and PiP, so constraints would be fragile.
final class BHMiniPlayerVideoContainer: UIView {

    private(set) weak var videoLayerView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func attach(_ view: UIView) {
        if view.superview === self, videoLayerView === view { return }
        // Drop any stale surface left from a previous episode.
        subviews.forEach { $0.removeFromSuperview() }
        videoLayerView = view
        addSubview(view)
        setNeedsLayout()
    }

    func detach() {
        // Removes only our own subviews; if the full player has already stolen
        // the layer view, it is no longer among them.
        subviews.forEach { $0.removeFromSuperview() }
        videoLayerView = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoLayerView?.frame = bounds
    }
}

// MARK: - Mini player

class BHMiniPlayerView: UIView {

    let btnSize: CGFloat = 32
    let actionWidth: CGFloat = 70

    weak var delegate: BHMiniPlayerViewDelegate?

    private var labelAfterImageConstraint: NSLayoutConstraint?
    private var labelAfterVideoConstraint: NSLayoutConstraint?

    var isSpacer: Bool = false {
        didSet {
            scrollView.isHidden = isSpacer
            applyTheme()
        }
    }

    private(set) var isVideoMode = false

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.scrollsToTop = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryBackground()
        return view
    }()

    private let actionView: UIView = {
        let view = UIView()
        view.backgroundColor = .accent()
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let videoContainer: BHMiniPlayerVideoContainer = {
        let view = BHMiniPlayerVideoContainer(frame: .zero)
        view.isHidden = true
        return view
    }()

    private let userLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .secondaryButton()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        return label
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .onAccent()
        return button
    }()

    private let loadIndicator: BHActivityIndicatorView = {
        let indicator = BHActivityIndicatorView(frame: .zero)
        indicator.type = .circleStrokeSpin
        indicator.color = .accent()
        return indicator
    }()

    private let blurredEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .prominent)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.contentMode = .scaleToFill
        return blurredEffectView
    }()

    private let expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.contentSize = CGSize(width: frame.size.width + actionWidth, height: Constants.playerHeight)
    }

    // MARK: - Public

    func hideActionView() {
        scrollView.setContentOffset(.zero, animated: true)
    }

    func applyTheme() {
        backgroundColor = isSpacer ? .clear : .cardBackground()
        contentView.backgroundColor = .primaryBackground()
        actionView.backgroundColor = .accent()

        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.backgroundColor = .tertiary()

        userLabel.textColor = .primary()
        playButton.tintColor = .primary()
        closeButton.tintColor = .onAccent()
        loadIndicator.color = .accent()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Covers the system light/dark switch and manual theme overrides
        // applied via overrideUserInterfaceStyle on the window.
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    func setVideoMode(_ enabled: Bool) {
        guard isVideoMode != enabled else { return }
        isVideoMode = enabled

        videoContainer.isHidden = !enabled
        imageView.isHidden = enabled

        // The title trails whichever cover is visible in the current mode.
        labelAfterVideoConstraint?.isActive = false
        labelAfterImageConstraint?.isActive = false
        (enabled ? labelAfterVideoConstraint : labelAfterImageConstraint)?.isActive = true

        if !enabled {
            videoContainer.detach()
        }
    }

    func attachVideoLayer(_ view: UIView) {
        guard isVideoMode else { return }
        videoContainer.attach(view)
    }

    func detachVideoLayer() {
        videoContainer.detach()
    }

    func update() {
        guard !isSpacer else { return }

        let state = BHHybridPlayer.shared.state
        let flags = BHHybridPlayer.shared.stateFlags

        updateControls(with: state, stateFlags: flags)
    }

    // MARK: - Private

    fileprivate func setupUI() {

        backgroundColor = .cardBackground()

        closeButton.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.accessibilityLabel = "Close player"

        playButton.accessibilityLabel = "Play"
        expandButton.accessibilityLabel = "Expand full screen player"

        expandButton.addTarget(self, action: #selector(onExpandButton(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(onPlayButton(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(onCloseButton(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [playButton, loadIndicator])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10

        blurredEffectView.contentView.addSubview(expandButton)
        contentView.addSubview(blurredEffectView)
        contentView.addSubview(imageView)
        contentView.addSubview(videoContainer)
        contentView.addSubview(userLabel)
        contentView.addSubview(stackView)
        
        actionView.addSubview(closeButton)
        
        scrollView.addSubview(contentView)
        scrollView.addSubview(actionView)
        
        addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        actionView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
                
        // 16:9 video surface fitted into the bar height.
        let videoHeight = Constants.playerHeight - 12
        let videoWidth = videoHeight * 16.0 / 9.0

        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: Constants.playerHeight),

            actionView.widthAnchor.constraint(equalToConstant: actionWidth),
            actionView.heightAnchor.constraint(equalToConstant: Constants.playerHeight),
            actionView.leftAnchor.constraint(equalTo: contentView.rightAnchor),

            imageView.heightAnchor.constraint(equalToConstant: 44),
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Constants.paddingHorizontal),

            videoContainer.heightAnchor.constraint(equalToConstant: videoHeight),
            videoContainer.widthAnchor.constraint(equalToConstant: videoWidth),
            videoContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoContainer.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Constants.paddingHorizontal),

            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: btnSize),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -Constants.paddingHorizontal),

            userLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userLabel.rightAnchor.constraint(equalTo: stackView.leftAnchor, constant: -Constants.paddingHorizontal / 2),

            playButton.heightAnchor.constraint(equalToConstant: btnSize),
            playButton.widthAnchor.constraint(equalToConstant: 4 * btnSize / 5),

            loadIndicator.heightAnchor.constraint(equalToConstant: btnSize),
            loadIndicator.widthAnchor.constraint(equalToConstant: btnSize),

            closeButton.heightAnchor.constraint(equalToConstant: btnSize),
            closeButton.widthAnchor.constraint(equalToConstant: btnSize),
            closeButton.centerXAnchor.constraint(equalTo: actionView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: actionView.centerYAnchor),

            blurredEffectView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            blurredEffectView.heightAnchor.constraint(equalToConstant: Constants.playerHeight),
            blurredEffectView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            blurredEffectView.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            expandButton.centerYAnchor.constraint(equalTo: blurredEffectView.centerYAnchor),
            expandButton.heightAnchor.constraint(equalToConstant: Constants.playerHeight),
            expandButton.leftAnchor.constraint(equalTo: blurredEffectView.leftAnchor),
            expandButton.rightAnchor.constraint(equalTo: blurredEffectView.rightAnchor)
        ])

        // The title's leading edge depends on the mode: after the 44pt cover in
        // audio mode, after the 16:9 video surface in video mode.
        labelAfterImageConstraint = userLabel.leftAnchor.constraint(
            equalTo: imageView.rightAnchor, constant: Constants.paddingHorizontal / 2)
        labelAfterVideoConstraint = userLabel.leftAnchor.constraint(
            equalTo: videoContainer.rightAnchor, constant: Constants.paddingHorizontal / 2)
        labelAfterImageConstraint?.isActive = true

        applyTheme()

        BHHybridPlayer.shared.addListener(self)
    }
    
    private func updateControls(with state: PlayerState, stateFlags: PlayerStateFlags) {
        guard !isSpacer else { return }
        guard let playerItem = getPlayerItem() else { return }

        var controlsEnabled = false
        var showIndicator = false
        var showRefresh = false

        self.userLabel.text = playerItem.post.title

        self.imageView.sd_setImage(with: playerItem.post.coverUrl)
        self.imageView.layoutSubviews()

        switch state {
        case .idle, .initializing:
            showIndicator = true

        case .playing:
            controlsEnabled = true
            showIndicator = stateFlags == .buffering
            playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            playButton.accessibilityLabel = "Pause"
        case .paused:
            controlsEnabled = true
            playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            playButton.accessibilityLabel = "Play"
        case .ended:
            controlsEnabled = true
            playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        case .failed:
            showRefresh = true
            playButton.setBackgroundImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
            playButton.accessibilityLabel = "Retry"
        }
        
        if showIndicator {
            self.loadIndicator.startAnimating()
            self.loadIndicator.isHidden = false
            self.playButton.isHidden = true
        } else if showRefresh {
            self.loadIndicator.stopAnimating()
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = false
        } else {
            self.loadIndicator.stopAnimating()
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = false
            self.playButton.isEnabled = controlsEnabled
        }
        
        if isLiveNow() {
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = true
        }
    }

    private func resetControls() {
        playButton.isEnabled = false
        loadIndicator.stopAnimating()
        loadIndicator.isHidden = true
        userLabel.text = ""
    }
    
    private func getPlayerItem() -> BHPlayerItem? {
        return BHHybridPlayer.shared.playerItem
    }

    private func isLiveNow() -> Bool {
        return BHHybridPlayer.shared.post?.isLiveNow() ?? false
    }
    
    private func isLiveStream() -> Bool {
        return BHHybridPlayer.shared.post?.isLiveStream() ?? false
    }

    // MARK: - Actions
    
    @objc private func onExpandButton(_ sender: Any) {
        delegate?.miniPlayerViewRequestExpand(self)
    }

    @objc private func onCloseButton(_ sender: Any) {
        hideActionView()
        delegate?.miniPlayerViewRequestClose(self)
    }

    @objc private func onPlayButton(_ sender: Any) {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isPlaying() {
            BHHybridPlayer.shared.pause()
        } else {
            BHHybridPlayer.shared.resume()
        }
    }
}

// MARK: BHHybridPlayerListener

extension BHMiniPlayerView: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            guard !self.isSpacer else { return }
            self.resetControls()
            self.updateControls(with: .idle, stateFlags: .initial)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            guard !self.isSpacer else { return }
            self.updateControls(with: state, stateFlags: stateFlags)
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            guard !self.isSpacer else { return }
            self.resetControls()
            self.updateControls(with: .ended, stateFlags: .complete)
        }
    }
}

