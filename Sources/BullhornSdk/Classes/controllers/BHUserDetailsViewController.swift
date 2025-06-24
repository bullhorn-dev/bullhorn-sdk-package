
import UIKit
import Foundation
import SDWebImage

class BHUserDetailsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let PostDetailsSegueIdentifier = "UserDetailsVC.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var searchController: BHSearchController!
    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var searchActive = false
    fileprivate var hideNavigationBarOnSearchActive = false

    fileprivate var headerView: BHUserHeaderView?
    fileprivate var footerView: BHListFooterView?

    fileprivate var userManager = BHUserManager.shared

    fileprivate var selectedPost: BHPost?
    
    fileprivate var shouldShowHeader: Bool = false

    var user: BHUser? {
        didSet {
            configureNavigationItems()
        }
    }

    var context: String?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHUserHeaderView", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
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

        userManager.addListener(self)

        fetch(initial: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openPodcast, context: user?.shareLink?.absoluteString, podcastId: user?.id, podcastTitle: user?.fullName)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    }
    
    fileprivate func configureRefreshControl() {
        
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    fileprivate func configureSearchController() {
        guard let searchBar = headerView?.searchBarView.searchBar else { return }
        
        searchController = BHSearchController.init(with: searchBar)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
    }

    // MARK: - Network
    
    fileprivate func fetch(initial: Bool = false) {
        guard let u = user else { return }
        
        userManager.clearUserCounters(u)

        let completeBlock = {
            self.shouldShowHeader = self.userManager.posts.count > 0
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
            self.headerView?.reloadData()
            self.configureNavigationItems()
        }

        if initial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()

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
        guard let u = user else { return }

        if searchActive {
            defaultShowActivityIndicatorView()
        }

        userManager.getUserPosts(u.id, text: searchController.searchText) { response in
            switch response {
            case .success:
                self.tableView.reloadData()
            case .failure(error: _):
                break
            }

            self.defaultHideActivityIndicatorView()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == BHUserDetailsViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
        }
    }
    
    // MARK: - Private
    
    override func openPostDetails(_ post: BHPost?) {
        selectedPost = post
        performSegue(withIdentifier: BHUserDetailsViewController.PostDetailsSegueIdentifier, sender: self)
    }

    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
    }

    @objc fileprivate func openOptionsAction(_ sender: Any) {
        let optionsSheet = BHUserOptionsBottomSheet()
        optionsSheet.user = user
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
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHUserDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userManager.posts.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }

        return userManager.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        cell.post = userManager.posts[indexPath.row]
        cell.playlist = userManager.posts
        cell.shareBtnTapClosure = { [weak self] url in
            self?.presentShareDialog(with: [url], configureBlock: { controller in
                controller.popoverPresentationController?.sourceView = cell.shareButton
            })
        }
        cell.errorClosure = { [weak self] message in
            self?.showError(message)
        }

        if userManager.hasMore && indexPath.row == userManager.posts.count - 1 {
            fetchPosts()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(searchActive)
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight(searchActive) ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if userManager.hasMore {
            footerView?.setup()
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return userManager.hasMore ? 40 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(userManager.posts[indexPath.row])
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
        presentSafari(websiteLink)
    }
    
    func userHeaderViewOnShareButtonPressed(_ view: BHUserHeaderView, shareLink: URL) {
        presentShareDialog(with: [shareLink], configureBlock: { controller in
            controller.popoverPresentationController?.sourceView = view.shareButton
        })
    }
    
    func userHeaderViewOnCollapseButtonPressed(_ view: BHUserHeaderView) {
        tableView.reloadData()
    }
}


// MARK: - SearchResultsUpdating

extension BHUserDetailsViewController: BHSearchResultsUpdating {
    
    func updateSearchResults(for searchController: BHSearchController) {
        
        refreshControl?.endRefreshing()
        
        if searchController.searchText.count == 0 || searchController.searchText.count > 2 {
            fetchPosts()
        }
    }
}

// MARK: - SearchControllerDelegate

extension BHUserDetailsViewController: BHSearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: BHSearchController) {
        searchActive = true
        tableView.bounces = false
        tableView.reloadData()
        
        if hideNavigationBarOnSearchActive {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.view.layoutIfNeeded()
        }) { (result) in }
    }
    
    func willDismissSearchController(_ searchController: BHSearchController) {
        searchActive = false
        tableView.bounces = true
        shouldShowHeader = false
        tableView.reloadData()

        if hideNavigationBarOnSearchActive {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.view.layoutIfNeeded()
        }) { (result) in
            self.shouldShowHeader = true
            self.tableView.reloadData()
        }
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
