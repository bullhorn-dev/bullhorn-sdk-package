
import UIKit
import Foundation

class BHChannelViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let UserDetailsSegueIdentifier = "Channel.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Channel.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var headerView: BHChannelHeaderView?
    fileprivate var footerView: BHListFooterView?

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?

    fileprivate var shouldShowHeader: Bool = false
    
    var channel: UIUsersModel?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()
        
        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHChannelHeaderView", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHChannelHeaderView.reusableIndentifer)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: BHListFooterView.reusableIndentifer)
        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        bottomView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHChannelHeaderView.reusableIndentifer) as? BHChannelHeaderView
        headerView?.podcasts = channel?.users ?? []
        headerView?.delegate = self
        
        footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHListFooterView.reusableIndentifer) as? BHListFooterView

        configureNavigationItems()
        configureRefreshControl()

        fetch(initial: true)

        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openChannel)
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
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        let title = channel?.title ?? NSLocalizedString("Channel", comment: "")
        navigationItem.title = title
        navigationItem.largeTitleDisplayMode = .never
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }
    
    fileprivate func configureRefreshControl() {
        
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    // MARK: - Network
    
    fileprivate func fetch(initial: Bool = false) {
        
        let completeBlock = {
            self.shouldShowHeader = BHNetworkManager.shared.posts.count > 0
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
            self.headerView?.reloadData()
            self.configureNavigationItems()
        }

        let networkId = BHAppConfiguration.shared.networkId
        
        if initial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()
            
            BHNetworkManager.shared.fetchPosts(networkId) { response in
                switch response {
                case .success:
                    if BHNetworkManager.shared.posts.count > 0 || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch recent episodes. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        } else {
            
            BHNetworkManager.shared.fetchPosts(networkId) { response in
                switch response {
                case .success:
                    break
                case .failure(error: let error):
                    if BHReachabilityManager.shared.isConnected() {
                        self.showError("Failed to fetch recent episodes from backend. \(error.localizedDescription)")
                    } else if !initial {
                        self.showConnectionError()
                    }
                }
                completeBlock()
            }
        }
    }
    
    fileprivate func fetchPosts() {

        let networkId = BHAppConfiguration.shared.networkId

        BHNetworkManager.shared.fetchPosts(networkId) { response in
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
        if segue.identifier == BHChannelViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        } else if segue.identifier == BHChannelViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = .details
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHChannelViewController.UserDetailsSegueIdentifier, sender: self)
    }
    
    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        performSegue(withIdentifier: BHChannelViewController.PostDetailsSegueIdentifier, sender: self)
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
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

extension BHChannelViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHNetworkManager.shared.posts.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection is lost"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }

        return activityIndicator.isAnimating ? 0 : BHNetworkManager.shared.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        let post = BHNetworkManager.shared.posts[indexPath.row]
        cell.post = post
        cell.playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: BHNetworkManager.shared.posts, order: .straight)
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

        if BHNetworkManager.shared.hasMorePosts && indexPath.row == BHNetworkManager.shared.posts.count - 1 {
            fetchPosts()
        }
        
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if BHNetworkManager.shared.hasMorePosts {
            footerView?.setup()
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return BHNetworkManager.shared.hasMorePosts ? 40 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(BHNetworkManager.shared.posts[indexPath.row])
    }
}

// MARK: - BHChannelHeaderViewDelegate

extension BHChannelViewController: BHChannelHeaderViewDelegate {

    func headerView(_ view: BHChannelHeaderView, didSelectUser user: BHUser) {
        openUserDetails(user)
    }
}
