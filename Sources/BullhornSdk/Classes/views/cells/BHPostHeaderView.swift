
import Foundation
import UIKit

protocol BHPostHeaderViewDelegate: AnyObject {
    func postHeaderView(_ view: BHPostHeaderView, didSelectTabBarItem item: BHPostTabs)
    func postHeaderView(_ view: BHPostHeaderView, didSelectUser user: BHUser)
    func postHeaderView(_ view: BHPostHeaderView, didSelectShare shareLink: URL)
    func postHeaderView(_ view: BHPostHeaderView, didSelectSocialLink link: URL)
    func postHeaderView(_ view: BHPostHeaderView, didGetError message: String)
}

class BHPostHeaderView: UITableViewHeaderFooterView {
        
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagLabel: BHPaddingLabel!
    @IBOutlet weak var postIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: BHPlayButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var downloadButton: BHDownloadButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var youtubeButton: UIButton!
    @IBOutlet weak var waitingRoomView: UIView!
    @IBOutlet weak var waitingRoomLabel: UILabel!
    @IBOutlet weak var waitingRoomButton: BHWaitingRoomButton!
    @IBOutlet weak var tabbedView: BHTabbedView!
    @IBOutlet weak var playedLabel: UILabel!
    @IBOutlet weak var divider1Label: UILabel!
    @IBOutlet weak var divider2Label: UILabel!

    weak var delegate: BHPostHeaderViewDelegate?

    var postsManager: BHPostsManager?
    
    fileprivate var selectedTab: BHPostTabs = .details

    fileprivate var links: [BHSocialLinkItem] = []

