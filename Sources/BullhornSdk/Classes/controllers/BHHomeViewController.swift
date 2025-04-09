
import UIKit
import Foundation
import SDWebImage

class BHHomeViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Home.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Home.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var headerView: BHHomeHeaderView?

    fileprivate var selectedChannelId: String = UserDefaults.standard.selectedChannelId

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
        NotificationCenter.default.addObserver(self, selector: #selector(onUniversalLinkNotification(notification:)), name: BHLinkResolver.UniversalLinkNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl?.resetUIState()
        reloadData()
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
            self.shouldShowHeader = BHNetworkManager.shared.users.count > 0
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.reloadData()
            self.headerView?.reloadData()
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
        
    fileprivate func reloadData() {
        BHNetworkManager.shared.splitUsers(selectedChannelId)
        tableView.reloadData()
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
        return 1 + BHNetworkManager.shared.splittedUsers.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 { return 0 }
        
        if BHNetworkManager.shared.splittedUsers.count == 0 && !activityIndicator.isAnimating {
            let image = UIImage(named: "ic_list_placeholder.png", in: Bundle.module, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }
        return BHNetworkManager.shared.splittedUsers.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHUsersGridCell.reusableIndentifer, for: indexPath) as! BHUsersGridCell
        let uimodel = BHNetworkManager.shared.splittedUsers[indexPath.section - 1]
        cell.collectionViewController.users = uimodel.users
        cell.collectionViewController.delegate = self

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if shouldShowHeader {
            if section == 0 {
                return nil
            } else {
                return BHNetworkManager.shared.splittedUsers[section - 1].title
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader && section == 0 {
            headerView?.setup()
            return headerView
        } else {
            return UITableViewHeaderFooterView()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if shouldShowHeader && section > 0 {
            let header = view as! UITableViewHeaderFooterView
            header.contentView.backgroundColor = .primaryBackground()
            header.textLabel?.textColor = .primary()
            header.textLabel?.font = UIFont.fontWithName(.robotoBold , size: 18)
            header.textLabel?.text =  header.textLabel?.text?.capitalized
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            if section == 0 {
                return headerView?.calculateHeight() ?? 0
            } else {
                return BHNetworkManager.shared.followedUsers.count > 0 ? 20.0 : 0
            }
        } else {
            return 0
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
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

    func headerView(_ view: BHHomeHeaderView, didSelectChannel channel: BHChannel) {
        selectedChannelId = channel.id
        reloadData()
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
