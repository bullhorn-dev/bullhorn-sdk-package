
import UIKit
import Foundation

class BHCategoryViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let UserDetailsSegueIdentifier = "Category.UserDetailsSegueIdentifier"
    fileprivate static let PostDetailsSegueIdentifier = "Category.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var selectedUser: BHUser?
    fileprivate var selectedPost: BHPost?
    
    var category: BHCategory?
    
    fileprivate let manager = BHCategoriesManager.shared
    fileprivate var showDots = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let sectionHeaderNib = UINib(nibName: "BHSectionHeaderView", bundle: bundle)
        let sectionFooterNib = UINib(nibName: "BHCollectionFooterView", bundle: bundle)
        
        collectionView.register(sectionHeaderNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer)
        collectionView.register(sectionFooterNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BHCollectionFooterView.reusableIndentifer)
        collectionView.register(BHUserCarouselCell.self, forCellWithReuseIdentifier: BHUserCarouselCell.reusableIndentifer)
        collectionView.register(BHPostCollectionCell.self, forCellWithReuseIdentifier: BHPostCollectionCell.reusableIndentifer)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = true
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .primaryBackground()
        collectionView.delegate = self
        collectionView.dataSource = self

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        layout?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        bottomView.backgroundColor = .primaryBackground()
        
        configureNavigationItems()
        configureRefreshControl()

        fetch(initial: true)

        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openCategory)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        refreshControl?.resetUIState()
        collectionView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        refreshControl?.endRefreshing()
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        let title = category?.name ?? NSLocalizedString("Category", comment: "")
        navigationItem.title = title
        navigationItem.largeTitleDisplayMode = .never

        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis")?.withConfiguration(config), style: .plain, target: self, action: #selector(openOptionsAction(_:)))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "More Options"

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
        collectionView.addSubview(newRefreshControl)
    }
    
    // MARK: - Network
    
    fileprivate func fetch(initial: Bool = false) {
        
        let completeBlock = {
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.collectionView.reloadData()
        }

        guard let categoryId = category?.id else { return }
        
        if initial {
            self.defaultShowActivityIndicatorView()
            manager.removeCategoryData()
            
            manager.fetchStorageCategoryPodcasts(categoryId) { response in
                switch response {
                case .success:
                    if self.manager.users.count > 0 {
                        self.showDots = true
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch category podcasts from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }
            
        manager.fetch(BHAppConfiguration.shared.networkId, categoryId: categoryId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                if BHReachabilityManager.shared.isConnected() {
                    let message = "Failed to fetch category podcasts and episodes. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                } else {
                    self.showDots = false
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }
    
    fileprivate func fetchPosts() {
        guard let categoryId = category?.id else { return }

        showDots = false

        manager.getCategoryPosts(categoryId: categoryId, text: nil) { response in
            switch response {
            case .success:
                self.collectionView.reloadData()
            case .failure(error: _):
                break
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHCategoryViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        } else if segue.identifier == BHCategoryViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = .details
        }
    }
        
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHCategoryViewController.UserDetailsSegueIdentifier, sender: self)
    }
    
    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        performSegue(withIdentifier: BHCategoryViewController.PostDetailsSegueIdentifier, sender: self)
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
    }
    
    @objc fileprivate func openOptionsAction(_ sender: Any) {
        let optionsSheet = BHCategoryOptionsBottomSheet()
        optionsSheet.category = category
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
            collectionView.restore()
            fetch(initial: true)
        default:
            break
        }
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension BHCategoryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if manager.users.count == 0 && manager.posts.count == 0 {
            if !activityIndicator.isAnimating {
                let image = UIImage(named: "ic_list_placeholder.png", in: Bundle.module, with: nil)
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                collectionView.setEmptyMessage(message, image: image)
            } else {
                collectionView.restore()
            }
            return 1
        }
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return manager.users.count
        } else if section == 1 {
            return manager.posts.count
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer, for: indexPath)
                
            guard let usersHeaderView = headerView as? BHSectionHeaderView else { return headerView }
            usersHeaderView.titleLabel.text = indexPath.section == 0 ? "Podcasts" : "Recent Episodes"
                
            return usersHeaderView
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHCollectionFooterView.reusableIndentifer, for: indexPath)
                
            guard let progressFooterView = footerView as? BHCollectionFooterView else { return footerView }
            progressFooterView.setup()
                
            return progressFooterView
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHUserCarouselCell.reusableIndentifer, for: indexPath) as! BHUserCarouselCell
            cell.user = manager.users[indexPath.row]
            cell.showCategory = false
            cell.showBadge = false
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHPostCollectionCell.reusableIndentifer, for: indexPath) as! BHPostCollectionCell
            let post = manager.posts[indexPath.row]
            cell.post = post
            cell.playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: manager.posts, order: .reversed)
            cell.autoplayContext = BHAutoplayContext.category.rawValue
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
            
            if manager.hasMore && indexPath.row == manager.posts.count - 1 {
                fetchPosts()
            }
            
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let user = manager.users[indexPath.row]
            openUserDetails(user)
        } else {
            let post = manager.posts[indexPath.row]
            openPostDetails(post)
        }
    }
      
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            let itemsPerRow: CGFloat = 3
            let padding: CGFloat = 2 * Constants.paddingHorizontal
            let spacing: CGFloat = 2 * Constants.itemSpacing
            let availableWidth: CGFloat = collectionView.bounds.width - padding - spacing
            let itemWidth = floor(availableWidth / itemsPerRow)
            let itemHeight = itemWidth + 24
            
            return CGSize(width: itemWidth, height: itemHeight)
        } else {
            return CGSize(width: collectionView.bounds.width, height: 240)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? Constants.itemSpacing : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? Constants.itemSpacing : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: Constants.itemSpacing / 2, right: Constants.paddingHorizontal)
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return manager.users.count > 0 ? CGSize(width: view.frame.width, height: Constants.panelHeight) : .zero
        } else if section == 1 {
            return manager.posts.count > 0 ? CGSize(width: view.frame.width, height: Constants.panelHeight) : .zero
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 0 { return .zero }
        return (manager.hasMore || showDots) ? CGSize(width: view.frame.width, height: Constants.panelHeight) : .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,  forItemAt indexPath: IndexPath) {
        cell.layoutSubviews()
    }
}
