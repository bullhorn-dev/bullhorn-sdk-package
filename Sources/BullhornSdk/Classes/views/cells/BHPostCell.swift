
import UIKit
import Foundation

class BHPostCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var tagLabel: BHPaddingLabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var playButton: BHPlayButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playedLabel: UILabel!
    @IBOutlet weak var waitingRoomLabel: UILabel!
    @IBOutlet weak var waitingRoomButton: BHWaitingRoomButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var downloadButton: BHDownloadButton!
    @IBOutlet weak var optionsButton: UIButton!

    var post: BHPost? {
        didSet {
            update()
        }
    }
    
    var playlist: [BHPost]? {
        didSet {
            playButton.playlist = playlist
        }
    }
    
    var shareBtnTapClosure: ((URL)->())?
    var likeBtnTapClosure: ((Bool)->())?

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()
    fileprivate var placeholderImage: UIImage?

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        dateLabel.textColor = .secondary()
        titleLabel.textColor = .primary()
        descriptionLabel.textColor = .secondary()
        durationLabel.textColor = .secondary()
        playedLabel.textColor = .secondary()
        waitingRoomLabel.textColor = .primary()

        let shadowColor = UIColor.shadow().withAlphaComponent(0.5)

        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowColor = shadowColor.cgColor
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 4
        
        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        
        tagLabel.sizeToFit()
    }
    
    // MARK: - Private
    
    fileprivate func update() {
        
        playButton.post = post
        downloadButton.post = post
        waitingRoomButton.post = post
        
        titleLabel.text = post?.title
        descriptionLabel.text = post?.description
        userIcon.sd_setImage(with: post?.user.coverUrl, placeholderImage: placeholderImage)
        
        updateTagLabel()
        updateControls()
    }
    
    fileprivate func updateControls() {
        guard let validPost = post else { return }

        let mediumConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .thin, scale: .medium)
        var image: UIImage? = nil

        if BullhornSdk.shared.externalUser?.level == .fox {
            if validPost.liked {
                image = UIImage(systemName: "heart.fill")?.withConfiguration(mediumConfig)
            } else {
                image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
            }
        } else {
            image = UIImage(systemName: "heart")?.withConfiguration(mediumConfig)
        }
        likeButton.setImage(image, for: .normal)
        likeButton.setTitle("", for: .normal)
        likeButton.backgroundColor = .clear
        likeButton.tintColor = .primary()

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .clear
        shareButton.tintColor = .primary()

        optionsButton.setTitle("", for: .normal)
        optionsButton.backgroundColor = .clear
        optionsButton.tintColor = .primary()

        if validPost.hasRecording() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)

            downloadButton.isHidden = false
            optionsButton.isHidden = false
            playButton.isHidden = false
            durationLabel.text = duration.stringFormatted()
            durationLabel.isHidden = false
            playedLabel.isHidden = !validPost.isPlaybackCompleted
        } else {
            downloadButton.isHidden = true
            optionsButton.isHidden = true
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
                waitingRoomButton.isHidden = false
                waitingRoomLabel.isHidden = false
                
                if validPost.liveScheduledInPast() {
                    waitingRoomLabel.text = "Live is coming soon"
                } else if let scheduledDate = validPost.scheduledAtDate {
                    waitingRoomLabel.text = "Going live \(dateFormatter.prettyFutureDayFormatString(from: scheduledDate))"
                }
            } else {
                waitingRoomButton.isHidden = true
                waitingRoomLabel.isHidden = true
            }
        } else {
            waitingRoomButton.isHidden = true
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
    
    // MARK: - Actions

    @IBAction func onLikeButton(_ sender: UIButton) {
        guard let validPost = post else { return }
        
        if BHReachabilityManager.shared.isConnected() {
            if BullhornSdk.shared.externalUser?.level == .fox {
                if validPost.liked {
                    BHPostsManager.shared.postLikeOff(validPost.id) { result in
                        self.post?.liked = false
                        self.updateControls()
                        self.likeBtnTapClosure?(false)
                        
                        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .dislikeEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
                        BHTracker.shared.trackEvent(with: request)
                    }
                } else {
                    BHPostsManager.shared.postLikeOn(validPost.id) { result in
                        self.post?.liked = true
                        self.updateControls()
                        self.likeBtnTapClosure?(true)
                        
                        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .likeEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
                        BHTracker.shared.trackEvent(with: request)
                    }
                }
            } else {
                NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
            }
        } else {
            let connectionSheet = BHConnectionLostBottomSheet()
            connectionSheet.preferredSheetSizing = .fit
            connectionSheet.panToDismissEnabled = true

            UIApplication.topNavigationController()?.present(connectionSheet, animated: true)
        }
    }

    @IBAction func onShareButton(_ sender: UIButton) {
        guard let validPost = post else { return }
        shareBtnTapClosure?(validPost.shareLink)
        
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .shareEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
        BHTracker.shared.trackEvent(with: request)
    }

    @IBAction func onOptionsButton(_ sender: UIButton) {
        let optionsSheet = BHPostOptionsBottomSheet()
        optionsSheet.post = post
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true

        UIApplication.topNavigationController()?.present(optionsSheet, animated: true)
    }

    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
        
        BHHybridPlayer.shared.addListener(self)
    }
}

extension BHPostCell: BHHybridPlayerListener {
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {
        if let validPost = self.post, validPost.id == item.post.postId {
            DispatchQueue.main.async {
                self.post?.isPlaybackCompleted = completed
                self.playedLabel.isHidden = !completed
            }
        }
    }
}
