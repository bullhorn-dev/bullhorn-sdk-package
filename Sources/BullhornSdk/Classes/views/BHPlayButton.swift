import UIKit
import Foundation

class BHPlayButton: UIView {
    
    var post: BHPost? {
        didSet {
            updateButtonState()
        }
    }
    
    var playlist: [BHPost]?
    
    var title: String? {
        didSet {
            updateButtonState()
        }
    }
    
    var context: String = "Episode"
    
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .primaryButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .accent()
        button.tintColor = .onAccent()
        return button
    }()
    
    private let loadIndicator: BHActivityIndicatorView = {
        let indicator = BHActivityIndicatorView(frame: .zero)
        indicator.type = .ballPulse
        indicator.color = .onAccent()
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
        button.layer.cornerRadius = button.frame.size.height / 2
    }
    
    var isEnabled: Bool {
        set {
            button.isEnabled = newValue
        }
        get {
            button.isEnabled
        }
    }
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        
        backgroundColor = .accent()

        updateButtonState()
        
        button.addTarget(self, action: #selector(onPress(_:)), for: .touchUpInside)
        
        addSubview(button)
        addSubview(loadIndicator)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: frame.size.width),
            button.heightAnchor.constraint(equalToConstant: frame.size.height),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadIndicator.widthAnchor.constraint(equalToConstant: 2 * frame.size.width / 3),
            loadIndicator.heightAnchor.constraint(equalToConstant: 2 * frame.size.height / 3),
            loadIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        BHHybridPlayer.shared.addListener(self)
    }
    
    fileprivate func updateButtonState() {
        let config = UIImage.SymbolConfiguration(scale: .large)
        
        /// accessability
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        button.isAccessibilityElement = false
        loadIndicator.isAccessibilityElement = false

        if BHHybridPlayer.shared.isPostPlaying(post?.id ?? "") {
            button.setImage(UIImage(systemName: "pause.fill")?.withConfiguration(config), for: .normal)
            button.setTitle("", for: .normal)
            accessibilityLabel = "Pause \(context)"
        } else {
            if let title = title {
                button.setTitle(title, for: .normal)
                button.setImage(nil, for: .normal)
            } else {
                button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
                button.setTitle("", for: .normal)
            }
            accessibilityLabel = "Play \(context) \(post?.title ?? "")"
        }
    }
    
    fileprivate func resetState() {
        let config = UIImage.SymbolConfiguration(scale: .medium)
        self.loadIndicator.stopAnimating()
        self.loadIndicator.isHidden = true
        self.button.isHidden = false
        if let title = self.title {
            self.button.setTitle(title, for: .normal)
            self.button.setImage(nil, for: .normal)
        } else {
            self.button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
            self.button.setTitle("", for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func onPress(_ sender: Any) {
        guard let validPost = post else { return }

        if !BHHybridPlayer.shared.isPostActive(validPost.id) {
            let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(validPost.id)
            
            if BHReachabilityManager.shared.isConnected() || fileUrl != nil {
                loadIndicator.startAnimating()
                loadIndicator.isHidden = false
                button.isHidden = true
            }
        }

        BHHybridPlayer.shared.playRequest(with: validPost, playlist: playlist)
    }
}

extension BHPlayButton: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        guard let p = post, let playerPost = player.post else {
            DispatchQueue.main.async { self.resetState() }
            return
        }

        if p.id != playerPost.id {
            DispatchQueue.main.async {
                self.resetState()
            }
        } else {
            DispatchQueue.main.async {
                let config = UIImage.SymbolConfiguration(scale: .medium)
                
                switch state {
                case .idle,
                     .initializing:
                    self.loadIndicator.startAnimating()
                    self.loadIndicator.isHidden = false
                    self.button.isHidden = true
                case .playing:
                    self.loadIndicator.isHidden = stateFlags != .buffering
                    self.button.isHidden = stateFlags == .buffering
                    self.button.setImage(UIImage(systemName: "pause.fill")?.withConfiguration(config), for: .normal)
                    self.button.setTitle("", for: .normal)
                    self.accessibilityLabel = "Pause \(self.context)"
                case .paused:
                    self.loadIndicator.stopAnimating()
                    self.loadIndicator.isHidden = true
                    self.button.isHidden = false
                    if let title = self.title {
                        self.button.setTitle(title, for: .normal)
                        self.button.setImage(nil, for: .normal)
                    } else {
                        self.button.setImage(UIImage(systemName: "play.fill")?.withConfiguration(config), for: .normal)
                        self.button.setTitle("", for: .normal)
                    }
                    self.accessibilityLabel = "Play \(self.context)"
                case .ended,
                     .failed:
                    self.resetState()
                }
            }
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async { self.resetState() }
    }
    
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {
        DispatchQueue.main.async { self.resetState() }
    }
}
