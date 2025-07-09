
import UIKit
import Foundation

class BHNotificationsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "Notifications.UserDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
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
        let gridCellNib = UINib(nibName: "BHUsersGridCell", bundle: bundle)

        tableView.register(gridCellNib, forCellReuseIdentifier: BHUsersGridCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

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
        tableView.reloadData()
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
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
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
                    self.tableView.reloadData()
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

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHNotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userManager.newEpisodesUsers.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
            let message = BHReachabilityManager.shared.isConnected() ? "No notifications yet" : "The Internet connection is lost"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }

        return userManager.newEpisodesUsers.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHUsersGridCell.reusableIndentifer, for: indexPath) as! BHUsersGridCell
        
        let uiModel = UIUsersModel(title: "Podcasts with new episodes", users: userManager.newEpisodesUsers)
        cell.collectionViewController.uiModels = [uiModel]
        cell.collectionViewController.showNewEpisodesBadge = true
        cell.collectionViewController.delegate = self
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - BHGridControllerDelegate

extension BHNotificationsViewController: BHGridControllerDelegate {

    func gridController(_ controller: BHGridCollectionController, didSelectUser user: BHUser) {
        openUserDetails(user)
    }
}
