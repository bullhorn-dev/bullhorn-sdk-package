import UIKit
import Foundation

class BHDownloadButton: UIView {
    
    var post: BHPost? {
        didSet {
            status = post?.downloadStatus ?? .start
            reason = post?.downloadReason ?? .manually
            updateButtonState()
        }
    }

    private var status: DownloadStatus = .start
    private var reason: DownloadReason = .manually
    
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .primary()
        return button
    }()
    
    private let progressView: BHCircularProgressView = {
        let progress = BHCircularProgressView(frame: .zero)
        progress.trackColor = .tertiary()
        progress.circleColor = .primary()
        return progress
    }()

    deinit {
//        BHDownloadsManager.shared.removeListener(self)
    }

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
        button.layer.cornerRadius = frame.size.height / 2
        updateButtonState()
    }
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        
        backgroundColor = .clear

        updateButtonState()
        
        button.addTarget(self, action: #selector(onPress(_:)), for: .touchUpInside)
        
        addSubview(button)
        addSubview(progressView)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: frame.size.width),
            button.heightAnchor.constraint(equalToConstant: frame.size.height),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: frame.size.width),
            progressView.heightAnchor.constraint(equalToConstant: frame.size.height),
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        BHDownloadsManager.shared.addListener(self)
    }
    
    fileprivate func updateButtonState() {
        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let mediumConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .medium)
        let smallConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .small)
        var image: UIImage? = nil
        var bgColor: UIColor = reason == .auto ? .fxPrimaryBackground() : .clear
        var hasProgress: Bool = false
            
        switch status {
        case .pending:
            image = UIImage(systemName: "arrow.down.to.line")?.withConfiguration(mediumConfig)
            bgColor = .defaultYellow()
        case .start:
            image = UIImage(systemName: "arrow.down.to.line")?.withConfiguration(mediumConfig)
        case .progress:
            image = UIImage(systemName: "stop")?.withConfiguration(smallConfig)
            hasProgress = true
        case .success:
            image = UIImage(systemName: "checkmark")?.withConfiguration(mediumConfig)
        case .failure:
            image = UIImage(systemName: "arrow.clockwise")?.withConfiguration(smallConfig)
            bgColor = .accent().withAlphaComponent(0.3)
        }

        button.setImage(image, for: .normal)
        button.backgroundColor = bgColor
            
        if hasProgress {
            progressView.setProgress(0, animated: false)
            progressView.isHidden = false
        } else {
            progressView.setProgress(0, animated: false)
            progressView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func onPress(_ sender: Any) {
        guard let validPost = post else { return }
        
        if !BHReachabilityManager.shared.isConnected() {
            UIApplication.topViewController()?.showError("Failed to download episode. The Internet connection is lost.")
        }
        
        switch status {
        case .start:
            BHDownloadsManager.shared.download(validPost, reason: .manually)
        case .pending,
             .progress,
             .success:
            break
        case .failure:
            BHDownloadsManager.shared.download(validPost, reason: .manually)
            break
        }

        layoutSubviews()
    }
}

// MARK: - BHDownloadsManagerListener

extension BHDownloadButton: BHDownloadsManagerListener {
    
    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool) {
        DispatchQueue.main.async {
            self.status = .start
            self.layoutSubviews()
        }
    }

    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem) {
        guard let validPost = post else { return }
        if item.post.id != validPost.id { return }

        DispatchQueue.main.async {
            self.status = item.status
            self.updateButtonState()
        }
    }

    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem) {
        guard let validPost = post else { return }
        if item.post.id != validPost.id { return }
        
        DispatchQueue.main.async {
            if self.status != item.status {
                self.status = item.status
                self.updateButtonState()
            }
            self.progressView.setProgress(Float(item.progress), animated: true)
        }
    }
    
    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager) {}
}
