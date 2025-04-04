
import UIKit
import Foundation
import SDWebImage

class BHHomeViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Home.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Home.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var headerView: BHHomeHeaderView?
    fileprivate var footerView: BHListFooterView?
    fileprivate var selectedTab: BHTabs = .podcasts

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?
    
    fileprivate lazy var userManager = BHUserManager()
    fileprivate lazy var postManager = BHPostsManager()
    
    fileprivate var shouldShowHeader: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        let gridCellNib = UINib(nibName: "BHUsersGridCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHHomeHeaderView", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHHomeHeaderView.reusableIndentifer)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: BHListFooterView.reusableIndentifer)
        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.register(gridCellNib, forCellReuseIdentifier: BHUsersGridCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHHomeHeaderView.reusableIndentifer) as? BHHomeHeaderView
        headerView?.initialize()
        headerView?.delegate = self
        
        footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHListFooterView.reusableIndentifer) as? BHListFooterView

        configureNavigationItems()
        configureRefreshControl()

        fetch(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIdChangedNotification(notification:)), name: BullhornSdk.NetworkIdChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(notification:)), name: BHAccountManager.AccountChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUniversalLinkNotification(notification:)), name: BHLinkResolver.UniversalLinkNotification, object: nil)
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
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {

        navigationItem.title = NSLocalizedString("Home", comment: "")
        navigationItem.largeTitleDisplayMode = .never
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
        
        let networkId = BHAppConfiguration.shared.foxNetworkId
        
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

            BHNetworkManager.shared.fetchStorage(networkId) { response in
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

        BHNetworkManager.shared.fetch(networkId) { response in
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
    
    fileprivate func fetchPosts() {

        BHNetworkManager.shared.getNetworkPosts(BHAppConfiguration.shared.foxNetworkId) { response in
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

        BHNetworkManager.shared.getNetworkUsers(BHAppConfiguration.shared.foxNetworkId) { response in
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

    override func openPostDetails(_ post: BHPost?) {
        selectedPost = post
        performSegue(withIdentifier: BHHomeViewController.PostDetailsSegueIdentifier, sender: self)
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
    
    
    @objc fileprivate func onUniversalLinkNotification(notification: Notification) {
        BHLog.p("\(#function)")

        guard let notificationInfo = notification.userInfo as? [String : UniversalNotificationInfo] else { return }
        guard let info = notificationInfo["info"] else { return }
        
        switch info.type {
        case .podcast:
            defaultShowActivityIndicatorView()
            userManager.getUserByUsername(info.username) { result in
                
                self.defaultHideActivityIndicatorView()

                switch result {
                case .success(user: let podcast):
                    self.selectedUser = podcast
                    self.performSegue(withIdentifier: BHHomeViewController.UserDetailsSegueIdentifier, sender: self)

                case .failure(error: let e):
                    self.showWarning(e.localizedDescription)
                    break
                }
            }

        case .episode:
            guard let postAlias = info.alias else { return }

            defaultShowActivityIndicatorView()
            postManager.getPostByAlias(info.username, postAlias: postAlias) { result in
                
                self.defaultHideActivityIndicatorView()

                switch result {
                case .success(post: let post):
                    self.selectedPost = post
                    self.performSegue(withIdentifier: BHHomeViewController.PostDetailsSegueIdentifier, sender: self)

                case .failure(error: let e):
                    self.showWarning(e.localizedDescription)
                    break
                }
            }

        case .unknown: break
        }
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let bundle = Bundle.module
        let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
        
        switch selectedTab {
        case .podcasts:
            if BHNetworkManager.shared.users.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return BHNetworkManager.shared.users.count > 0 ? 1 : 0
        case .episodes:
            if BHNetworkManager.shared.posts.count == 0 && !activityIndicator.isAnimating {
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                tableView.setEmptyMessage(message, image: image)
            } else {
                tableView.restore()
            }
            return BHNetworkManager.shared.posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .podcasts:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHUsersGridCell.reusableIndentifer, for: indexPath) as! BHUsersGridCell
            cell.collectionViewController.users = BHNetworkManager.shared.users
            cell.collectionViewController.delegate = self

            if BHNetworkManager.shared.hasMoreUsers {
                fetchUsers()
            }

            return cell
        case .episodes:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostCell.reusableIndentifer, for: indexPath) as! BHPostCell
            cell.post = BHNetworkManager.shared.posts[indexPath.row]
            cell.playlist = BHNetworkManager.shared.posts
            cell.shareBtnTapClosure = { [weak self] url in
                self?.presentShareDialog(with: [url], configureBlock: { controller in
                    controller.popoverPresentationController?.sourceView = cell.shareButton
                })
            }
            
            if BHNetworkManager.shared.hasMorePosts && indexPath.row == BHNetworkManager.shared.posts.count - 1 {
                fetchPosts()
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(BHRadioStreamsManager.shared.hasRadioStreams)
            return headerView
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight(BHRadioStreamsManager.shared.hasRadioStreams) ?? 88
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch selectedTab {
        case .podcasts:
            if BHNetworkManager.shared.hasMoreUsers {
                footerView?.setup()
                return footerView
            }
        case .episodes:
            if BHNetworkManager.shared.hasMorePosts {
                footerView?.setup()
                return footerView
            }
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch selectedTab {
        case .podcasts:
            return BHNetworkManager.shared.hasMoreUsers ? 40 : 0
        case .episodes:
            return BHNetworkManager.shared.hasMorePosts ? 40 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch selectedTab {
        case .podcasts:
            break
        case .episodes:
            openPostDetails(BHNetworkManager.shared.posts[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - BHHomeHeaderViewDelegate

extension BHHomeViewController: BHHomeHeaderViewDelegate {

    func headerView(_ view: BHHomeHeaderView, didSelectPost post: BHPost) {
        openPostDetails(post)
    }
    
    func headerView(_ view: BHHomeHeaderView, didSelectUser user: BHUser) {
        openUserDetails(user)
    }

    func headerView(_ view: BHHomeHeaderView, didSelectTabBarItem item: BHTabs) {
        selectedTab = item
        tableView.reloadData()
    }
    
    func headerView(_ view: BHHomeHeaderView, didRequestPlayPost post: BHPost) {
        BHLivePlayer.shared.playRequest(with: post)
    }
}

// MARK: - BHGridControllerDelegate

extension BHHomeViewController: BHGridControllerDelegate {

    func gridController(_ controller: BHGridCollectionController, didSelectUser user: BHUser) {
        openUserDetails(user)
    }
}
