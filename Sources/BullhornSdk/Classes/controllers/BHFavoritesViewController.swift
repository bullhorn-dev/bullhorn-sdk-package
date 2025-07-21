
import UIKit
import Foundation
import SDWebImage

class BHFavoritesViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let PostDetailsSegueIdentifier = "FavoritesVC.PostDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var footerView: BHListFooterView?

    fileprivate var feedManager = BHFeedManager.shared

    fileprivate var selectedPost: BHPost?
    fileprivate var selectedTab: BHPostTabs = .details

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        let footerNib = UINib(nibName: "BHListFooterView", bundle: bundle)

        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: BHListFooterView.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHListFooterView.reusableIndentifer) as? BHListFooterView

        configureNavigationItems()
        configureRefreshControl()

        fetchPosts(initial: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openFavorites)
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
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Liked Episodes", comment: "")
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
    
    fileprivate func fetchPosts(initial: Bool = false) {

        let completeBlock = {
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
        }

        if initial {
            self.defaultShowActivityIndicatorView()
            
            feedManager.fetchStoragePosts() { response in
                switch response {
                case .success:
                    if self.feedManager.favorites.count > 0 || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch liked posts from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        feedManager.getLikedPosts("") { response in
            switch response {
            case .success:
                self.tableView.reloadData()
                break
            case .failure(error: let error):
                if BHReachabilityManager.shared.isConnected() {
                    self.showError("Failed to fetch liked posts from backend. \(error.localizedDescription)")
                } else if !initial {
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == BHFavoritesViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = selectedTab
        }
    }
    
    // MARK: - Private
    
    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        selectedTab = tab
        performSegue(withIdentifier: BHFavoritesViewController.PostDetailsSegueIdentifier, sender: self)
    }

    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetchPosts(initial: false)
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onConnectionChangedNotification(notification: Notification) {
        guard let notificationInfo = notification.userInfo as? [String : BHReachabilityManager.ConnectionChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHReachabilityManager.NotificationInfoKey] else { return }
        
        switch info.type {
        case .connected, .connectedExpensive:
            tableView.restore()
            fetchPosts(initial: true)
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHFavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if feedManager.favorites.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "No episode liked yet" : "The Internet connection is lost"

            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }

        return feedManager.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        let post = feedManager.favorites[indexPath.row]
        cell.post = post
        cell.playlist = feedManager.favorites
        cell.shareBtnTapClosure = { [weak self] url in
            self?.presentShareDialog(with: [url], configureBlock: { controller in
                controller.popoverPresentationController?.sourceView = cell.shareButton
            })
        }
        cell.likeBtnTapClosure = { [weak self] liked in
            self?.fetchPosts(initial: true)
        }
        cell.transcriptBtnTapClosure = { [weak self] postId in
            self?.openPostDetails(post, tab: .transcript)
        }
        cell.errorClosure = { [weak self] message in
            self?.showError(message)
        }

        if feedManager.hasMore && indexPath.row == feedManager.favorites.count - 1 {
            fetchPosts()
        }
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if feedManager.hasMore {
            footerView?.setup()
            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return feedManager.hasMore ? 40 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(feedManager.favorites[indexPath.row])
    }
}

