
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

    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var searchActive = false

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?
    
    fileprivate var shouldShowHeader: Bool = false
    
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

        configureSearchBar()
        configureRefreshControl()
        configureNavigationItems()

        fetch(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIdChangedNotification(notification:)), name: BullhornSdk.NetworkIdChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl?.resetUIState()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutSearchBar()
    }
    
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Search", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }

    fileprivate func configureSearchBar() {

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false

        searchController.searchBar.placeholder = "Search podcasts or episodes"
        searchController.searchBar.delegate = self
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.barStyle = .black
        searchController.searchBar.isTranslucent = false

        configureSearchBarStyle()

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        definesPresentationContext = true
    }
    
    fileprivate func configureSearchBarStyle() {

        searchController.searchBar.backgroundColor = searchActive ? .navigationBackground() : .primaryBackground()
//        searchController.searchBar.barTintColor = .navigationBackground()
        searchController.searchBar.tintColor = .onAccent()
        searchController.searchBar.setPlaceholderTextColor(to: .secondary())
        searchController.searchBar.setMagnifyingGlassColor(to: .secondary())
        searchController.searchBar.setClearButtonColor(to: .tertiary())
        
        searchController.searchBar.searchTextField.font = .fontWithName(.robotoRegular, size: 14)
        searchController.searchBar.searchTextField.textColor = .primary()
        searchController.searchBar.searchTextField.tintColor = .accent()
        searchController.searchBar.searchTextField.borderStyle = .roundedRect
        searchController.searchBar.searchTextField.layer.cornerRadius = 18
        searchController.searchBar.searchTextField.backgroundColor = .cardBackground()
        searchController.searchBar.searchTextField.clipsToBounds = true
    }

    fileprivate func configureRefreshControl() {
        
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    fileprivate func layoutSearchBar() {
        let tf = searchController.searchBar.searchTextField.frame
        let y: CGFloat = searchActive ? tf.origin.y : 12.0

        searchController.searchBar.searchTextField.frame = CGRect(origin: CGPoint(x: tf.origin.x, y: y), size: tf.size)
        searchController.view.layoutSubviews()
    }

    // MARK: - Network

    fileprivate func fetch(_ isInitial: Bool = false) {
        
        let networkId = BHAppConfiguration.shared.networkId
        
        let completeBlock = {
            self.shouldShowHeader = BHNetworkManager.shared.featuredUsers.count > 0
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
            self.headerView?.reloadData()
        }

        if isInitial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()

            BHExploreManager.shared.fetchStorage(networkId) { response in
                switch response {
                case .success:
                    let showHeader = BHNetworkManager.shared.featuredUsers.count > 0
                    if showHeader || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch network from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        BHExploreManager.shared.fetch(networkId) { response in
            switch response {
            case .success:
                break
            case .failure(error: _):
                if !BHReachabilityManager.shared.isConnected() {
                    self.showError("The Internet connection appears to be offline")
                }
            }
            completeBlock()
        }
    }
    
    fileprivate func fetchRecents() {
        BHExploreManager.shared.getRecentUsers(BHAppConfiguration.shared.networkId, isFirstPage: true) { response in
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

        if searchActive {
            defaultShowActivityIndicatorView()
        }

        BHExploreManager.shared.getPosts(BHAppConfiguration.shared.networkId, text: searchController.searchBar.text) { response in
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

        if searchActive {
            defaultShowActivityIndicatorView()
        }

        BHExploreManager.shared.getUsers(BHAppConfiguration.shared.networkId, text: searchController.searchBar.text) { response in
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
            vc.context = context
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHExploreViewController.UserDetailsSegueIdentifier, sender: self)
    }

    override func openPostDetails(_ post: BHPost?) {
        selectedPost = post
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
            if BHExploreManager.shared.users.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return BHExploreManager.shared.users.count
        case .episodes:
            if BHExploreManager.shared.posts.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return BHExploreManager.shared.posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .podcasts:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHUserCell.reusableIndentifer, for: indexPath) as! BHUserCell
            cell.user = BHExploreManager.shared.users[indexPath.row]

            if BHExploreManager.shared.hasMoreUsers && indexPath.row == BHExploreManager.shared.users.count - 1 {
                fetchUsers()
            }

            return cell
        case .episodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostCell.reusableIndentifer, for: indexPath) as! BHPostCell
            cell.post = BHExploreManager.shared.posts[indexPath.row]
            cell.playlist = BHExploreManager.shared.posts
            cell.shareBtnTapClosure = { [weak self] url in
                self?.presentShareDialog(with: [url], configureBlock: { controller in
                    controller.popoverPresentationController?.sourceView = cell.shareButton
                })
            }
            
            if BHExploreManager.shared.hasMorePosts && indexPath.row == BHExploreManager.shared.posts.count - 1 {
                fetchPosts()
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(searchActive)
            return headerView
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight(searchActive) ?? 88
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        if !searchActive {
            return nil
        }

        switch selectedTab {
        case .podcasts:
            if BHExploreManager.shared.hasMoreUsers {
                footerView?.setup()
                return footerView
            }
        case .episodes:
            if BHExploreManager.shared.hasMorePosts {
                footerView?.setup()
                return footerView
            }
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if !searchActive {
            return 0
        }
        
        switch selectedTab {
        case .podcasts:
            return BHExploreManager.shared.hasMoreUsers ? 40 : 0
        case .episodes:
            return BHExploreManager.shared.hasMorePosts ? 40 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch selectedTab {
        case .podcasts:
            openUserDetails(BHExploreManager.shared.users[indexPath.row])
        case .episodes:
            openPostDetails(BHExploreManager.shared.posts[indexPath.row])
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
        selectedTab = item
        tableView.reloadData()
        
        switch selectedTab {
        case .podcasts:
            fetchUsers()
        case .episodes:
            fetchPosts()
        }
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

// MARK: - UISearchResultsUpdating

extension BHExploreViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        refreshControl?.endRefreshing()
        
        let searchText: String = searchController.searchBar.text ?? ""
        
        if searchText.isEmpty || searchText.count > 2 {
            switch selectedTab {
            case .podcasts:
                fetchUsers()
            case .episodes:
                fetchPosts()
            }
        }
    }
}

extension BHExploreViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchController.searchResultsUpdater?.updateSearchResults(for: searchController)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.searchResultsUpdater?.updateSearchResults(for: searchController)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchActive = true
        configureSearchBarStyle()
        tableView.reloadData()
        
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

        searchActive = false
        shouldShowHeader = true
        
//        if (selectedTab == .podcasts && BHExploreManager.shared.users.count > 0) ||
//            (selectedTab == .episodes && BHExploreManager.shared.posts.count > 0) {
//            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
//        }
        tableView.reloadData()

        searchController.searchResultsUpdater?.updateSearchResults(for: searchController)
        
        fetchRecents()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.layoutSearchBar()
            self.configureSearchBarStyle()
        }
    }
}


