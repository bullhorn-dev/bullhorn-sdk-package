
import UIKit
import Foundation
import SDWebImage

class BHExploreViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Explore.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Explore.PostDetailsSegueIdentifier"
    fileprivate static let RecentUsersSegueIdentifier = "Explore.RecentUsersSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var headerView: BHExploreHeaderView?
    fileprivate var footerView: BHListFooterView?
    fileprivate var selectedTab: BHTabs = .podcasts

    fileprivate var searchFieldView: BHSearchFieldView?
    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var skeleton: BHSkeletonView?

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?
    fileprivate var selectedPostTab: BHPostTabs = .details

    fileprivate let exploreManager = BHExploreManager.shared
    
    fileprivate var shouldShowHeader: Bool = false
    fileprivate var isLoadingMore = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        let userCellNib = UINib(nibName: "BHUserCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHExploreHeaderView", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHExploreHeaderView.reusableIndentifer)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: BHListFooterView.reusableIndentifer)
        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.register(userCellNib, forCellReuseIdentifier: BHUserCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHExploreHeaderView.reusableIndentifer) as? BHExploreHeaderView
        headerView?.delegate = self
        
        footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHListFooterView.reusableIndentifer) as? BHListFooterView

        configureSearchField()
        configureRefreshControl()
        configureNavigationItems()

        fetch(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIdChangedNotification(notification:)), name: BullhornSdk.NetworkIdChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onExternalAccountChangedNotification(_:)), name: BullhornSdk.OnExternalAccountChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onContentSizeCategoryChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        exploreManager.addListener(self)
        tableView.reloadData()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .opennSearch)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        exploreManager.removeListener(self)
        refreshControl?.endRefreshing()
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderToFit()
    }
    
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Search", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }

    fileprivate func configureSearchField() {

        /// keep the search results presentation within this view controller
        definesPresentationContext = true

        let field = BHSearchFieldView()
        field.onTap = { [weak self] in
            self?.activateNavigationSearch()
        }
        field.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: searchFieldHeight)
        searchFieldView = field
        tableView.tableHeaderView = field
    }

    fileprivate var searchFieldHeight: CGFloat { return 52.0 }

    /// keep the in-content search field sized to the table width
    fileprivate func sizeTableHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        if header.frame.width != width {
            header.frame.size = CGSize(width: width, height: searchFieldHeight)
            tableView.tableHeaderView = header
        }
    }

    fileprivate func configureRefreshControl() {

        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }

    // MARK: - Network

    fileprivate func fetch(_ isInitial: Bool = false) {
        
        let networkId = BHAppConfiguration.shared.networkId
        
        let completeBlock = {
            self.shouldShowHeader = self.hasHeaderContent()
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.headerView?.reloadData()
            self.skeleton?.dismiss()
            self.skeleton = nil
        }

        if isInitial {
            shouldShowHeader = false
            skeleton = BHSkeletonView.present(over: view, rows: BHSkeletonView.explore())

            exploreManager.fetchStorage(networkId) { response in
                switch response {
                case .success:
                    if self.hasHeaderContent() || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch network from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        exploreManager.fetch(networkId) { response in
            switch response {
            case .success:
                break
            case .failure(error: _):
                if !BHReachabilityManager.shared.isConnected() {
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }

    /// The discovery header is shown whenever it has any content to display.
    fileprivate func hasHeaderContent() -> Bool {
        return BHExploreManager.shared.recentUsers.count > 0
            || BHNetworkManager.shared.featuredUsers.count > 0
            || BHNetworkManager.shared.featuredPosts.count > 0
    }
    
    fileprivate func fetchRecents() {
        exploreManager.fetchRecent(BHAppConfiguration.shared.networkId) { response in
            switch response {
            case .success:
                self.tableView.reloadData()
            case .failure(error: let error):
                BHLog.w(error)
                break
            }
        }
    }

    fileprivate func fetchPosts() {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        if searchActive {
            defaultShowActivityIndicatorView()
        }

        exploreManager.getPosts(BHAppConfiguration.shared.networkId, text: searchController?.searchBar.text) { [weak self] response in
            guard let self else { return }

            self.isLoadingMore = false

            switch response {
            case .success:
                self.tableView.reloadData()
            case .failure(error: _):
                break
            }

            self.defaultHideActivityIndicatorView()
        }
    }

    fileprivate func fetchUsers() {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        if searchActive {
            defaultShowActivityIndicatorView()
        }

        exploreManager.getUsers(BHAppConfiguration.shared.networkId, text: searchController?.searchBar.text) { [weak self] response in
            guard let self else { return }

            self.isLoadingMore = false

            switch response {
            case .success:
                self.tableView.reloadData()
            case .failure(error: _):
                break
            }

            self.defaultHideActivityIndicatorView()
        }
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let context = searchActive ? "search" : nil

        if segue.identifier == BHExploreViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
            vc.context = context
        }
        else if segue.identifier == BHExploreViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = selectedPostTab
            vc.context = context
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHExploreViewController.UserDetailsSegueIdentifier, sender: self)
    }

    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        selectedPostTab = tab
        performSegue(withIdentifier: BHExploreViewController.PostDetailsSegueIdentifier, sender: self)
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onConnectionChangedNotification(notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String : BHReachabilityManager.ConnectionChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHReachabilityManager.NotificationInfoKey] else { return }
        
        switch info.type {
        case .connected, .connectedExpensive:
            tableView.restore()
            fetch(true)
        default:
            break
        }
    }
    
    @objc fileprivate func onNetworkIdChangedNotification(notification: Notification) {
                
        DataBaseManager.shared.dataStack.drop() { error in
            if let validError = error {
                debugPrint("Failed to drop data base: \(validError.debugDescription)")
            }
            
            self.fetch(true)
        }
    }
    
    @objc fileprivate func onExternalAccountChangedNotification(_ notification: Notification) {
        fetch(true)
    }
    
    @objc fileprivate func onContentSizeCategoryChanged(_ notification: Notification) {
        tableView.reloadData()
    }

    // MARK: - Navigation search hooks

    override func searchManagedTableView() -> UITableView? {
        return tableView
    }

    override func performSearch(with text: String) {
        refreshControl?.endRefreshing()

        /// a new search must supersede any in-flight "load more"
        isLoadingMore = false

        switch selectedTab {
        case .podcasts:
            fetchUsers()
        case .episodes:
            fetchPosts()
        }
    }

    override func searchDidBecomeActive() {
        /// hide the in-content field (the real bar is now in the navigation bar),
        /// and switch the header to the Podcasts/Episodes tabs
        tableView.tableHeaderView = nil
        shouldShowHeader = true
        reloadSearchHeader(scrollToTopWhenDone: false)
    }

    override func searchDidResignActive() {
        /// restore the in-content field and the discovery carousels
        tableView.tableHeaderView = searchFieldView
        sizeTableHeaderToFit()
        shouldShowHeader = hasHeaderContent()

        fetchRecents()
        reloadSearchHeader(scrollToTopWhenDone: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHExploreViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if !searchActive {
            return 0
        }
        
        let bundle = Bundle.module
        let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
        
        switch selectedTab {
        case .podcasts:
            if exploreManager.users.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return exploreManager.users.count
        case .episodes:
            if exploreManager.posts.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return exploreManager.posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .podcasts:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHUserCell.reusableIndentifer, for: indexPath) as! BHUserCell
            cell.user = exploreManager.users[indexPath.row]
            return cell
        case .episodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostCell.reusableIndentifer, for: indexPath) as! BHPostCell
            let post = exploreManager.posts[indexPath.row]
            cell.post = post
            cell.playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: exploreManager.posts, order: .straight)
            cell.autoplayContext = .search
            cell.shareBtnTapClosure = { [weak self] url in
                self?.presentShareDialog(with: [url], configureBlock: { controller in
                    controller.popoverPresentationController?.sourceView = cell.shareButton
                })
            }
            cell.transcriptBtnTapClosure = { [weak self] postId in
                self?.openPostDetails(post, tab: .transcript)
            }
            cell.errorClosure = { [weak self] message in
                self?.showError(message)
            }

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(searchActive)
            return headerView
        } else {
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight(searchActive) ?? 88
        } else {
            return .leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        guard searchActive else { return UIView() }

        switch selectedTab {
        case .podcasts:
            if exploreManager.hasMoreUsers {
                footerView?.setup()
                return footerView
            }
        case .episodes:
            if exploreManager.hasMorePosts {
                footerView?.setup()
                return footerView
            }
        }

        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {

        guard searchActive else { return .leastNormalMagnitude }

        switch selectedTab {
        case .podcasts:
            return exploreManager.hasMoreUsers ? 40 : .leastNormalMagnitude
        case .episodes:
            return exploreManager.hasMorePosts ? 40 : .leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch selectedTab {
        case .podcasts:
            openUserDetails(exploreManager.users[indexPath.row])
        case .episodes:
            openPostDetails(exploreManager.posts[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard searchActive, !isLoadingMore else { return }

        switch selectedTab {
        case .podcasts:
            if exploreManager.hasMoreUsers && indexPath.row == exploreManager.users.count - 1 {
                fetchUsers()
            }
        case .episodes:
            if exploreManager.hasMorePosts && indexPath.row == exploreManager.posts.count - 1 {
                fetchPosts()
            }
        }
    }
}

// MARK: - BHExploreManagerListener

extension BHExploreViewController: BHExploreManagerListener {
    
    func exploreManagerDidFetch(_ manager: BHExploreManager) {}
    
    func exploreManagerDidFetchRecent(_ manager: BHExploreManager) {}

    func exploreManagerDidUpdateItems(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: - BHExploreHeaderViewDelegate

extension BHExploreViewController: BHExploreHeaderViewDelegate {
    
    func headerView(_ view: BHExploreHeaderView, didSelectPost post: BHPost) {
        openPostDetails(post)
    }
    
    func headerView(_ view: BHExploreHeaderView, didSelectUser user: BHUser) {
        openUserDetails(user)
    }

    func headerView(_ view: BHExploreHeaderView, didSelectTabBarItem item: BHTabs) {
        guard selectedTab != item else { return }

        selectedTab = item
        isLoadingMore = false

        /// show the spinner before reloading so the empty-state doesn't flash
        defaultShowActivityIndicatorView()
        tableView.reloadData()

        performSearch(with: searchController?.searchBar.text ?? "")
    }
    
    func headerView(_ view: BHExploreHeaderView, didRequestPlayPost post: BHPost) {
        BHLivePlayer.shared.playRequest(with: post)
    }
    
    func headerView(_ view: BHExploreHeaderView, didSelectSeeAll section: Sections) {
        switch section {
        case .recentUsers:
            performSegue(withIdentifier: BHExploreViewController.RecentUsersSegueIdentifier, sender: self)
        default:
            break
        }
    }
}




