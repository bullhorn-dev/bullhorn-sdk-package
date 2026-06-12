
import UIKit
import Foundation
import SDWebImage

class BHUserDetailsViewController: BHPlayerContainingViewController {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let PostDetailsSegueIdentifier = "UserDetailsVC.PostDetailsSegueIdentifier"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var skeleton: BHSkeletonView?

    fileprivate var isLoadingMore = false

    fileprivate var headerView: BHUserHeaderView?
    fileprivate var footerView: BHListFooterView?

    fileprivate var userManager = BHUserManager()

    fileprivate var selectedPost: BHPost?
    fileprivate var selectedTab: BHPostTabs = .details

    fileprivate var shouldShowHeader: Bool = false

    var user: BHUser? {
        didSet {
            configureNavigationItems()
        }
    }

    var context: String?
    var openedFromPostId: String?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomView.backgroundColor = .primaryBackground()
        
        let bundle = Bundle.module
        let headerNib = UINib(nibName: "BHUserHeaderView", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(BHPostCell.self, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHUserHeaderView.reusableIndentifer)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: BHListFooterView.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHUserHeaderView.reusableIndentifer) as? BHUserHeaderView
        headerView?.delegate = self
        headerView?.userManager = userManager
        
        footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHListFooterView.reusableIndentifer) as? BHListFooterView

        configureNavigationItems()
        configureRefreshControl()
        configureSearchController()

        fetch(initial: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPostChangedNotification(notification:)), name: BHPostsManager.PostChangedNotification, object: nil)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openPodcast, context: context, podcastId: user?.id, podcastTitle: user?.fullName)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        userManager.addListener(self)
        tableView.reloadData()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        refreshControl?.endRefreshing()
        userManager.removeListener(self)

        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = NSLocalizedString("Podcast Details", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis")?.withConfiguration(config), style: .plain, target: self, action: #selector(openOptionsAction(_:)))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "More Options"

        navigationItem.backButtonTitle = ""
        navigationItem.backBarButtonItem?.accessibilityLabel = "Back"
    }
    
    fileprivate func configureRefreshControl() {
        
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    fileprivate func configureSearchController() {
        /// keep the search results presentation within this view controller
        definesPresentationContext = true
    }

    // MARK: - Network
    
    fileprivate func fetch(initial: Bool = false) {
        guard let u = user else { return }
        
        userManager.clearUserCounters(u)

        let completeBlock = {
            self.shouldShowHeader = self.userManager.posts.count > 0 || BHReachabilityManager.shared.isConnected()
            self.refreshControl?.endRefreshing()
            self.skeleton?.dismiss()
            self.skeleton = nil
            self.tableView.reloadData()
            self.headerView?.reloadData()
            self.configureNavigationItems()
        }

        if initial {
            shouldShowHeader = false
            skeleton = BHSkeletonView.present(over: view, rows: BHSkeletonView.userDetails())

            userManager.fetchStorage(u.id) { response in
                switch response {
                case .success:
                    if self.userManager.posts.count > 0 || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch user details from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        userManager.fetch(u.id, context: context) { response in
            switch response {
            case .success:
                BHNotificationsManager.shared.removeDeliveredNotifications(with: u.id)
            case .failure(error: let error):
                if BHReachabilityManager.shared.isConnected() {
                    self.showError("Failed to fetch user details from backend. \(error.localizedDescription)")
                } else if !initial {
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }
    
    fileprivate func fetchPosts() {
        guard let u = user, !isLoadingMore else { return }

        isLoadingMore = true

        userManager.getUserPosts(u.id, text: searchController?.searchBar.text) { [weak self] response in
            guard let self else { return }

            self.isLoadingMore = false
            self.setSearchBarLoading(false)

            switch response {
            case .success:
                self.tableView.reloadData()
            case .failure(error: _):
                break
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == BHUserDetailsViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = selectedTab
            vc.openedFromUserId = user?.id
        }
    }
    
    // MARK: - Private
    
    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        guard let validPost = post else { return }
        
        if let validOpenedFromPostId = openedFromPostId, validOpenedFromPostId == validPost.id {
            UIApplication.topNavigationController()?.popViewController(animated: true)
        } else {
            selectedPost = post
            selectedTab = tab
            performSegue(withIdentifier: BHUserDetailsViewController.PostDetailsSegueIdentifier, sender: self)
        }
    }

    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
    }

    @objc fileprivate func openOptionsAction(_ sender: Any) {
        let optionsSheet = BHUserOptionsBottomSheet()
        optionsSheet.user = userManager.user
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true
        present(optionsSheet, animated: true)
    }

    // MARK: - Notifications
    
    @objc fileprivate func onConnectionChangedNotification(notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String : BHReachabilityManager.ConnectionChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHReachabilityManager.NotificationInfoKey] else { return }
        
        switch info.type {
        case .connected, .connectedExpensive:
            tableView.restore()
            fetch(initial: true)
        default:
            break
        }
    }
    
    @objc fileprivate func onPostChangedNotification(notification: Notification) {

        guard let notificationInfo = notification.userInfo as? [String : BHPostsManager.PostChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHPostsManager.NotificationInfoKey] else { return }
        guard let post = info.post else { return }

        switch info.reason {
        case .like, .unlike:
            /// updatePost notifies the listener, which reloads the table
            userManager.updatePost(post)
        default:
            break
        }
    }

    // MARK: - Navigation search hooks

    override func searchManagedTableView() -> UITableView? {
        return tableView
    }

    override func hasExistingSearchResults() -> Bool {
        return !userManager.posts.isEmpty
    }

    override func performSearch(with text: String) {
        refreshControl?.endRefreshing()

        /// a new search must supersede any in-flight "load more"
        isLoadingMore = false

        /// show the loading spinner in the search bar (pagination uses the footer)
        setSearchBarLoading(true)
        fetchPosts()

        /// drop any stale "Nothing to show" while the new query loads
        tableView.reloadData()
    }

    override func searchDidBecomeActive() {
        /// hide the big header; the real search bar now lives in the navigation bar
        reloadSearchHeader(scrollToTopWhenDone: false)
    }

    override func searchDidResignActive() {
        /// restore the header, then scroll to top so it becomes visible again
        reloadSearchHeader(scrollToTopWhenDone: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHUserDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userManager.posts.count == 0 && !isLoadingMore && skeleton == nil {
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
            tableView.setEmptyMessage(message, image: nil, topOffset: 30)
        } else {
            tableView.restore()
        }

        return userManager.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        let post = userManager.posts[indexPath.row]
        cell.post = post
        cell.playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: userManager.posts, order: .straightAndReversed)
        cell.autoplayContext = .podcast
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard shouldShowHeader, !searchActive else { return UIView() }
        headerView?.setup()
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard shouldShowHeader, !searchActive else { return .leastNormalMagnitude }
        return headerView?.calculateHeight() ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if userManager.hasMore {
            footerView?.setup()
            return footerView
        }
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return userManager.hasMore ? 40 : .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(userManager.posts[indexPath.row])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard userManager.hasMore, !isLoadingMore else { return }
        if indexPath.row == userManager.posts.count - 1 {
            fetchPosts()
        }
    }
}

// MARK: - BHUserHeaderViewDelegate

extension BHUserDetailsViewController: BHUserHeaderViewDelegate {

    func userHeaderViewOnFollowButtonPressed(_ view: BHUserHeaderView, user: BHUser) {
        self.user?.outgoingStatus = user.outgoingStatus
    }
    
    func userHeaderViewOnErrorOccured(_ view: BHUserHeaderView, message: String) {
        showError(message)
    }
    
    func userHeaderViewOnLinkButtonPressed(_ view: BHUserHeaderView, websiteLink: URL) {
        openExternalLink(websiteLink)
    }
    
    func userHeaderViewOnShareButtonPressed(_ view: BHUserHeaderView, shareLink: URL) {
        presentShareDialog(with: [shareLink], configureBlock: { controller in
            controller.popoverPresentationController?.sourceView = view.shareButton
        })
    }
    
    func userHeaderViewOnCollapseButtonPressed(_ view: BHUserHeaderView) {
        tableView.reloadData()
    }

    func userHeaderViewOnSearchTapped(_ view: BHUserHeaderView) {
        activateNavigationSearch()
    }
}


// MARK: - BHUserManagerListener

extension BHUserDetailsViewController: BHUserManagerListener {

    func userManagerDidUpdateFollowedUsers(_ manager: BHUserManager) {}
    
    func userManagerDidFetchPosts(_ manager: BHUserManager) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func userManagerDidUpdatePosts(_ manager: BHUserManager) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

