
import Foundation
import UIKit

protocol BHUserHeaderViewDelegate: AnyObject {
    func userHeaderViewOnCollapseButtonPressed(_ view: BHUserHeaderView)
    func userHeaderViewOnShareButtonPressed(_ view: BHUserHeaderView, shareLink: URL)
    func userHeaderViewOnLinkButtonPressed(_ view: BHUserHeaderView, websiteLink: URL)
    func userHeaderViewOnFollowButtonPressed(_ view: BHUserHeaderView, user: BHUser)
    func userHeaderViewOnErrorOccured(_ view: BHUserHeaderView, message: String)
}

class BHUserHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var bioView: UIView!
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bioLabel: BHHyperlinkLabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var unfollowButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var socialLinksView: BHSocialLinksView!
    @IBOutlet weak var searchBarView: BHSearchBarView!

    fileprivate var isCollapsed: Bool = BHUserHeaderView.shouldCollapse()
    fileprivate var numberOfLines: Int = 4
    fileprivate var uncollapsedWidth: Int = 300
    
    weak var delegate: BHUserHeaderViewDelegate?

    var userManager: BHUserManager?
    
    var links: [BHSocialLinkItem] = []

    fileprivate var placeholderImage: UIImage?

    static func shouldCollapse() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
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
        followButton.layer.cornerRadius = followButton.frame.size.height / 2
        unfollowButton.layer.cornerRadius = unfollowButton.frame.size.height / 2
        collapseButton.layer.cornerRadius = collapseButton.frame.size.height / 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.shareButton.accessibilityLabel = nil
        self.followButton.accessibilityLabel = nil
        self.unfollowButton.accessibilityLabel = nil
        self.collapseButton.accessibilityLabel = nil
    }
    
    // MARK: - Public
    
    func reloadData() {
        titleLabel.text = userManager?.user?.fullName
        userIcon.sd_setImage(with: userManager?.user?.coverUrl, placeholderImage: placeholderImage)
        categoryLabel.text = userManager?.user?.categoryName
        
        setupBio(with: didTap)
        updateFollowButton()
        setupSocialLinks()
        
        if BHUserHeaderView.shouldCollapse() {
            if let bio = userManager?.user?.bio {
                collapseButton.isHidden = bio.count < uncollapsedWidth
            } else {
                collapseButton.isHidden = true
            }
            updateCollapseButton()
        } else {
            collapseButton.isHidden = true
        }
    }
    
    func calculateHeight(_ searchActive: Bool = false) -> CGFloat {
        if searchActive {
            return searchBarView.frame.size.height
        } else {
            let linksViewHeight = hasSocialLinks() ? socialLinksView.calculateHeight() : 0
            let spacing: CGFloat = 12
            let bio = bioLabel.attributedText?.string ?? ""
            let bioWidth = bio.count < uncollapsedWidth ? frame.size.width - 2 * Constants.paddingHorizontal : frame.size.width - collapseButton.frame.size.width - 2 * Constants.paddingHorizontal

            return 3 * spacing + userView.frame.size.height + heightForView(text: bio, font: bioLabel.font, width: bioWidth) + linksViewHeight + searchBarView.frame.size.height
        }
    }

    func setup(_ searchActive: Bool = false) {
        
        contentView.backgroundColor = .primaryBackground()
        userView.backgroundColor = .primaryBackground()
        
        updateCollapseButton()

        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .secondaryBackground()
        shareButton.configuration?.baseForegroundColor = .primary()

        collapseButton.setTitle("", for: .normal)
        collapseButton.backgroundColor = .secondaryBackground()
        collapseButton.configuration?.baseForegroundColor = .primary()

        followButton.setTitle("Follow", for: .normal)
        followButton.configuration?.image = nil
        followButton.configuration?.imagePadding = 0
        followButton.backgroundColor = .navigationBackground()
        followButton.tintColor = .navigationText()
        followButton.configuration?.baseForegroundColor = .navigationText()
        followButton.titleLabel?.font = .primaryButton()
        followButton.titleLabel?.adjustsFontForContentSizeCategory = true

        let config = UIImage.SymbolConfiguration(scale: .small)
        unfollowButton.setTitle("Following ", for: .normal)
        unfollowButton.setImage(UIImage(systemName: "chevron.down")?.withConfiguration(config), for: .normal)
        unfollowButton.configuration?.imagePlacement = .trailing
        unfollowButton.configuration?.imagePadding = 4.0
        unfollowButton.backgroundColor = .secondaryBackground()
        unfollowButton.tintColor = .primary()
        unfollowButton.configuration?.baseForegroundColor = .primary()
        unfollowButton.titleLabel?.font = .primaryButton()
        unfollowButton.titleLabel?.adjustsFontForContentSizeCategory = true

        updateFollowButton()
        
        titleLabel.textColor = .primary()
        titleLabel.font = .primaryButton()
        titleLabel.adjustsFontForContentSizeCategory = true

        bioLabel.textColor = .primary()
        bioLabel.font = .secondaryText()
        bioLabel.adjustsFontForContentSizeCategory = true

        categoryLabel.textColor = .secondary()
        categoryLabel.font = .secondaryText()
        categoryLabel.adjustsFontForContentSizeCategory = true

        userView.isHidden = searchActive
        bioView.isHidden = searchActive
        socialLinksView.isHidden = searchActive || !hasSocialLinks()
        
        searchBarView.searchBar.placeholder = "Search..."
        searchBarView.mode = searchActive ? .dark : .light
        
        setupAccessibility()
        reloadData()
    }
    
    private func setupAccessibility() {
        shareButton.accessibilityLabel = "Share podcast"
        followButton.accessibilityLabel = "Follow podcast"
        unfollowButton.accessibilityLabel = "Following options"
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func hasWebsite() -> Bool {
        return userManager?.user?.website != nil
    }

    fileprivate func hasSocialLinks() -> Bool {
        return hasWebsite() || userManager?.user?.socialLinks != nil
    }

    fileprivate func heightForView(text: String, font: UIFont, width: CGFloat) -> CGFloat {

        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = numberOfLines
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()

        return label.frame.height
    }
    
    fileprivate func updateCollapseButton() {
        if isCollapsed {
            collapseButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            collapseButton.accessibilityLabel = "Expand podcast details"
            numberOfLines = 5
        } else {
            collapseButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            collapseButton.accessibilityLabel = "Collapse podcast details"
            numberOfLines = 0
        }
    }

    fileprivate func updateFollowButton() {
        guard let user = userManager?.user else { return }

        if user.isFollowed {
            followButton.isHidden = true
            unfollowButton.isHidden = false
        } else {
            followButton.isHidden = false
            unfollowButton.isHidden = true
        }
    }

    fileprivate func setupBio(with tapHandler: @escaping (URL) -> Void) {
        
        let attributedString = NSMutableAttributedString(string: userManager?.user?.bio ?? "")
        let terms: [(URL, NSRange)] = userManager?.user?.bio?.extractURLs() ?? []
        var termsDictionary: [String : (URL, NSRange)] = [:]
        
        for term in terms {
            termsDictionary[term.0.absoluteString] = (url: term.0, range: term.1)
        }

        termsDictionary.enumerated().forEach { index, value in
            let linkAttribute: NSAttributedString.Key = .hyperlink
            let attributes: [NSAttributedString.Key: Any] = [
                linkAttribute: value.1
            ]
            let urlAttributedString = NSAttributedString(string: value.0, attributes: attributes)
            let range = value.1.1
            if (range.location + range.length) < attributedString.length {
                attributedString.replaceCharacters(in: range, with: urlAttributedString)
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        bioLabel.attributedText = attributedString
        bioLabel.didTapOnURL = tapHandler
        bioLabel.textAlignment = .left
    }
    
    fileprivate func setupSocialLinks() {
        
        links.removeAll()

        if hasWebsite() {
            let link = BHSocialLinkItem(title: "Website", url: userManager?.user?.website, image: "ic_website.png")
            links.append(link)
        }

        if let socialLinks = userManager?.user?.socialLinks {
            
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
        
        socialLinksView.delegate = self
        socialLinksView.links = links
    }
    
    // MARK: - Actions

    private func didTap(_ url: URL) {
        delegate?.userHeaderViewOnLinkButtonPressed(self, websiteLink: url)
    }
    
    // MARK: - Actions

    @IBAction func onShareButton(_ sender: UIButton) {
        share()
    }
    
    @IBAction func onFollowButton(_ sender: UIButton) {
        guard let validUser = userManager?.user else { return }

        if validUser.isFollowed {
            let optionsSheet = BHFollowingOptionsBottomSheet()
            optionsSheet.user = validUser
            optionsSheet.preferredSheetSizing = .fit
            optionsSheet.panToDismissEnabled = true
            optionsSheet.notificationsPressedClosure = { [weak self] _ in
                self?.enableUserNotifications(validUser.id, enable: !validUser.receiveNotifications)
            }
            optionsSheet.downloadsPressedClosure = { [weak self] _ in
                self?.enableUserDownloads(validUser.id, enable: !validUser.autoDownload)
            }
            optionsSheet.unfollowPressedClosure = { [weak self] _ in
                self?.unfollow(validUser.id)
            }
            UIApplication.topNavigationController()?.present(optionsSheet, animated: true)
        } else {
            if BullhornSdk.shared.externalUser?.level == .external {
                follow(validUser.id)
            } else {
                NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
            }
        }
    }

    @IBAction func onCollapseButton(_ sender: UIButton) {
        isCollapsed = !isCollapsed
        updateCollapseButton()
        delegate?.userHeaderViewOnCollapseButtonPressed(self)
    }
    
    // MARK: - Private
    
    fileprivate func share() {
        guard let user = userManager?.user else { return }
        guard let shareLink = userManager?.user?.shareLink else { return }

        delegate?.userHeaderViewOnShareButtonPressed(self, shareLink: shareLink)

        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sharePodcast, context: shareLink.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
        BHTracker.shared.trackEvent(with: request)
    }
    
    fileprivate func follow(_ userId: String) {
        BHLog.p("\(#function) - userID: \(userId)")
        
        userManager?.followUser(userId) { response in
            switch response {
            case .success(user: let user):
                DispatchQueue.main.async {
                    self.userManager?.updateFollowedUser(user)
                    self.reloadData()
                    self.delegate?.userHeaderViewOnFollowButtonPressed(self, user: user)
                }
            case .failure(error: let error):
                DispatchQueue.main.async {
                    var message = "Failed to follow podcast. "
                    if BHReachabilityManager.shared.isConnected() {
                        message += error.localizedDescription
                    } else {
                        message += "The Internet connection is lost."
                    }
                    self.delegate?.userHeaderViewOnErrorOccured(self, message: message)
                }
            }
        }
    }
    
    fileprivate func unfollow(_ userId: String) {
        BHLog.p("\(#function) - userID: \(userId)")
        
        userManager?.unfollowUser(userId) { response in
            switch response {
            case .success(user: let user):
                DispatchQueue.main.async {
                    self.userManager?.updateFollowedUser(user)
                    self.reloadData()
                    self.delegate?.userHeaderViewOnFollowButtonPressed(self, user: user)
                }
            case .failure(error: let error):
                DispatchQueue.main.async {
                    var message = "Failed to unfollow podcast. "
                    if BHReachabilityManager.shared.isConnected() {
                        message += error.localizedDescription
                    } else {
                        message += "The Internet connection is lost."
                    }
                    self.delegate?.userHeaderViewOnErrorOccured(self, message: message)
                }
            }
        }
    }
    
    fileprivate func enableUserNotifications(_ userId: String, enable: Bool) {
        BHLog.p("\(#function) - userID: \(userId), enable: \(enable)")
        
        if enable && !UserDefaults.standard.isPushNotificationsEnabled {
            BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
        }

        BHSettingsManager.shared.enableUserNotifications(userId, enable: enable) { response in
            switch response {
            case .success(user: let user):
                BHUserManager.shared.updateUserNotifications(user)
                self.reloadData()
            case .failure(error: let error):
                DispatchQueue.main.async {
                    var message = "Failed to enable podcast notifications. "
                    if BHReachabilityManager.shared.isConnected() {
                        message += error.localizedDescription
                    } else {
                        message += "The Internet connection is lost."
                    }
                    self.delegate?.userHeaderViewOnErrorOccured(self, message: message)
                }
            }
        }
    }
    
    fileprivate func enableUserDownloads(_ userId: String, enable: Bool) {
        BHLog.p("\(#function) - userID: \(userId), enable: \(enable)")
        
        if enable && !UserDefaults.standard.isPushNotificationsEnabled {
            BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
        }

        BHSettingsManager.shared.enableUserDownloads(userId, enable: enable) { response in
            switch response {
            case .success(user: let user):
                BHUserManager.shared.updateUserNotifications(user)
                self.reloadData()
            case .failure(error: let error):
                DispatchQueue.main.async {
                    var message = "Failed to enable podcast auto downloads. "
                    if BHReachabilityManager.shared.isConnected() {
                        message += error.localizedDescription
                    } else {
                        message += "The Internet connection is lost."
                    }
                    self.delegate?.userHeaderViewOnErrorOccured(self, message: message)
                }
            }
        }
    }
}

// MARK: - BHSocialLinksViewDelegate

extension BHUserHeaderView: BHSocialLinksViewDelegate {

    func socialLinksView(_ view: BHSocialLinksView, didSelectLink url: URL?) {
        guard let validUrl = url else { return }
        delegate?.userHeaderViewOnLinkButtonPressed(self, websiteLink: validUrl)
    }
}
