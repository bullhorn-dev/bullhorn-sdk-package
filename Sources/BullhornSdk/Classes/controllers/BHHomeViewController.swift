
import UIKit
import Foundation
import SDWebImage

class BHHomeViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Home.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Home.PostDetailsSegueIdentifier"
    fileprivate static let FollowedPodcastsSegueIdentifier = "Home.FollowedPodcastsSegueIdentifier"
    fileprivate static let NotificationsSegueIdentifier = "Home.NotificationsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!

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
        let headerNib = UINib(nibName: "BHHomeHeaderView", bundle: bundle)
        let sectionHeaderNib = UINib(nibName: "BHSectionHeaderView", bundle: bundle)

        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BHHomeHeaderView.reusableIndentifer)
        collectionView.register(sectionHeaderNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer)
        collectionView.register(BHUserGridCell.self, forCellWithReuseIdentifier: BHUserGridCell.reusableIndentifer)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = true
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .primaryBackground()
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
        configureNavigationItems()
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openHome)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let sections = getAllSectionsIndexSet()
        collectionView.reloadSections(sections)
        
        BHLog.p("Refresh all sections")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {

        navigationItem.title = NSLocalizedString("Home", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        if UserDefaults.standard.isPushNotificationsFeatureEnabled {
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
        collectionView.addSubview(newRefreshControl)
    }
    
    fileprivate func getAllSectionsIndexSet() -> IndexSet {
        let numberOfSections = collectionView.numberOfSections
        let allSections = IndexSet(integersIn: 1..<numberOfSections)
        return allSections
    }

    // MARK: - Network

    fileprivate func fetch(_ isInitial: Bool = false) {
        
        let networkId = BHAppConfiguration.shared.networkId
        
        let completeBlock = {
            self.shouldShowHeader = BHNetworkManager.shared.featuredUsers.count > 0 && BHNetworkManager.shared.channels.count > 0
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
                    completeBlock()
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
        BHLog.p("\(#function)")
        
        BHNetworkManager.shared.splitUsers(selectedChannelId)

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
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
            collectionView.restore()
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

// MARK: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension BHHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if BHNetworkManager.shared.splittedUsers.count == 0 && !activityIndicator.isAnimating {
            let image = UIImage(named: "ic_list_placeholder.png", in: Bundle.module, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
            collectionView.setEmptyMessage(message, image: image)
        } else {
            collectionView.restore()
        }
        return BHNetworkManager.shared.splittedUsers.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 0 }
        return BHNetworkManager.shared.splittedUsers[section - 1].users.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            if indexPath.section == 0 {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHHomeHeaderView.reusableIndentifer, for: indexPath)
                
                guard let homeHeaderView = headerView as? BHHomeHeaderView else { return headerView }
                
                if self.headerView == nil {
                    homeHeaderView.initialize()
                    homeHeaderView.delegate = self
                }
                homeHeaderView.setup()
                
                self.headerView = homeHeaderView
                
                return  homeHeaderView
            } else {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer, for: indexPath)
                
                guard let usersHeaderView = headerView as? BHSectionHeaderView else { return headerView }
                usersHeaderView.titleLabel.text = BHNetworkManager.shared.splittedUsers[indexPath.section - 1].title
                
                return usersHeaderView
            }
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHUserGridCell.reusableIndentifer, for: indexPath) as! BHUserGridCell
        cell.user = BHNetworkManager.shared.splittedUsers[indexPath.section - 1].users[indexPath.item]
    
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = BHNetworkManager.shared.splittedUsers[indexPath.section - 1].users[indexPath.row]
        openUserDetails(user)
    }
      
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemsPerRow: CGFloat = 3
        let padding: CGFloat = 2 * Constants.paddingHorizontal
        let spacing: CGFloat = 2 * Constants.itemSpacing
        let availableWidth: CGFloat = collectionView.bounds.width - padding - spacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        let itemHeight = itemWidth + 24

        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.itemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: Constants.itemSpacing/2, right: Constants.paddingHorizontal)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        if section == 0 {
            if shouldShowHeader {
                return CGSize(width: view.frame.width, height: headerView?.calculateHeight() ?? 768.0)
            } else {
                return CGSize(width: view.frame.width, height: 0.0)
            }
        } else {
            return CGSize(width: view.frame.width, height: Constants.panelHeight)
        }
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
