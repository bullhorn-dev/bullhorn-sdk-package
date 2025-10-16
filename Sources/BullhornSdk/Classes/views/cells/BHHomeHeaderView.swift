
import Foundation
import UIKit

protocol BHHomeHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHHomeHeaderView, didSelectChannel channel: BHChannel)
    func headerView(_ view: BHHomeHeaderView, didSelectPost post: BHPost)
    func headerView(_ view: BHHomeHeaderView, didSelectUser user: BHUser)
    func headerView(_ view: BHHomeHeaderView, didRequestPlayPost post: BHPost)
    func headerView(_ view: BHHomeHeaderView, didSelectSeeAll section: Sections)
}

class BHHomeHeaderView: UICollectionReusableView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var radioStreamsView: BHRadioStreamsView!
    @IBOutlet weak var scheduledPostsTitle: UIView!
    @IBOutlet weak var scheduledPostsTitleLabel: UILabel!
    @IBOutlet weak var scheduledPostsView: BHPostsCarouselView!
    @IBOutlet weak var livePostsTitle: UIView!
    @IBOutlet weak var livePostsTitleLabel: UILabel!
    @IBOutlet weak var livePostsView: BHLiveCarouselView!
    @IBOutlet weak var followedUsersTitle: UIView!
    @IBOutlet weak var followedUsersTitleLabel: UILabel!
    @IBOutlet weak var seeAllFollowedButton: UIButton!
    @IBOutlet weak var followedUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredUsersTitle: UIView!
    @IBOutlet weak var featuredUsersTitleLabel: UILabel!
    @IBOutlet weak var featuredUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredPostsTitle: UIView!
    @IBOutlet weak var featuredPostsTitleLabel: UILabel!
    @IBOutlet weak var featuredPostsView: BHPagedCarouselView!
    @IBOutlet weak var channelsView: BHChannelsView!
    
    weak var delegate: BHHomeHeaderViewDelegate?

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        seeAllFollowedButton.accessibilityLabel = nil
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return CGSize(width: frame.size.width, height: calculateHeight())
    }
    
    // MARK: - Public
    
    func initialize() {
        radioStreamsView.showLaterStreams = false
    }

    func reloadData() {
        featuredUsersView.users = BHNetworkManager.shared.featuredUsers
        featuredPostsView.posts = BHNetworkManager.shared.featuredPosts
        scheduledPostsView.posts = BHNetworkManager.shared.scheduledPosts
        livePostsView.posts = BHNetworkManager.shared.liveNowPosts
        radioStreamsView.radio = BHRadioStreamsManager.shared.currentRadio
        channelsView.channels = BHNetworkManager.shared.channels
        followedUsersView.users = BHUserManager.shared.followedUsers
        seeAllFollowedButton.isHidden = BHUserManager.shared.followedUsers.count < 6
    }

    func setup() {
        
        scheduledPostsTitleLabel.textColor = .primary()
        scheduledPostsTitleLabel.font = .sectionTitle()
        scheduledPostsTitle.backgroundColor = .primaryBackground()

        livePostsTitleLabel.textColor = .primary()
        livePostsTitleLabel.font = .sectionTitle()
        livePostsTitle.backgroundColor = .primaryBackground()

        featuredUsersTitleLabel.textColor = .primary()
        featuredUsersTitleLabel.font = .sectionTitle()
        featuredPostsTitle.backgroundColor = .primaryBackground()

        featuredPostsTitleLabel.textColor = .primary()
        featuredPostsTitleLabel.font = .sectionTitle()
        featuredUsersTitle.backgroundColor = .primaryBackground()

        followedUsersTitleLabel.textColor = .primary()
        followedUsersTitleLabel.font = .sectionTitle()
        followedUsersTitle.backgroundColor = .primaryBackground()

        featuredUsersView.delegate = self
        featuredUsersView.context = "Featured podcast"
        featuredPostsView.delegate = self
        livePostsView.delegate = self
        scheduledPostsView.delegate = self
        channelsView.delegate = self
        followedUsersView.delegate = self
        followedUsersView.context = "Followed podcast"

        seeAllFollowedButton.titleLabel?.font = .secondaryButton()
        seeAllFollowedButton.backgroundColor = .clear
        seeAllFollowedButton.tintColor = .accent()

        radioStreamsView.isHidden = !hasRadioStreams()
        featuredUsersTitle.isHidden = !hasFeaturedUsers()
        featuredUsersView.isHidden = !hasFeaturedUsers()
        featuredPostsTitle.isHidden = !hasFeaturedPosts()
        featuredPostsView.isHidden = !hasFeaturedPosts()
        scheduledPostsTitle.isHidden = !hasScheduledPosts()
        scheduledPostsView.isHidden = !hasScheduledPosts()
        livePostsTitle.isHidden = !hasLivePosts()
        livePostsView.isHidden = !hasLivePosts()
        followedUsersTitle.isHidden = !hasFollowedUsers()
        followedUsersView.isHidden = !hasFollowedUsers()

        reloadData()
        scrollToSelectedChannel()
    }
    
    func scrollToSelectedChannel() {
        channelsView.moveToChannel(UserDefaults.standard.selectedChannelId)
    }
    
    func calculateHeight() -> CGFloat {
        var totalHeight: CGFloat = 0

        if hasChannels() {
            totalHeight += channelsView.calculateHeight()
        }

        if hasRadioStreams() {
            totalHeight += radioStreamsView.calculateHeight()
        }
            
        if hasFeaturedUsers() {
            totalHeight += featuredUsersView.calculateHeight() + (featuredUsersTitle.frame.size.height > 0 ? featuredUsersTitle.frame.size.height : Constants.panelHeight)
        }
            
        if hasFeaturedPosts() {
            totalHeight += featuredPostsView.calculateHeight() + (featuredPostsTitle.frame.size.height > 0 ? featuredPostsTitle.frame.size.height : Constants.panelHeight)
        }

        if hasScheduledPosts() {
            totalHeight += scheduledPostsView.calculateHeight() + (scheduledPostsTitle.frame.size.height > 0 ? scheduledPostsTitle.frame.size.height : Constants.panelHeight)
        }
            
        if hasLivePosts() {
            totalHeight += livePostsView.calculateHeight() + (livePostsTitle.frame.size.height > 0 ? livePostsTitle.frame.size.height : Constants.panelHeight)
        }
        
        if hasFollowedUsers() {
            totalHeight += followedUsersView.calculateHeight() + (followedUsersTitle.frame.size.height > 0 ? followedUsersTitle.frame.size.height : Constants.panelHeight)
        }

        return totalHeight
    }
    
    // MARK: - Private
    
    fileprivate func hasScheduledPosts() -> Bool {
        return BHNetworkManager.shared.scheduledPosts.count > 0
    }
    
    fileprivate func hasLivePosts() -> Bool {
        return BHNetworkManager.shared.liveNowPosts.count > 0
    }
    
    fileprivate func hasFeaturedPosts() -> Bool {
        return BHNetworkManager.shared.featuredPosts.count > 0
    }
    
    fileprivate func hasFeaturedUsers() -> Bool {
        return BHNetworkManager.shared.featuredUsers.count > 0
    }
    
    fileprivate func hasRadioStreams() -> Bool {
        return BHRadioStreamsManager.shared.hasRadioStreams
    }
    
    fileprivate func hasChannels() -> Bool {
        return BHNetworkManager.shared.channels.count > 0
    }

    fileprivate func hasFollowedUsers() -> Bool {
        return BHUserManager.shared.followedUsers.count > 0 && BullhornSdk.shared.externalUser?.level == .external
    }
    
    // MARK: - Actions
    
    @IBAction func tapFollowedSeeAllButton() {
        delegate?.headerView(self, didSelectSeeAll: .followedUsers)
    }
}

