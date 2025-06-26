import UIKit
import Foundation

protocol BHMiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewRequestExpand(_ view: BHMiniPlayerView)
    func miniPlayerViewRequestClose(_ view: BHMiniPlayerView)
}

class BHMiniPlayerView: UIView {
    
    let btnSize: CGFloat = 32
    let actionWidth: CGFloat = 70
    
    weak var delegate: BHMiniPlayerViewDelegate?
    
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

    private let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        return button
    }()

    private let backwardButton: UIButton = {
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
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        
        backgroundColor = .cardBackground()
        
        backwardButton.setBackgroundImage(UIImage(systemName: "gobackward.15"), for: .normal)
        forwardButton.setBackgroundImage(UIImage(systemName: "goforward.15"), for: .normal)
        closeButton.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)

        expandButton.addTarget(self, action: #selector(onExpandButton(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(onPlayButton(_:)), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(onBackwardButton(_:)), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(onForwardButton(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(onCloseButton(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [backwardButton, playButton, forwardButton, loadIndicator])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 6

        blurredEffectView.contentView.addSubview(expandButton)
        contentView.addSubview(blurredEffectView)
        contentView.addSubview(imageView)
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
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
                
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

            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: btnSize),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -Constants.paddingHorizontal),

            userLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: Constants.paddingHorizontal / 2),
            userLabel.rightAnchor.constraint(equalTo: stackView.leftAnchor, constant: -Constants.paddingHorizontal / 2),

            backwardButton.heightAnchor.constraint(equalToConstant: btnSize),
            backwardButton.widthAnchor.constraint(equalToConstant: btnSize),

            playButton.heightAnchor.constraint(equalToConstant: btnSize),
            playButton.widthAnchor.constraint(equalToConstant: 4 * btnSize / 5),

            forwardButton.heightAnchor.constraint(equalToConstant: btnSize),
            forwardButton.widthAnchor.constraint(equalToConstant: btnSize),

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

        BHHybridPlayer.shared.addListener(self)
        BHLivePlayer.shared.addListener(self)
    }
    
    private func updateControls(with state: PlayerState, stateFlags: PlayerStateFlags) {
        guard let playerItem = getPlayerItem() else { return }

        var controlsEnabled = false
        var showIndicator = false
        var showRefresh = false

        self.userLabel.text = playerItem.post.title

        self.imageView.sd_setImage(with: playerItem.post.userImageUrl)
        self.imageView.layoutSubviews()

        switch state {
        case .idle, .initializing:
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
            self.loadIndicator.startAnimating()
            self.loadIndicator.isHidden = false
            self.playButton.isHidden = true
            self.backwardButton.isHidden = true
            self.forwardButton.isHidden = true
        } else if showRefresh {
            self.loadIndicator.stopAnimating()
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = false
            self.backwardButton.isHidden = true
            self.forwardButton.isHidden = true
        } else {
            self.loadIndicator.stopAnimating()
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = false
            self.backwardButton.isHidden = false
            self.forwardButton.isHidden = false
            self.playButton.isEnabled = controlsEnabled
            self.backwardButton.isEnabled = controlsEnabled
            self.forwardButton.isEnabled = controlsEnabled
        }
        
        if isLiveNow() {
            self.loadIndicator.isHidden = true
            self.playButton.isHidden = true
            self.backwardButton.isHidden = true
            self.forwardButton.isHidden = true
        }
        
        if playerItem.isStream || isLiveStream() {
            self.backwardButton.isHidden = true
            self.forwardButton.isHidden = true
        }
    }

    private func resetControls() {
        playButton.isEnabled = false
        backwardButton.isEnabled = false
        forwardButton.isEnabled = false
        loadIndicator.stopAnimating()
        loadIndicator.isHidden = true
        userLabel.text = ""
    }
    
    private func getPlayerItem() -> BHPlayerItem? {
        if let playerItem = BHLivePlayer.shared.playerItem {
            return playerItem
        } else if let playerItem = BHHybridPlayer.shared.playerItem {
            return playerItem
        }
        return nil
    }

    private func isLiveNow() -> Bool {
        return BHLivePlayer.shared.post?.isLiveNow() ?? false
    }
    
    private func isLiveStream() -> Bool {
        return BHLivePlayer.shared.post?.isLiveStream() ?? false
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
    
    @objc private func onForwardButton(_ sender: Any) {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.seekForward()
        }
    }
    
    @objc private func onBackwardButton(_ sender: Any) {
        guard BHHybridPlayer.shared.playerItem != nil else { return }
        
        if BHHybridPlayer.shared.isActive() {
            BHHybridPlayer.shared.seekBackward()
        }
    }
    
    // MARK: - Public
    
    func update() {
        let state = BHHybridPlayer.shared.state
        let flags = BHHybridPlayer.shared.stateFlags
        
        updateControls(with: state, stateFlags: flags)
    }
}

// MARK: BHHybridPlayerListener

extension BHMiniPlayerView: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.resetControls()
            self.updateControls(with: .idle, stateFlags: .initial)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.updateControls(with: state, stateFlags: stateFlags)
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.resetControls()
            self.updateControls(with: .ended, stateFlags: .complete)
        }
    }
}

// MARK: - BHLivePlayerListener

extension BHMiniPlayerView: BHLivePlayerListener {
    
    func livePlayer(_ player: BHLivePlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.resetControls()
            self.updateControls(with: .idle, stateFlags: .initial)
        }
    }
    
    func livePlayer(_ player: BHLivePlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func livePlayerDidFinishPlaying(_ player: BHLivePlayer) {
        DispatchQueue.main.async {
            self.resetControls()
        }
    }
}