    fileprivate var placeholderImage: UIImage?

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shareButton.layer.cornerRadius = shareButton.frame.size.height / 2
        likeButton.layer.cornerRadius = likeButton.frame.size.height / 2
        downloadButton.layer.cornerRadius = downloadButton.frame.size.height / 2
        youtubeButton.layer.cornerRadius = youtubeButton.frame.size.height / 2
        userIcon.layer.cornerRadius = userIcon.frame.size.height / 2
    }
    
    // MARK: - Public
    
    func reloadData() {
        let duration: Double = Double(postsManager?.post?.recording?.duration ?? 0)

        playButton.post = postsManager?.post
        waitingRoomButton.post = postsManager?.post

        downloadButton.post = postsManager?.post

        postIcon.sd_setImage(with: postsManager?.post?.coverUrl, placeholderImage: placeholderImage)
        userIcon.sd_setImage(with: postsManager?.post?.user.coverUrl, placeholderImage: placeholderImage)
        userLabel.text = postsManager?.post?.user.fullName
        titleLabel.text = postsManager?.post?.title
        durationLabel.text = duration.prettyFormatted()
        
        updateTagLabel()
        updateControls()
    }

    func setup(_ tab: BHPostTabs = .details) {
        
        contentView.backgroundColor = .fxPrimaryBackground()

        playButton.post = postsManager?.post
        playButton.title = "Listen"
        waitingRoomButton.post = postsManager?.post

        postIcon.layer.cornerRadius = 8
        postIcon.layer.borderColor = UIColor.tertiary().cgColor
        postIcon.layer.borderWidth = 1
        postIcon.backgroundColor = .tertiary()
        postIcon.clipsToBounds = true

        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true

        likeButton.setTitle("", for: .normal)
        likeButton.backgroundColor = .secondaryBackground()
        likeButton.configuration?.baseForegroundColor = .primary()

        userLabel.textColor = .primary()
        userLabel.font = .primaryText()
        userLabel.adjustsFontForContentSizeCategory = true

        dateLabel.textColor = .secondary()
        dateLabel.font = .fontWithName(.robotoMedium, size: 12)
        dateLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = .primary()
        titleLabel.font = .fontWithName(.robotoMedium, size: 16)
        titleLabel.adjustsFontForContentSizeCategory = true

        durationLabel.textColor = .secondary()
        durationLabel.font = .fontWithName(.robotoMedium, size: 12)
        durationLabel.adjustsFontForContentSizeCategory = true

        waitingRoomLabel.textColor = .primary()

        playedLabel.textColor = .secondary()
        playedLabel.font = .fontWithName(.robotoMedium, size: 12)
        playedLabel.adjustsFontForContentSizeCategory = true

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .secondaryBackground()
        shareButton.configuration?.baseForegroundColor = .primary()

        youtubeButton.setTitle("YouTube", for: .normal)
        youtubeButton.backgroundColor = .secondaryBackground()
        youtubeButton.configuration?.baseForegroundColor = .primary()
        youtubeButton.titleLabel?.font = .fontWithName(.robotoRegular, size: 14)
        youtubeButton.setTitleColor(.primary(), for: .normal)

        downloadButton.backgroundColor = .secondaryBackground()

        tabbedView.currentlySelectedIndex = tab.rawValue
        tabbedView.tabs = [
            BHTabItemView(title: "Details"),
            BHTabItemView(title: "Transcript")
        ]
        tabbedView.delegate = self
        tabbedView.isHidden = !hasTranscript()
        selectedTab = tab
        
        setupSocialLinks()
        setupAccessibility()
        reloadData()
    }
    
    func calculateHeight() -> CGFloat {
        let spacing: CGFloat = 12
        var totalHeight: CGFloat = Constants.episodeProfileIconSize + 2 * Constants.paddingVertical
        
        totalHeight += heightForView(text: titleLabel.text ?? "", font: titleLabel.font, width: frame.size.width - 2 * Constants.paddingHorizontal) + spacing
        totalHeight += userIcon.frame.size.height + spacing
        totalHeight += durationLabel.frame.size.height + spacing
        totalHeight += shareButton.frame.size.height + spacing

        if hasRecording() {
            totalHeight += playButton.frame.size.height + spacing
        }

        if hasWaitingRoom() {
            totalHeight += waitingRoomView.frame.size.height + spacing
        }
        
        if hasTranscript() {
            totalHeight += tabbedView.frame.size.height + spacing
        }
        
        return totalHeight
    }
    
    // MARK: Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
        
        BHHybridPlayer.shared.addListener(self)
    }

    fileprivate func setupSocialLinks() {
        
        links.removeAll()

        if let socialLinks = postsManager?.post?.socialLinks {
            
            if socialLinks.hasWebsite() {
                links.append(socialLinks.websiteLink)
            }

            if socialLinks.hasFacebook() {
                links.append(socialLinks.facebookLink)
            }
            
            if socialLinks.hasInstagram() {
                links.append(socialLinks.instagramLink)
            }
            
            if socialLinks.hasTwitch() {
                links.append(socialLinks.twitchLink)
            }
            
            if socialLinks.hasTwitter() {
                links.append(socialLinks.twitterLink)
            }
            
            if socialLinks.hasYouTube() {
                links.append(socialLinks.youtubeLink)
            }
            
            if socialLinks.hasLinkedIn() {
                links.append(socialLinks.linkedinLink)
            }
        }
    }
    
    fileprivate func setupAccessibility() {
        guard let validPost = postsManager?.post else { return }

        playButton.isAccessibilityElement = true
        playButton.context = "episode"
        likeButton.isAccessibilityElement = true
        likeButton.accessibilityTraits = .button
        likeButton.accessibilityLabel = validPost.liked ? "Unfavorite episode" : "Favorite episode"
        shareButton.isAccessibilityElement = true
        shareButton.accessibilityTraits = .button
        shareButton.accessibilityLabel = "Share episode"
        youtubeButton.isAccessibilityElement = true
        youtubeButton.accessibilityTraits = .button
        youtubeButton.accessibilityLabel = "YouTube"
        youtubeButton.accessibilityValue = "external link"
        downloadButton.isAccessibilityElement = true
        downloadButton.context = "episode"
        
        if let dateText = dateLabel.text {
            dateLabel.accessibilityLabel = "Episode published: \(dateText)"
        }
        if let durationText = durationLabel.text {
            durationLabel.accessibilityLabel = "Episode duration: \(durationText)"
        }

    }

    fileprivate func updateControls() {
        guard let validPost = postsManager?.post else { return }

        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let mediumConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .medium)
        var image: UIImage? = nil

        if BullhornSdk.shared.externalUser?.level == .external {
            if validPost.liked {
                image = UIImage(systemName: "heart.fill")?.withConfiguration(mediumConfig)
                likeButton.accessibilityLabel = "Unfavorite episode"
            } else {
                image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
                likeButton.accessibilityLabel = "Favorite episode"
            }
        } else {
            image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
            likeButton.accessibilityLabel = "Favorite episode"
        }
        likeButton.setImage(image, for: .normal)
        shareButton.setImage(UIImage(systemName: "arrowshape.turn.up.right")?.withConfiguration(mediumConfig), for: .normal)

        youtubeButton.isHidden = !hasYouTubeSocialLink()

        if validPost.isLiveStream() {
            downloadButton.isHidden = true
            playButton.isHidden = false
            durationLabel.text = ""
            divider1Label.isHidden = true
            playedLabel.isHidden = true
            divider2Label.isHidden = true
        } else if validPost.hasRecording() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)

            downloadButton.isHidden = false
            playButton.isHidden = false
            durationLabel.text = duration.prettyFormatted()
            durationLabel.isHidden = false
            divider1Label.isHidden = false
            playedLabel.isHidden = !validPost.isPlaybackCompleted
            divider2Label.isHidden = !validPost.isPlaybackCompleted
        } else {
            downloadButton.isHidden = true
            playButton.isHidden = true
            durationLabel.isHidden = true
            divider1Label.isHidden = true
            playedLabel.isHidden = true
            divider2Label.isHidden = true
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
                waitingRoomView.isHidden = false
                
                if validPost.liveScheduledInPast() {
                    waitingRoomLabel.text = "Live is coming soon"
                } else if let scheduledDate = validPost.scheduledAtDate {
                    waitingRoomLabel.text = "Going live \(dateFormatter.prettyFutureDayFormatString(from: scheduledDate))"
                }
            } else {
                waitingRoomView.isHidden = true
            }
        } else {
            waitingRoomView.isHidden = true
        }
    }

    fileprivate func updateTagLabel() {
        guard let validPost = postsManager?.post else { return }
        
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

    fileprivate func hasTag() -> Bool {
        guard let validPost = postsManager?.post else { return false }
        return validPost.isLiveNow() || validPost.isLiveStream() || validPost.isInteractive()
    }
    
    fileprivate func hasWaitingRoom() -> Bool {
        guard let validPost = postsManager?.post else { return false }
        return validPost.isLiveNow() && validPost.liveStatus.isScheduled()
    }
    
    fileprivate func hasRecording() -> Bool {
        return postsManager?.post?.hasRecording() ?? false
    }
    
    fileprivate func hasYouTubeSocialLink() -> Bool {
        return postsManager?.post?.socialLinks != nil && postsManager?.post?.socialLinks?.hasYouTube() == true
    }
    
    fileprivate func hasTranscript() -> Bool {
        return postsManager?.post?.hasTranscript == true
    }
    
    fileprivate func heightForView(text: String, font: UIFont, width: CGFloat) -> CGFloat {

        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()

        return label.frame.height
    }
    
    // MARK: - Actions

    @IBAction func onShareButton(_ sender: UIButton) {
        guard let validPost = postsManager?.post else { return }

        if BHReachabilityManager.shared.isConnected() {
            postsManager?.getPost(validPost.id, context: nil) { result in
                switch result {
                case .success(post: let post):
                    DispatchQueue.main.async {
                        self.delegate?.postHeaderView(self, didSelectShare: post.shareLink)
                    }
                case .failure(error: _):
                    DispatchQueue.main.async {
                        self.delegate?.postHeaderView(self, didGetError: "Failed to share episode. This episode is no longer available.")
                    }
                }
            }
            
            let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .shareEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
            BHTracker.shared.trackEvent(with: request)

        } else {
            self.delegate?.postHeaderView(self, didGetError: "Failed to share episode. The Internet connection is lost.")
        }
    }

    @IBAction func onLikeButton(_ sender: UIButton) {
        guard let validPost = postsManager?.post else { return }
        
        if BullhornSdk.shared.externalUser?.level == .external {
            if validPost.liked {
                if BHReachabilityManager.shared.isConnected() {
                    BHPostsManager.shared.postLikeOff(validPost) { result in
                        switch result {
                        case .success(post: _):
                            self.postsManager?.post?.liked = false
                            self.updateControls()
                        case .failure(error: _):
                            DispatchQueue.main.async {
                                self.delegate?.postHeaderView(self, didGetError: "Failed to unlike episode. This episode is no longer available.")
                            }
                        }
                    }
                } else {
                    self.delegate?.postHeaderView(self, didGetError: "Failed to unlike episode. The Internet connection is lost.")
                }
            } else {
                if BHReachabilityManager.shared.isConnected() {
                    BHPostsManager.shared.postLikeOn(validPost) { result in
                        switch result {
                        case .success(post: _):
                            self.postsManager?.post?.liked = true
                            self.updateControls()
                        case .failure(error: _):
                            DispatchQueue.main.async {
                                self.delegate?.postHeaderView(self, didGetError: "Failed to like episode. This episode is no longer available.")
                            }
                        }
                    }
                } else {
                    self.delegate?.postHeaderView(self, didGetError: "Failed to like episode. The Internet connection is lost.")
                }
            }
        } else {
            let vc = BHAuthBottomSheet()
            vc.preferredSheetSizing = .fit
            vc.panToDismissEnabled = true
            UIApplication.topNavigationController()?.present(vc, animated: true)
        }
    }
    
    @IBAction func onYouTubeButton(_ sender: UIButton) {
        guard let validUrl = links.first?.url else { return }
        delegate?.postHeaderView(self, didSelectSocialLink: validUrl)
    }
}

// MARK: - BHTabbedViewDelegate

extension BHPostHeaderView: BHTabbedViewDelegate {
    
    func tabbedView(_ tabbedView: BHTabbedView, didMoveToTab index: Int) {
        selectedTab = BHPostTabs(rawValue: index) ?? .details
        delegate?.postHeaderView(self, didSelectTabBarItem: selectedTab)
    }
}

// MARK: - BHHybridPlayerListener

extension BHPostHeaderView: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        if UserDefaults.standard.isEpisodeProgressViewFeatureEnabled {
            guard let playerPost = player.post else { return }
            guard let validPost = postsManager?.post else { return }
            
            if playerPost.id == validPost.id {
                DispatchQueue.main.async {
                    self.postsManager?.post?.updatePlaybackOffset(position, completed: false)
                    self.reloadData()
                }
            }
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {
        if let validPost = self.postsManager?.post, validPost.id == item.post.postId {
            DispatchQueue.main.async {
                self.postsManager?.post?.isPlaybackCompleted = completed
                self.playedLabel.isHidden = !completed
            }
        }
    }
}
