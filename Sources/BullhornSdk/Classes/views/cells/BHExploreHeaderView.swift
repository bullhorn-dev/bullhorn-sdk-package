
import UIKit
import Foundation

enum BHTabs: Int {
    case podcasts = 0
    case episodes
}

enum Sections {
    case recentUsers
    case featuredUsers
    case featuredPosts
    case followedUsers
}

protocol BHExploreHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHExploreHeaderView, didSelectTabBarItem item: BHTabs)
    func headerView(_ view: BHExploreHeaderView, didSelectPost post: BHPost)
    func headerView(_ view: BHExploreHeaderView, didSelectUser user: BHUser)
    func headerView(_ view: BHExploreHeaderView, didRequestPlayPost post: BHPost)
    func headerView(_ view: BHExploreHeaderView, didSelectSeeAll section: Sections)
}

class BHExploreHeaderView: UITableViewHeaderFooterView {
        
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var recentUsersTitle: UIView!
    @IBOutlet weak var recentUsersTitleLabel: UILabel!
    @IBOutlet weak var seeAllRecentsButton: UIButton!
    @IBOutlet weak var recentUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredUsersTitle: UIView!
    @IBOutlet weak var featuredUsersTitleLabel: UILabel!
    @IBOutlet weak var featuredUsersView: BHUsersCarouselView!
    @IBOutlet weak var featuredPostsTitle: UIView!
    @IBOutlet weak var featuredPostsTitleLabel: UILabel!
    @IBOutlet weak var featuredPostsView: BHPagedCarouselView!
    @IBOutlet weak var tabbedView: BHTabbedView!
    
    weak var delegate: BHExploreHeaderViewDelegate?
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        seeAllRecentsButton.accessibilityLabel = nil
    }
    
    // MARK: - Public
    
    func reloadData() {
        recentUsersView.users = BHExploreManager.shared.recentUsers
        featuredUsersView.users = BHNetworkManager.shared.featuredUsers
        featuredPostsView.posts = BHNetworkManager.shared.featuredPosts
        seeAllRecentsButton.isHidden = BHExploreManager.shared.recentUsers.count < 6
    }

    func setup(_ searchActive: Bool) {
        
        contentView.backgroundColor = .primaryBackground()

        recentUsersView.delegate = self
        featuredUsersView.delegate = self
        featuredPostsView.delegate = self

        recentUsersTitleLabel.textColor = .primary()
        recentUsersTitleLabel.font = .sectionTitle()

        featuredUsersTitleLabel.textColor = .primary()
        featuredUsersTitleLabel.font = .sectionTitle()

        featuredPostsTitleLabel.textColor = .primary()
        featuredPostsTitleLabel.font = .sectionTitle()

        seeAllRecentsButton.titleLabel?.font = .secondaryButton()
        seeAllRecentsButton.backgroundColor = .clear
        seeAllRecentsButton.tintColor = .accent()
        
        tabbedView.tabs = [
            BHTabItemView(title: "Podcasts"),
            BHTabItemView(title: "Episodes")
        ]
        tabbedView.delegate = self
                
        if searchActive {
            recentUsersTitle.isHidden = true
            recentUsersView.isHidden = true
            featuredUsersTitle.isHidden = true
            featuredUsersView.isHidden = true
            featuredPostsTitle.isHidden = true
            featuredPostsView.isHidden = true
            tabbedView.isHidden = false
        } else {
            recentUsersTitle.isHidden = !hasRecentUsers()
            recentUsersView.isHidden = !hasRecentUsers()
            featuredUsersTitle.isHidden = !hasFeaturedUsers()
            featuredUsersView.isHidden = !hasFeaturedUsers()
            featuredPostsTitle.isHidden = !hasFeaturedPosts()
            featuredPostsView.isHidden = !hasFeaturedPosts()
            tabbedView.isHidden = true
        }
        
        reloadData()
    }
    
    func calculateHeight(_ searchActive: Bool = false) -> CGFloat {
        var totalHeight: CGFloat = 0

        if searchActive {
            return tabbedView.frame.size.height > 0 ? tabbedView.frame.size.height : Constants.panelHeight
        } else {
            if hasRecentUsers() {
                totalHeight += recentUsersView.calculateHeight() + (recentUsersTitle.frame.size.height > 0 ? recentUsersTitle.frame.size.height : Constants.panelHeight)
            }
            if hasFeaturedUsers() {
                totalHeight += featuredUsersView.calculateHeight() + (featuredUsersTitle.frame.size.height > 0 ? featuredUsersTitle.frame.size.height : Constants.panelHeight)
            }
            if hasFeaturedPosts() {
                totalHeight += featuredPostsView.calculateHeight() + (featuredPostsTitle.frame.size.height > 0 ? featuredPostsTitle.frame.size.height : Constants.panelHeight)
            }

            return totalHeight
        }
    }
    
    // MARK: - Private

    fileprivate func hasRecentUsers() -> Bool {
        return BHExploreManager.shared.recentUsers.count > 0
    }

    fileprivate func hasFeaturedPosts() -> Bool {
        return BHNetworkManager.shared.featuredPosts.count > 0
    }
    
    fileprivate func hasFeaturedUsers() -> Bool {
        return BHNetworkManager.shared.featuredUsers.count > 0
    }
    
    // MARK: - Actions
    
    @IBAction func tapRecentsSeeAllButton() {
        delegate?.headerView(self, didSelectSeeAll: .recentUsers)
    }
}

// MARK: - BHTabbedViewDelegate

extension BHExploreHeaderView: BHTabbedViewDelegate {
    
    func tabbedView(_ tabbedView: BHTabbedView, didMoveToTab index: Int) {
        selectedTab = BHTabs(rawValue: index) ?? .podcasts
        delegate?.headerView(self, didSelectTabBarItem: selectedTab)
    }
}

// MARK: - BHPagedCarouselViewDelegate

extension BHExploreHeaderView : BHPagedCarouselViewDelegate {

    func pagedCarouselView(_ carouselView: BHPagedCarouselView, didMoveToPage index: Int) {
        //
    }
    
    func pagedCarouselView(_ carouselView: BHPagedCarouselView, didSelectPost post: BHPost) {
        delegate?.headerView(self, didSelectPost: post)
    }
}

// MARK: - BHUsersCarouselViewDelegate

extension BHExploreHeaderView: BHUsersCarouselViewDelegate {

    func usersCarouselView(_ view: BHUsersCarouselView, didSelectUser user: BHUser) {
        delegate?.headerView(self, didSelectUser: user)
    }
}

// MARK: - BHPostCarouselViewDelegate

extension BHExploreHeaderView: BHPostCarouselViewDelegate {
    
    func postsCarouselView(_ view: BHPostsCarouselView, didSelectPost post: BHPost) {
        delegate?.headerView(self, didRequestPlayPost: post)
    }
}

