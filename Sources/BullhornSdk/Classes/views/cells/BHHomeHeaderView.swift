
import Foundation
import UIKit

protocol BHHomeHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHHomeHeaderView, didSelectChannel channel: BHChannel)
    func headerView(_ view: BHHomeHeaderView, didSelectPost post: BHPost)
    func headerView(_ view: BHHomeHeaderView, didSelectUser user: BHUser)
    func headerView(_ view: BHHomeHeaderView, didRequestPlayPost post: BHPost)
}

class BHHomeHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var radioStreamsView: BHRadioStreamsView!
    @IBOutlet weak var scheduledPostsTitle: UIView!
    @IBOutlet weak var scheduledPostsTitleLabel: UILabel!
    @IBOutlet weak var scheduledPostsView: BHPostsCarouselView!
    @IBOutlet weak var livePostsTitle: UIView!
    @IBOutlet weak var livePostsTitleLabel: UILabel!
    @IBOutlet weak var livePostsView: BHPostsCarouselView!
    @IBOutlet weak var featuredUsersTitle: UIView!
    @IBOutlet weak var featuredUsersTitleLabel: UILabel!
    @IBOutlet weak var featuredUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredPostsTitle: UIView!
    @IBOutlet weak var featuredPostsTitleLabel: UILabel!
    @IBOutlet weak var featuredPostsView: BHPagedCarouselView!
    @IBOutlet weak var channelsView: BHChannelsView!
    
    weak var delegate: BHHomeHeaderViewDelegate?

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    }

    func setup() {
        
        contentView.backgroundColor = .primaryBackground()
        
        scheduledPostsTitleLabel.textColor = .primary()
        livePostsTitleLabel.textColor = .primary()
        featuredUsersTitleLabel.textColor = .primary()
        featuredPostsTitleLabel.textColor = .primary()
        
        featuredUsersView.delegate = self
        featuredPostsView.delegate = self
        livePostsView.delegate = self
        scheduledPostsView.delegate = self
        
        channelsView.delegate = self
                
        radioStreamsView.isHidden = !hasRadioStreams()
        featuredUsersTitle.isHidden = !hasFeaturedUsers()
        featuredUsersView.isHidden = !hasFeaturedUsers()
        featuredPostsTitle.isHidden = !hasFeaturedPosts()
        featuredPostsView.isHidden = !hasFeaturedPosts()
        scheduledPostsTitle.isHidden = !hasScheduledPosts()
        scheduledPostsView.isHidden = !hasScheduledPosts()
        livePostsTitle.isHidden = !hasLivePosts()
        livePostsView.isHidden = !hasLivePosts()
        
        reloadData()
    }
    
    func calculateHeight() -> CGFloat {
        var totalHeight: CGFloat = 0

        if hasChannels() {
            totalHeight += channelsView.frame.size.height
        }

        if hasRadioStreams() {
            totalHeight += radioStreamsView.calculateHeight()
        }
            
        if hasFeaturedUsers() {
            totalHeight += featuredUsersTitle.frame.size.height + featuredUsersView.frame.size.height
        }
            
        if hasFeaturedPosts() {
            totalHeight += featuredPostsTitle.frame.size.height + featuredPostsView.frame.size.height
        }

        if hasScheduledPosts() {
            totalHeight += scheduledPostsTitle.frame.size.height + scheduledPostsView.frame.size.height
        }
            
        if hasLivePosts() {
                totalHeight += livePostsTitle.frame.size.height + livePostsView.frame.size.height
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
