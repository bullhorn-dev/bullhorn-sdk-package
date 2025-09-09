
import Foundation
import UIKit

protocol BHPostHeaderViewDelegate: AnyObject {
    func postHeaderView(_ view: BHPostHeaderView, didSelectTabBarItem item: BHPostTabs)
    func postHeaderView(_ view: BHPostHeaderView, didSelectUser user: BHUser)
    func postHeaderView(_ view: BHPostHeaderView, didSelectShare shareLink: URL)
    func postHeaderView(_ view: BHPostHeaderView, didGetError message: String)
}

class BHPostHeaderView: UITableViewHeaderFooterView {
        
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagLabel: BHPaddingLabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playButton: BHPlayButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var downloadButton: BHDownloadButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var waitingRoomView: UIView!
    @IBOutlet weak var waitingRoomLabel: UILabel!
    @IBOutlet weak var waitingRoomButton: BHWaitingRoomButton!
    @IBOutlet weak var tabbedView: BHTabbedView!
    @IBOutlet weak var tabTitleLabel: UILabel!
    @IBOutlet weak var separatorView1: UIView!
    @IBOutlet weak var separatorView2: UIView!
    @IBOutlet weak var playedLabel: UILabel!
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressBgView: UIView!
    @IBOutlet weak var progressActiveView: UIView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!

    weak var delegate: BHPostHeaderViewDelegate?

    var postsManager: BHPostsManager?
    
