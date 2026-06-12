
import UIKit
import Foundation
import SDWebImage

class BHPostContentView: UIView {

    // MARK: - Public configuration

    var post: BHPost? {
        didSet { update() }
    }

    var playlist: [BHPost]? {
        didSet { playButton.playlist = playlist }
    }

    var context: String = "Episode"

    var autoplayContext: BHAutoplayContext? {
        didSet { playButton.autoplayContext = autoplayContext }
    }

    var shareBtnTapClosure: ((URL)->())?
    var likeBtnTapClosure: ((Bool)->())?
    var transcriptBtnTapClosure: ((String)->())?
    var errorClosure: ((String)->())?

    // MARK: - Subviews

    let shadowView: UIView = {
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

    let userIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.clipsToBounds = true
        imageView.isAccessibilityElement = false
        return imageView
    }()

    let tagLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.font = .fontWithName(.robotoMedium, size: 8)
        label.numberOfLines = 1
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .primaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 2
        return label
    }()

    let descriptionLabel: RichLabel = {
        let label = RichLabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.numberOfLines = 4
        return label
    }()

    let playButton: BHPlayButton = {
        return BHPlayButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    }()

    let waitingRoomLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoRegular, size: 14)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 0
        return label
    }()

    let waitingRoomButton: BHWaitingRoomButton = {
        return BHWaitingRoomButton(frame: CGRect(x: 0, y: 0, width: 140, height: 32))
    }()

    let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        button.backgroundColor = .clear
        return button
    }()

    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        button.backgroundColor = .clear
        return button
    }()

    let downloadButton: BHDownloadButton = {
        return BHDownloadButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    }()

    let transcriptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        button.backgroundColor = .clear
        return button
    }()

    let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = .primary()
        button.backgroundColor = .clear
        return button
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.numberOfLines = 1
        return label
    }()

    let playedLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.textAlignment = .right
        label.numberOfLines = 1
        label.text = "Played"
        return label
    }()

    let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private var tagRow: UIStackView!
    private var waitingButtonRow: UIStackView!
    private var bottomView: UIStackView!

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()
    fileprivate var placeholderImage: UIImage?

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        BHHybridPlayer.shared.removeListener(self)
    }

    /// Called by the wrapping cell's `prepareForReuse`.
    func prepareForReuse() {
        accessibilityLabel = nil
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

    // MARK: - Layout

    private func setupUI() {

        let iconSize: CGFloat = 52

        backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        likeButton.addTarget(self, action: #selector(onLikeButton(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(onShareButton(_:)), for: .touchUpInside)
        transcriptButton.addTarget(self, action: #selector(onTranscriptButton(_:)), for: .touchUpInside)
        optionsButton.addTarget(self, action: #selector(onOptionsButton(_:)), for: .touchUpInside)

        let topStackView = UIStackView(arrangedSubviews: [userIcon, titleLabel, playButton])
        topStackView.axis = .horizontal
        topStackView.alignment = .center
        topStackView.distribution = .fill
        topStackView.spacing = 12
        /// fixed-width elements hug; the title absorbs the remaining width
        userIcon.setContentHuggingPriority(.required, for: .horizontal)
        playButton.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        tagLabel.setContentHuggingPriority(.required, for: .horizontal)
        tagRow = UIStackView(arrangedSubviews: [tagLabel, UIView()])
        tagRow.axis = .horizontal
        tagRow.distribution = .fill

        waitingButtonRow = UIStackView(arrangedSubviews: [waitingRoomButton, UIView()])
        waitingButtonRow.axis = .horizontal
        waitingButtonRow.distribution = .fill

        let buttonsStackView = UIStackView(arrangedSubviews: [likeButton, shareButton, downloadButton, transcriptButton, optionsButton, UIView()])
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fill
        buttonsStackView.spacing = 8

        bottomView = UIStackView(arrangedSubviews: [dateLabel, playedLabel, durationLabel])
        bottomView.axis = .horizontal
        bottomView.distribution = .fill
        bottomView.spacing = 12
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        playedLabel.setContentHuggingPriority(.required, for: .horizontal)
        durationLabel.setContentHuggingPriority(.required, for: .horizontal)

        let vStackView = UIStackView(arrangedSubviews: [topStackView, tagRow, descriptionLabel, waitingRoomLabel, waitingButtonRow, buttonsStackView, bottomView])
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        vStackView.distribution = .fill
        vStackView.spacing = 8

        shadowView.addSubview(vStackView)
        addSubview(shadowView)

        [userIcon, playButton, waitingRoomButton, likeButton, shareButton, downloadButton, transcriptButton, optionsButton, vStackView, shadowView, bottomView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let shadowTrailing = shadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.paddingHorizontal)
        shadowTrailing.priority = UILayoutPriority(999)
        let shadowBottom = shadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.paddingVertical / 2)
        shadowBottom.priority = UILayoutPriority(999)

        let vStackTrailing = vStackView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor, constant: -Constants.paddingHorizontal)
        vStackTrailing.priority = UILayoutPriority(999)
        let vStackBottom = vStackView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor, constant: -Constants.paddingVertical)
        vStackBottom.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            shadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.paddingHorizontal),
            shadowView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.paddingVertical / 2),
            shadowTrailing,
            shadowBottom,

            vStackView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor, constant: Constants.paddingHorizontal),
            vStackView.topAnchor.constraint(equalTo: shadowView.topAnchor, constant: Constants.paddingVertical),
            vStackTrailing,
            vStackBottom,

            userIcon.widthAnchor.constraint(equalToConstant: iconSize),
            userIcon.heightAnchor.constraint(equalToConstant: iconSize),

            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),

            waitingRoomButton.widthAnchor.constraint(equalToConstant: 140),
            waitingRoomButton.heightAnchor.constraint(equalToConstant: 32),

            likeButton.widthAnchor.constraint(equalToConstant: 36),
            likeButton.heightAnchor.constraint(equalToConstant: 36),
            shareButton.widthAnchor.constraint(equalToConstant: 36),
            shareButton.heightAnchor.constraint(equalToConstant: 36),
            downloadButton.widthAnchor.constraint(equalToConstant: 36),
            downloadButton.heightAnchor.constraint(equalToConstant: 36),
            transcriptButton.widthAnchor.constraint(equalToConstant: 36),
            transcriptButton.heightAnchor.constraint(equalToConstant: 36),
            optionsButton.widthAnchor.constraint(equalToConstant: 36),
            optionsButton.heightAnchor.constraint(equalToConstant: 36),

            bottomView.heightAnchor.constraint(equalToConstant: 20),
        ])

        BHHybridPlayer.shared.addListener(self)
    }

    // MARK: - Configuration

    fileprivate func update() {

        playButton.post = post
        playButton.autoplayContext = autoplayContext
        downloadButton.post = post
        waitingRoomButton.post = post

        titleLabel.text = post?.title
        descriptionLabel.text = post?.trimmedDescription()
        userIcon.sd_setImage(with: post?.coverUrl, placeholderImage: placeholderImage)

        updateTagLabel()
        updateControls()
        setupAccessibility()
    }

    private func setupAccessibility() {
        guard let title = post?.title else { return }

        isAccessibilityElement = false
        accessibilityLabel = "\(context) \(title)"

        titleLabel.accessibilityLabel = "\(context) title: \(title)"
        if let validDescription = post?.trimmedDescription() {
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

        accessibilityElements = [titleLabel, descriptionLabel, playButton, likeButton, shareButton, downloadButton, transcriptButton, optionsButton, dateLabel, durationLabel]
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
            durationLabel.text = duration.prettyFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = true
            bottomView.isHidden = true
        } else if validPost.hasRecording() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)
            downloadButton.isHidden = false
            optionsButton.isHidden = false
            transcriptButton.isHidden = !validPost.hasTranscript
            playButton.isHidden = false
            durationLabel.text = duration.prettyFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = !validPost.isPlaybackCompleted
            bottomView.isHidden = false
        } else {
            downloadButton.isHidden = true
            optionsButton.isHidden = true
            transcriptButton.isHidden = true
            playButton.isHidden = true
            durationLabel.isHidden = true
            playedLabel.isHidden = true
            bottomView.isHidden = true
        }

        if let validDate = validPost.publishedAtDate {
            dateLabel.text = dateFormatter.prettyDayFormatString(from: validDate)
            dateLabel.isHidden = false
        } else {
            dateLabel.text = ""
            dateLabel.isHidden = true
        }

        if validPost.isLiveNow() {
            if validPost.liveStatus.isScheduled() {
                waitingRoomButton.isHidden = false
                waitingButtonRow.isHidden = false
                waitingRoomLabel.isHidden = false

                if validPost.liveScheduledInPast() {
                    waitingRoomLabel.text = "Live is coming soon"
                } else if let scheduledDate = validPost.scheduledAtDate {
                    waitingRoomLabel.text = "Going live \(dateFormatter.prettyFutureDayFormatString(from: scheduledDate))"
                }
            } else {
                waitingRoomButton.isHidden = true
                waitingButtonRow.isHidden = true
                waitingRoomLabel.isHidden = true
            }
        } else {
            waitingRoomButton.isHidden = true
            waitingButtonRow.isHidden = true
            waitingRoomLabel.isHidden = true
        }
    }

    fileprivate func updateTagLabel() {
        guard let validPost = post else { return }

        var text: String = ""
        var color: UIColor = .clear

        if validPost.isLiveNow() {
            if validPost.liveStatus.isScheduled() {
                text = "UPCOMING"
                color = .primary()
            } else {
                text = "LIVE"
                color = .accent()
            }
        } else if validPost.isLiveStream() {
            text = "LIVE"
            color = .accent()
        } else if validPost.isInteractive() {
            if validPost.hasVideo() && validPost.hasTiles() {
                text = "VIDEO + INTERACTIVE"
            } else if validPost.hasVideo() {
                text = "VIDEO"
            } else if validPost.hasTiles() {
                text = "INTERACTIVE"
            }
            color = .accent()
        }

        tagLabel.isHidden = text.isEmpty
        tagRow.isHidden = text.isEmpty
        tagLabel.text = text
        tagLabel.textColor = color
        tagLabel.layer.borderColor = color.cgColor
        tagLabel.layer.borderWidth = 1
        tagLabel.layer.cornerRadius = 3
        tagLabel.addCharacterSpacing()

        tagLabel.paddingLeft = 6
        tagLabel.paddingRight = 6
        tagLabel.paddingTop = 4
        tagLabel.paddingBottom = 4
    }

    fileprivate func updateContext() {
        playButton.autoplayContext = autoplayContext
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
            let vc = BHAuthBottomSheet()
            vc.preferredSheetSizing = .fit
            vc.panToDismissEnabled = true
            UIApplication.topNavigationController()?.present(vc, animated: true)
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

extension BHPostContentView: BHHybridPlayerListener {

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
