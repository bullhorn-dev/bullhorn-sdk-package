
import UIKit
import Foundation

class BHNotificationsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Notifications.UserDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var userManager = BHUserManager.shared
    fileprivate var selectedUser: BHUser?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        let sectionHeaderNib = UINib(nibName: "BHSectionHeaderView", bundle: bundle)

        collectionView.register(sectionHeaderNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer)
        collectionView.register(BHUserCarouselCell.self, forCellWithReuseIdentifier: BHUserCarouselCell.reusableIndentifer)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = true
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .primaryBackground()
        collectionView.delegate = self
        collectionView.dataSource = self

        configureNavigationItems()
        configureRefreshControl()

        fetch(initial: true)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openNotifications)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
        configureNavigationItems()
        collectionView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshControl?.endRefreshing()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = NSLocalizedString("Notifications", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearButtonAction(_:)))
        navigationItem.rightBarButtonItem?.isEnabled = BHUserManager.shared.newEpisodesUsers.count > 0
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Clear notifications"
        
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

        if initial {
            self.defaultShowActivityIndicatorView()
        }

        if let user = BHAccountManager.shared.user {
            userManager.fetchFollowed(user.id) { response in
                switch response {
                case .success:
                    break
                case .failure(error: let error):
                    if BHReachabilityManager.shared.isConnected() {
                        self.showError("Failed to fetch followed podcasts from backend. \(error.localizedDescription)")
                    } else if !initial {
                        self.showConnectionError()
                    }
                }
                completeBlock()
            }
        } else {
            completeBlock()
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == BHNotificationsViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHNotificationsViewController.UserDetailsSegueIdentifier, sender: self)
    }

    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
    }
    
    @objc fileprivate func clearButtonAction(_ sender: Any) {
        userManager.clearCounters() { respose in
            switch respose {
            case .success:
                DispatchQueue.main.async {
                    self.configureNavigationItems()
                    self.collectionView.reloadData()
                    BHNotificationsManager.shared.removeAllDeliveredNotifications()
                }
            case .failure(error: let error):
                DispatchQueue.main.async {
                    self.showError("Failed to clear all notifications. \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension BHNotificationsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if userManager.newEpisodesUsers.count == 0 {
            if !activityIndicator.isAnimating {
                let image = UIImage(named: "ic_list_placeholder.png", in: Bundle.module, with: nil)
                let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
                collectionView.setEmptyMessage(message, image: image)
            } else {
                collectionView.restore()
            }
        }
        return userManager.newEpisodesUsers.count == 0 ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userManager.newEpisodesUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer, for: indexPath)
                
            guard let usersHeaderView = headerView as? BHSectionHeaderView else { return headerView }
            usersHeaderView.titleLabel.text = "Podcasts with new episodes"
                
            return usersHeaderView
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHUserCarouselCell.reusableIndentifer, for: indexPath) as! BHUserCarouselCell
        cell.user = userManager.newEpisodesUsers[indexPath.row]
        cell.showCategory = false
        cell.showBadge = true

        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = userManager.newEpisodesUsers[indexPath.row]
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
        return CGSize(width: view.frame.width, height: Constants.panelHeight)
    }
}