    fileprivate var selectedTab: BHPostTabs = .details

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
    }
    
    // MARK: - Public
    
    func reloadData() {
        let duration: Double = Double(postsManager?.post?.recording?.duration ?? 0)

        playButton.post = postsManager?.post
        waitingRoomButton.post = postsManager?.post

        downloadButton.post = postsManager?.post

        userIcon.sd_setImage(with: postsManager?.post?.user.coverUrl, placeholderImage: placeholderImage)
        userLabel.text = postsManager?.post?.user.fullName
        titleLabel.text = postsManager?.post?.title
        durationLabel.text = duration.stringFormatted()
        tabTitleLabel.text = selectedTab == .details ? "Episode Description" : "Episode Transcription"
        
        updateTagLabel()
        updateControls()
    }

    func setup(_ tab: BHPostTabs = .details) {
        
        contentView.backgroundColor = .primaryBackground()

        playButton.post = postsManager?.post
        waitingRoomButton.post = postsManager?.post

        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true

        likeButton.setTitle("", for: .normal)
        likeButton.backgroundColor = .clear
        likeButton.configuration?.baseForegroundColor = .primary()

        userLabel.textColor = .primary()
        userLabel.font = .primaryText()
        userLabel.adjustsFontForContentSizeCategory = true

        dateLabel.textColor = .secondary()
        dateLabel.font = .secondaryText()
        dateLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = .primary()
        titleLabel.font = .primaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        durationLabel.textColor = .primary()
        durationLabel.font = .secondaryText()
        durationLabel.adjustsFontForContentSizeCategory = true

        waitingRoomLabel.textColor = .primary()

        playedLabel.textColor = .primary()
        playedLabel.font = .secondaryText()
        playedLabel.adjustsFontForContentSizeCategory = true

        tabTitleLabel.textColor = .primary()
        tabTitleLabel.font = .primaryText()
        tabTitleLabel.adjustsFontForContentSizeCategory = true

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .clear
        shareButton.configuration?.baseForegroundColor = .primary()

        separatorView1.addBottomBorder()
        separatorView2.addBottomBorder()
        separatorView1.backgroundColor = .clear
        separatorView2.backgroundColor = .clear

        tabbedView.currentlySelectedIndex = tab.rawValue
        tabbedView.tabs = [
            BHTabItemView(title: "Details"),
            BHTabItemView(title: "Transcript")
        ]
        tabbedView.delegate = self
        
        selectedTab = tab
        
        progressBgView.layer.cornerRadius = progressBgView.frame.height / 2
        progressBgView.layer.borderColor = UIColor.primaryBackground().cgColor
        progressBgView.layer.borderWidth = 1
        progressBgView.backgroundColor = .divider()
        progressBgView.clipsToBounds = true
            
        progressActiveView.layer.cornerRadius = progressActiveView.frame.height / 2
        progressActiveView.backgroundColor = .secondary()
        progressActiveView.clipsToBounds = true
        
        guard let validPost = postsManager?.post else { return }
        playButton.isAccessibilityElement = true
        playButton.accessibilityLabel = "Play \(validPost.title)"
        likeButton.isAccessibilityElement = true
        likeButton.accessibilityLabel = "Like \(validPost.title)"
        shareButton.isAccessibilityElement = true
        shareButton.accessibilityLabel = "Share \(validPost.title)"
        downloadButton.isAccessibilityElement = true
        downloadButton.accessibilityLabel = "Download \(validPost.title)"
        
        reloadData()
    }
    
    func calculateHeight() -> CGFloat {
        let spacing: CGFloat = 6
        var totalHeight: CGFloat = 3 * Constants.paddingVertical
        
        totalHeight += userIcon.frame.size.height + spacing
        totalHeight += heightForView(text: titleLabel.text ?? "", font: titleLabel.font, width: frame.size.width - 2 * Constants.paddingHorizontal) + spacing
        totalHeight += tabbedView.frame.size.height + spacing
        totalHeight += tabTitleLabel.frame.size.height + spacing
        totalHeight += shareButton.frame.size.height + spacing

        if hasRecording() {
            totalHeight += playerView.frame.size.height + spacing
        }

        if hasTag() {
            totalHeight += tagView.frame.size.height + spacing
        }
        
        if hasWaitingRoom() {
            totalHeight += waitingRoomView.frame.size.height + spacing
        }
        
        return totalHeight
    }
    
    // MARK: Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
        
        BHHybridPlayer.shared.addListener(self)
    }

    fileprivate func updateControls() {
        guard let validPost = postsManager?.post else { return }

        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let mediumConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .medium)
        var image: UIImage? = nil

        if BullhornSdk.shared.externalUser?.level == .external {
            if validPost.liked {
                image = UIImage(systemName: "heart.fill")?.withConfiguration(mediumConfig)
            } else {
                image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
            }
        } else {
            image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
        }
        likeButton.setImage(image, for: .normal)
        shareButton.setImage(UIImage(systemName: "arrowshape.turn.up.right")?.withConfiguration(mediumConfig), for: .normal)

        if validPost.isLiveStream() {
            playerView.isHidden = false
            downloadButton.isHidden = true
            playButton.isHidden = false
            durationLabel.text = ""
            playedLabel.isHidden = true
        } else if validPost.hasRecording() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)

            playerView.isHidden = false
            downloadButton.isHidden = false
            playButton.isHidden = false
            durationLabel.text = duration.stringFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = !validPost.isPlaybackCompleted
        } else {
            playerView.isHidden = true
            downloadButton.isHidden = true
            playButton.isHidden = true
            durationLabel.isHidden = true
            playedLabel.isHidden = true
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
        
        if UserDefaults.standard.isEpisodeProgressViewFeatureEnabled {
            if let duration = validPost.recording?.duration, validPost.playbackOffset > 0, duration > 0, abs(duration - Int(validPost.playbackOffset)) > 5 {
                let fullWidth = progressBgView.frame.size.width
                let progressWidth = validPost.playbackOffset * fullWidth / Double(duration)
                
                if progressWidth > 0 {
                    progressViewWidthConstraint.constant =  progressWidth < fullWidth ? progressWidth : 0
                    progressView.isHidden = false
                } else {
                    progressView.isHidden = true
                }
            } else {
                progressView.isHidden = true
            }
        } else {
            progressView.isHidden = true
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

        tagView.isHidden = text.isEmpty
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
                NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
        }
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
}