// MARK: - BHChannelsViewDelegate

extension BHHomeHeaderView: BHChannelsViewDelegate {
    
    func channelsView(_ view: BHChannelsView, didMoveToChannel index: Int) {
        let selectedChannel = BHNetworkManager.shared.channels[index]
        delegate?.headerView(self, didSelectChannel: selectedChannel)
    }
}

// MARK: - BHPagedCarouselViewDelegate

extension BHHomeHeaderView : BHPagedCarouselViewDelegate {

    func pagedCarouselView(_ carouselView: BHPagedCarouselView, didMoveToPage index: Int) {
        //
    }
    
    func pagedCarouselView(_ carouselView: BHPagedCarouselView, didSelectPost post: BHPost) {
        delegate?.headerView(self, didSelectPost: post)
    }
}

// MARK: - BHUsersCarouselViewDelegate

extension BHHomeHeaderView: BHUsersCarouselViewDelegate {

    func usersCarouselView(_ view: BHUsersCarouselView, didSelectUser user: BHUser) {
        delegate?.headerView(self, didSelectUser: user)
    }
}

// MARK: - BHPostCarouselViewDelegate

extension BHHomeHeaderView: BHPostCarouselViewDelegate {
    
    func postsCarouselView(_ view: BHPostsCarouselView, didSelectPost post: BHPost) {
        delegate?.headerView(self, didRequestPlayPost: post)
    }
}

// MARK: - BHLiveCarouselViewDelegate

extension BHHomeHeaderView : BHLiveCarouselViewDelegate {

    func liveCarouselView(_ view: BHLiveCarouselView, didMoveToPage index: Int) {}
    
    func liveCarouselView(_ view: BHLiveCarouselView, didSelectPost post: BHPost) {
        delegate?.headerView(self, didSelectPost: post)
    }
}
