
import Foundation
import UIKit

protocol BHHomeHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHHomeHeaderView, didSelectTabBarItem item: BHTabs)
    func headerView(_ view: BHHomeHeaderView, didSelectPost post: BHPost)
    func headerView(_ view: BHHomeHeaderView, didSelectUser user: BHUser)
    func headerView(_ view: BHHomeHeaderView, didRequestPlayPost post: BHPost)
}

class BHHomeHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var radioStreamsView: BHRadioStreamsView!
    @IBOutlet weak var scheduledPostsTitle: UIView!
    @IBOutlet weak var scheduledPostsView: BHPostsCarouselView!
    @IBOutlet weak var livePostsTitle: UIView!
    @IBOutlet weak var livePostsView: BHPostsCarouselView!
    @IBOutlet weak var featuredUsersTitle: UIView!
    @IBOutlet weak var featuredUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredPostsTitle: UIView!
    @IBOutlet weak var featuredPostsView: BHPagedCarouselView!
    @IBOutlet weak var tabbedView: BHTabbedView!
    
    weak var delegate: BHHomeHeaderViewDelegate?
    
    fileprivate var selectedTab: BHTabs = .podcasts

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
    }

    func setup(_ hasRadioStreams: Bool = true) {
        
        contentView.backgroundColor = .primaryBackground()
        
        featuredUsersView.delegate = self
        featuredPostsView.delegate = self
        livePostsView.delegate = self
        scheduledPostsView.delegate = self
        
        tabbedView.tabs = [
            BHTabItemView(title: "Podcasts"),
            BHTabItemView(title: "Episodes")
        ]
        tabbedView.delegate = self
                
        radioStreamsView.isHidden = !hasRadioStreams
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
    
    func calculateHeight(_ hasRadioStreams: Bool = true) -> CGFloat {
        var totalHeight: CGFloat = tabbedView.frame.size.height

        if hasRadioStreams {
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
}

// MARK: - BHTabbedViewDelegate

extension BHHomeHeaderView: BHTabbedViewDelegate {
    
    func tabbedView(_ tabbedView: BHTabbedView, didMoveToTab index: Int) {
        selectedTab = BHTabs(rawValue: index) ?? .podcasts
        delegate?.headerView(self, didSelectTabBarItem: selectedTab)
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
