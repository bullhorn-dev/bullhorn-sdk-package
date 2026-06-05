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
    
    var context: String = "Episode"

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

    private let activityIndicator: BHActivityIndicatorView = {
        let indicator = BHActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: .tertiary())
        return indicator
    }()

    deinit {
        // Intentionally NOT removing the listener here.
        //
        // This button lives in a reused UITableViewCell (BHPostCell) and is
        // deallocated frequently. removeListener(self) dispatches async and
        // captures the listener strongly — i.e. it retains an object whose deinit
        // is already running, which crashed on cell reuse (use-after-free).
        //
        // The observers container is expected to hold listeners weakly, so a dead
        // button drops out on its own and no explicit removal is needed. If that
        // ever stops being true, remove from a point where the button is still
        // alive (e.g. the cell's prepareForReuse), or via a non-retaining
        // identifier (ObjectIdentifier) rather than the object itself.
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
        addSubview(activityIndicator)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: frame.size.width),
            button.heightAnchor.constraint(equalToConstant: frame.size.height),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: frame.size.width - 4),
            progressView.heightAnchor.constraint(equalToConstant: frame.size.height - 4),
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: frame.size.width - 4),
            activityIndicator.heightAnchor.constraint(equalToConstant: frame.size.height - 4),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
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
        var hasSpinner: Bool = false
            
        switch status {
        case .pending:
            image = UIImage(systemName: "stop")?.withConfiguration(smallConfig)
            bgColor = .clear
            hasSpinner = true
            accessibilityLabel = "Waiting to download \(context)"
        case .start:
            image = UIImage(systemName: "arrow.down.to.line")?.withConfiguration(mediumConfig)
            accessibilityLabel = "Download \(context)"
        case .progress:
            image = UIImage(systemName: "stop")?.withConfiguration(smallConfig)
            accessibilityLabel = "Downloading \(context)"
            hasProgress = true
        case .success:
            image = UIImage(systemName: "checkmark")?.withConfiguration(mediumConfig)
            accessibilityLabel = "\(context) is downloaded"
        case .failure:
            image = UIImage(systemName: "arrow.clockwise")?.withConfiguration(smallConfig)
            accessibilityLabel = "Failed to download \(context)"
            bgColor = .accent().withAlphaComponent(0.3)
        }

        button.setImage(image, for: .normal)
        button.backgroundColor = bgColor

        if hasProgress {
            let current = post.flatMap { BHDownloadsManager.shared.item(for: $0.id)?.progress } ?? 0
            progressView.setProgress(Float(current), animated: false)
        } else {
            progressView.setProgress(0, animated: false)
        }
        progressView.isHidden = !hasProgress

        if hasSpinner {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        /// accessability
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        button.isAccessibilityElement = false
        progressView.isAccessibilityElement = false
        activityIndicator.isAccessibilityElement = false
    }
    
    // MARK: - Actions
    
    @objc private func onPress(_ sender: Any) {
        guard let validPost = post else { return }

        switch status {
        case .start, .failure:
            BHDownloadsManager.shared.download(validPost, reason: .manually)
        case .pending,
             .progress,
             .success:
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

