
import UIKit
import SDWebImage
import Foundation

class BHPostCollectionCell: UICollectionViewCell {
        
    class var reusableIndentifer: String { return String(describing: self) }

    var post: BHPost? {
        didSet {
            self.update()
        }
    }
    
    var playlist: [BHPost]? {
        didSet {
            self.playButton.playlist = playlist
        }
    }
    
    var context: String = "Episode"

    fileprivate var placeholderImage: UIImage?

    private let shadowView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.shadow().withAlphaComponent(0.5).cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 4
        view.backgroundColor = .cardBackground()
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .primaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.numberOfLines = 4
        return label
    }()
    
    let playButton: BHPlayButton = {
        let button = BHPlayButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        return button
    }()

    let downloadButton: BHDownloadButton = {
        let button = BHDownloadButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        return button
    }()

    let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .primaryButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .primaryBackground()
        button.tintColor = .primary()
        return button
    }()

    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .primaryButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .primaryBackground()
        button.tintColor = .primary()
        return button
    }()

    let transcriptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .primaryButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .primaryBackground()
        button.tintColor = .primary()
        return button
    }()
    
    let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .primaryButton()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .primaryBackground()
        button.tintColor = .primary()
        return button
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.numberOfLines = 1
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private let playedLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.textAlignment = .right
        label.numberOfLines = 1
        label.text = "Played"
        return label
    }()

    var shareBtnTapClosure: ((URL)->())?
    var likeBtnTapClosure: ((Bool)->())?
    var transcriptBtnTapClosure: ((String)->())?
    var errorClosure: ((String)->())?

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()
        
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shadowView.frame = CGRect(x: Constants.paddingHorizontal, y: Constants.paddingVertical / 2, width: frame.size.width - 2 * Constants.paddingHorizontal, height: frame.size.height - Constants.paddingVertical)

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        contentView.accessibilityLabel = nil
        playButton.accessibilityLabel = nil
        likeButton.accessibilityLabel = nil
        shareButton.accessibilityLabel = nil
        transcriptButton.accessibilityLabel = nil
        optionsButton.accessibilityLabel = nil
        downloadButton.accessibilityLabel = nil
        titleLabel.accessibilityLabel = nil
        descriptionLabel.accessibilityLabel = nil
        dateLabel.accessibilityLabel = nil
        durationLabel.accessibilityLabel = nil
    }

    // MARK: - Private Methods
    
    private func setupUI() {
        
        let iconSize: CGFloat = 48
        
        contentView.backgroundColor = .primaryBackground()
        
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        likeButton.addTarget(self, action: #selector(onLikeButton(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(onShareButton(_:)), for: .touchUpInside)
        transcriptButton.addTarget(self, action: #selector(onTranscriptButton(_:)), for: .touchUpInside)
        optionsButton.addTarget(self, action: #selector(onOptionsButton(_:)), for: .touchUpInside)
        
        let hTopStackView = UIStackView(arrangedSubviews: [imageView, titleLabel, playButton])
        hTopStackView.axis = .horizontal
        hTopStackView.alignment = .center
        hTopStackView.distribution = .equalSpacing
        hTopStackView.spacing = 12

        let hButtonsStackView = UIStackView(arrangedSubviews: [likeButton, shareButton, downloadButton, transcriptButton, optionsButton, UIView()])
        hTopStackView.axis = .horizontal
        hTopStackView.alignment = .leading
        hTopStackView.distribution = .equalSpacing
        hTopStackView.spacing = 8

        let hBottomStackView = UIStackView(arrangedSubviews: [dateLabel, playedLabel, durationLabel])
        hTopStackView.axis = .horizontal
        hTopStackView.alignment = .fill
        hTopStackView.distribution = .fill
        hTopStackView.spacing = 12

        let vStackView = UIStackView(arrangedSubviews: [hTopStackView, descriptionLabel, hButtonsStackView, hBottomStackView])
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        vStackView.distribution = .equalSpacing
        vStackView.spacing = 8

        shadowView.addSubview(vStackView)
        contentView.addSubview(shadowView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        transcriptButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        hTopStackView.translatesAutoresizingMaskIntoConstraints = false
        hBottomStackView.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            vStackView.centerYAnchor.constraint(equalTo: shadowView.centerYAnchor),
            vStackView.leftAnchor.constraint(equalTo: shadowView.leftAnchor, constant: Constants.paddingHorizontal),
            vStackView.rightAnchor.constraint(equalTo: shadowView.rightAnchor, constant: -Constants.paddingHorizontal),

            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),

            playButton.widthAnchor.constraint(equalToConstant: 48),
            playButton.heightAnchor.constraint(equalToConstant: 48),

            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),

            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),

            downloadButton.widthAnchor.constraint(equalToConstant: 44),
            downloadButton.heightAnchor.constraint(equalToConstant: 44),

            transcriptButton.widthAnchor.constraint(equalToConstant: 44),
            transcriptButton.heightAnchor.constraint(equalToConstant: 44),
            
            optionsButton.widthAnchor.constraint(equalToConstant: 44),
            optionsButton.heightAnchor.constraint(equalToConstant: 44),

            hBottomStackView.heightAnchor.constraint(equalToConstant: 20),

            durationLabel.rightAnchor.constraint(equalTo: hBottomStackView.rightAnchor),
        ])
        
        BHHybridPlayer.shared.addListener(self)
    }

    fileprivate func update() {
        
        playButton.post = post
        downloadButton.post = post
        
        titleLabel.text = post?.title
        descriptionLabel.text = post?.description
        imageView.sd_setImage(with: post?.user.coverUrl, placeholderImage: placeholderImage)
        
        updateControls()
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        guard let title = post?.title else { return }

        contentView.isAccessibilityElement = true
        contentView.accessibilityTraits = .button
        contentView.accessibilityLabel = "\(context) \(title)"
        
        titleLabel.accessibilityLabel = "\(context) title: \(title)"
        if let validDescription = post?.description {
            descriptionLabel.accessibilityLabel = "\(context) details: \(validDescription)"
        }
        if let dateText = dateLabel.text {
            dateLabel.accessibilityLabel = "\(context) published: \(dateText)"
        }
        if let durationText = durationLabel.text {
            durationLabel.accessibilityLabel = "\(context) duration: \(durationText)"
        }

        playButton.isAccessibilityElement = true
        playButton.context = "\(context) \(title)"
        likeButton.isAccessibilityElement = true
        likeButton.accessibilityLabel = post?.liked == true ? "Unfavorite \(context) \(title)" : "Favorite \(context) \(title)"
        shareButton.isAccessibilityElement = true
        shareButton.accessibilityLabel = "Share \(context) \(title)"
        downloadButton.isAccessibilityElement = true
        downloadButton.context = "\(context) \(title)"
        transcriptButton.isAccessibilityElement = true
        transcriptButton.accessibilityLabel = "Transcript \(context) \(title)"
        optionsButton.isAccessibilityElement = true
        optionsButton.accessibilityLabel = "Options: \(context) \(title)"
        
        self.accessibilityElements = [contentView, titleLabel, descriptionLabel, playButton, likeButton, shareButton, downloadButton, transcriptButton, optionsButton, dateLabel, durationLabel]
        self.isAccessibilityElement = false
    }

    fileprivate func updateControls() {
        guard let validPost = post else { return }

        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let mediumConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .medium)
        var image: UIImage? = nil

        if BullhornSdk.shared.externalUser?.level == .external {
            if validPost.liked {
                image = UIImage(systemName: "heart.fill")?.withConfiguration(mediumConfig)
                likeButton.accessibilityLabel = "Unfavorite \(context) \(validPost.title)"
            } else {
                image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
                likeButton.accessibilityLabel = "Favorite \(context) \(validPost.title)"
            }
        } else {
            image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
            likeButton.accessibilityLabel = "Favorite \(context) \(validPost.title)"
        }
        likeButton.setImage(image, for: .normal)
        likeButton.setTitle("", for: .normal)
        likeButton.backgroundColor = .clear
        likeButton.configuration?.baseForegroundColor = .primary()

        shareButton.setImage(UIImage(systemName: "arrowshape.turn.up.right")?.withConfiguration(mediumConfig), for: .normal)
        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .clear
        shareButton.configuration?.baseForegroundColor = .primary()

        transcriptButton.setImage(UIImage(systemName: "doc.plaintext")?.withConfiguration(mediumConfig), for: .normal)
        transcriptButton.setTitle("", for: .normal)
        transcriptButton.backgroundColor = .clear
        transcriptButton.configuration?.baseForegroundColor = .primary()

        optionsButton.setImage(UIImage(systemName: "ellipsis")?.withConfiguration(mediumConfig), for: .normal)
        optionsButton.setTitle("", for: .normal)
        optionsButton.backgroundColor = .clear
        optionsButton.configuration?.baseForegroundColor = .primary()

        if validPost.isLiveStream() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)
            downloadButton.isHidden = true
            optionsButton.isHidden = false
            transcriptButton.isHidden = true
            playButton.isHidden = false
            durationLabel.text = duration.stringFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = true
