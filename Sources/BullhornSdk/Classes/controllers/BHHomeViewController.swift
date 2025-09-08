
import UIKit
import Foundation
import SDWebImage

class BHHomeViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Home.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Home.PostDetailsSegueIdentifier"
    fileprivate static let FollowedPodcastsSegueIdentifier = "Home.FollowedPodcastsSegueIdentifier"
    fileprivate static let NotificationsSegueIdentifier = "Home.NotificationsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var headerView: BHHomeHeaderView?

    fileprivate var selectedChannelId: String = UserDefaults.standard.selectedChannelId

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?
        
    fileprivate var shouldShowHeader: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let gridCellNib = UINib(nibName: "BHUsersGridCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHHomeHeaderView", bundle: bundle)

        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHHomeHeaderView.reusableIndentifer)
        tableView.register(gridCellNib, forCellReuseIdentifier: BHUsersGridCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHHomeHeaderView.reusableIndentifer) as? BHHomeHeaderView
        headerView?.initialize()
        headerView?.delegate = self

        configureNavigationItems()
        configureRefreshControl()

        fetch(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIdChangedNotification(notification:)), name: BullhornSdk.NetworkIdChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(notification:)), name: BHAccountManager.AccountChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onExternalAccountChangedNotification(_:)), name: BullhornSdk.OnExternalAccountChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
        configureNavigationItems()

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openHome)
        BHTracker.shared.trackEvent(with: request)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {

        navigationItem.title = NSLocalizedString("Home", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        if UserDefaults.standard.isDevModeEnabled {
            let config = UIImage.SymbolConfiguration(weight: .light)
            let imageName = BHUserManager.shared.newEpisodesUsers.count > 0 ? "bell.badge" : "bell"
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: imageName)?.withConfiguration(config), style: .plain, target: self, action: #selector(notificationsButtonAction(_:)))
            navigationItem.rightBarButtonItem?.accessibilityLabel = "Notifications"
        } else {
            navigationItem.rightBarButtonItem = nil
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
            self.shouldShowHeader = BHNetworkManager.shared.featuredPosts.count > 0 && BHNetworkManager.shared.users.count > 0
            self.refreshControl?.endRefreshing()
            self.reloadData()
            self.headerView?.reloadData()
            self.configureNavigationItems()
        }

        if isInitial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()

            BHNetworkManager.shared.fetchStorage(networkId) { response in
                switch response {
                case .success:
                    let showHeader = self.headerView != nil
                    if showHeader || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                    if BHNetworkManager.shared.users.count > 0 {
                        self.defaultHideActivityIndicatorView()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch network from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        BHNetworkManager.shared.fetch(networkId) { response in
            switch response {
            case .success:
                BHDownloadsManager.shared.autoDownloadNewEpisodesIfNeeded()
            case .failure(error: _):
                if !BHReachabilityManager.shared.isConnected() {
                    self.showConnectionError()
                }
            }
            self.defaultHideActivityIndicatorView()
            completeBlock()
        }
    }
        
    fileprivate func reloadData() {
        BHNetworkManager.shared.splitUsers(selectedChannelId)
        tableView.reloadData()
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch()
    }
    
    @objc fileprivate func notificationsButtonAction(_ sender: Any) {
        openNotifications()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == BHHomeViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        }
        else if segue.identifier == BHHomeViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHHomeViewController.UserDetailsSegueIdentifier, sender: self)
    }

    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        performSegue(withIdentifier: BHHomeViewController.PostDetailsSegueIdentifier, sender: self)
    }

    private func openFollowedPodcasts() {
        performSegue(withIdentifier: BHHomeViewController.FollowedPodcastsSegueIdentifier, sender: self)
    }

    private func openNotifications() {
        performSegue(withIdentifier: BHHomeViewController.NotificationsSegueIdentifier, sender: self)
    }

    // MARK: - Notifications
    
    @objc fileprivate func onConnectionChangedNotification(notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String : BHReachabilityManager.ConnectionChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHReachabilityManager.NotificationInfoKey] else { return }
        
        switch info.type {
        case .connected, .connectedExpensive:
            tableView.restore()
            fetch()
        default:
            break
        }
    }
    
    @objc fileprivate func onNetworkIdChangedNotification(notification: Notification) {
        BHLog.p("\(#function)")
        
        BHHybridPlayer.shared.close()
        BHLivePlayer.shared.close()
        BHDownloadsManager.shared.removeAll()
        
        DataBaseManager.shared.dataStack.drop() { error in
            if let validError = error {
                debugPrint("Failed to drop data base: \(validError.debugDescription)")
            }
            
            self.fetch(true)
        }
    }
    
    @objc fileprivate func onAccountChangedNotification(notification: Notification) {

        guard let notificationInfo = notification.userInfo as? [String : BHAccountManager.AccountChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHAccountManager.NotificationInfoKey] else { return }

        switch info.reason {
        case .login:
            fetch(true)
        default:
            break
        }
    }
    
    @objc fileprivate func onExternalAccountChangedNotification(_ notification: Notification) {
        fetch(true)
    }

    @objc private func onApplicationDidBecomeActive(_ notification: Notification) {
        headerView?.scrollToSelectedChannel()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHNetworkManager.shared.splittedUsers.count == 0 && !activityIndicator.isAnimating {
            let image = UIImage(named: "ic_list_placeholder.png", in: Bundle.module, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }
        return BHNetworkManager.shared.splittedUsers.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHUsersGridCell.reusableIndentifer, for: indexPath) as! BHUsersGridCell
        cell.collectionViewController.uiModels = BHNetworkManager.shared.splittedUsers
        cell.collectionViewController.delegate = self

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup()
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight() ?? 0
        }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - BHHomeHeaderViewDelegate

extension BHHomeViewController: BHHomeHeaderViewDelegate {

    func headerView(_ view: BHHomeHeaderView, didSelectSeeAll section: Sections) {
        switch section {
        case .followedUsers:
            openFollowedPodcasts()
        default:
            break
        }
    }

    func headerView(_ view: BHHomeHeaderView, didSelectPost post: BHPost) {
        openPostDetails(post)
    }
    
    func headerView(_ view: BHHomeHeaderView, didSelectUser user: BHUser) {
        openUserDetails(user)
    }

    func headerView(_ view: BHHomeHeaderView, didSelectChannel channel: BHChannel) {
        selectedChannelId = channel.id
        reloadData()
    }
    
    func headerView(_ view: BHHomeHeaderView, didRequestPlayPost post: BHPost) {
        if post.isLiveStream() {
            BHHybridPlayer.shared.playRequest(with: post, playlist: [])
        } else {
            BHLivePlayer.shared.playRequest(with: post)
        }
    }
}

// MARK: - BHGridControllerDelegate

extension BHHomeViewController: BHGridControllerDelegate {

    func gridController(_ controller: BHGridCollectionController, didSelectUser user: BHUser) {
        openUserDetails(user)
    }
}
