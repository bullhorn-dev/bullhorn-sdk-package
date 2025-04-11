
import Foundation
import UIKit

protocol BHPostHeaderViewDelegate: AnyObject {
    func postHeaderView(_ view: BHPostHeaderView, didSelectTabBarItem item: BHPostHeaderView.Tabs)
    func postHeaderView(_ view: BHPostHeaderView, didSelectUser user: BHUser)
    func postHeaderView(_ view: BHPostHeaderView, didSelectShare shareLink: URL)
}

class BHPostHeaderView: UITableViewHeaderFooterView {
    
    enum Tabs: Int {
        case details = 0
        case related
    }
    
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
    @IBOutlet weak var waitingRoomView: UIView!
    @IBOutlet weak var waitingRoomLabel: UILabel!
    @IBOutlet weak var waitingRoomButton: BHWaitingRoomButton!
    @IBOutlet weak var tabbedView: BHTabbedView!
    @IBOutlet weak var tabTitleLabel: UILabel!
    @IBOutlet weak var separatorView1: UIView!
    @IBOutlet weak var separatorView2: UIView!
    @IBOutlet weak var playedLabel: UILabel!

    weak var delegate: BHPostHeaderViewDelegate?

    var postsManager: BHPostsManager?
    
    fileprivate var selectedTab: Tabs = .details

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
        tabTitleLabel.text = selectedTab == .details ? "Episode Description" : "Similar Podcasts"
        
        updateTagLabel()
        updateControls()
    }

    func setup() {
        
        contentView.backgroundColor = .primaryBackground()

        playButton.post = postsManager?.post
        waitingRoomButton.post = postsManager?.post

        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        
        userLabel.textColor = .primary()
        dateLabel.textColor = .secondary()
        titleLabel.textColor = .primary()
        durationLabel.textColor = .primary()
        waitingRoomLabel.textColor = .primary()
        playedLabel.textColor = .primary()
        tabTitleLabel.textColor = .primary()

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .clear
        shareButton.configuration?.baseForegroundColor = .primary()

        separatorView1.addBottomBorder()
        separatorView2.addBottomBorder()
        separatorView1.backgroundColor = .clear
        separatorView2.backgroundColor = .clear

        tabbedView.tabs = [
            BHTabItemView(title: "Details"),
            BHTabItemView(title: "Related")
        ]
        tabbedView.delegate = self
        
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
    }

    fileprivate func updateControls() {
        guard let validPost = postsManager?.post else { return }

        if validPost.isLiveStream() {
            let duration: Double = Double(validPost.recording?.duration ?? 0)

            playerView.isHidden = false
            downloadButton.isHidden = true
            playButton.isHidden = false
            durationLabel.text = duration.stringFormatted()
            durationLabel.isHidden = false
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
        delegate?.postHeaderView(self, didSelectShare: validPost.shareLink)
        
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .shareEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
        BHTracker.shared.trackEvent(with: request)
    }
}

// MARK: - BHTabbedViewDelegate

extension BHPostHeaderView: BHTabbedViewDelegate {
    
    func tabbedView(_ tabbedView: BHTabbedView, didMoveToTab index: Int) {
        selectedTab = Tabs(rawValue: index) ?? .details
        delegate?.postHeaderView(self, didSelectTabBarItem: selectedTab)
    }
}