//            bottomView.isHidden = true
        } else if validPost.hasRecording() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)
            downloadButton.isHidden = false
            optionsButton.isHidden = false
            transcriptButton.isHidden = !validPost.hasTranscript
            playButton.isHidden = false
            durationLabel.text = duration.stringFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = !validPost.isPlaybackCompleted
//            bottomView.isHidden = false
        } else {
            downloadButton.isHidden = true
            optionsButton.isHidden = true
            transcriptButton.isHidden = true
            playButton.isHidden = true
            durationLabel.isHidden = true
            playedLabel.isHidden = true
//            bottomView.isHidden = true
        }
        
        if let validDate = validPost.startTimeDate {
            dateLabel.text = dateFormatter.prettyDayFormatString(from: validDate)
            dateLabel.isHidden = false
        } else {
            dateLabel.text = ""
            dateLabel.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction func onLikeButton(_ sender: UIButton) {
        guard let validPost = post else { return }
        
        if BullhornSdk.shared.externalUser?.level == .external {
            if validPost.liked {
                if BHReachabilityManager.shared.isConnected() {
                    BHPostsManager.shared.postLikeOff(validPost) { result in
                        switch result {
                        case .success(post: _):
                            self.post?.liked = false
                            self.updateControls()
                            self.likeBtnTapClosure?(false)
                        case .failure(error: _):
                            self.errorClosure?("Failed to unlike episode. This episode is no longer available.")
                        }
                    }
                } else {
                    errorClosure?("Failed to unlike episode. The Internet connection is lost.")
                }
            } else {
                if BHReachabilityManager.shared.isConnected() {
                    BHPostsManager.shared.postLikeOn(validPost) { result in
                        switch result {
                        case .success(post: _):
                            self.post?.liked = true
                            self.updateControls()
                            self.likeBtnTapClosure?(true)
                        case .failure(error: _):
                            self.errorClosure?("Failed to like episode. This episode is no longer available.")
                        }
                    }
                } else {
                    errorClosure?("Failed to like episode. The Internet connection is lost.")
                }
            }
        } else {
            NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
        }
    }

    @IBAction func onShareButton(_ sender: UIButton) {
        guard let validPost = post else { return }
        
        if BHReachabilityManager.shared.isConnected() {
            BHPostsManager.shared.getPost(validPost.id, context: nil) { result in
                switch result {
                case .success(post: let post):
                    DispatchQueue.main.async {
                        self.shareBtnTapClosure?(post.shareLink)
                    }
                case .failure(error: _):
                    DispatchQueue.main.async {
                        self.errorClosure?("Failed to share episode. This episode is no longer available.")
                    }
                }
            }
            
            /// track stats
            let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .shareEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
            BHTracker.shared.trackEvent(with: request)

        } else {
            errorClosure?("Failed to share episode. The Internet connection is lost.")
        }
    }
    
    @IBAction func onTranscriptButton(_ sender: UIButton) {
        guard let validPost = post else { return }
        
        self.transcriptBtnTapClosure?(validPost.id)
    }

    @IBAction func onOptionsButton(_ sender: UIButton) {
        let optionsSheet = BHPostOptionsBottomSheet()
        optionsSheet.post = post
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true

        UIApplication.topNavigationController()?.present(optionsSheet, animated: true)
    }
}

// MARK: - BHHybridPlayerListener

extension BHPostCollectionCell: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {}

    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {
        if let validPost = self.post, validPost.id == item.post.postId {
            DispatchQueue.main.async {
                self.post?.isPlaybackCompleted = completed
                self.playedLabel.isHidden = !completed
            }
        }
    }
}

