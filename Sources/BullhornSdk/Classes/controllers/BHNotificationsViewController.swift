
import UIKit
import Foundation
import SDWebImage

class BHNotificationsViewController: UIViewController, ActivityIndicatorSupport {
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var headerView: BHNotificationHeaderView?

    fileprivate var userManager = BHUserManager()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        let notificationUserCellNib = UINib(nibName: "BHNotificationUserCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHNotificationHeaderView", bundle: bundle)

        tableView.register(notificationUserCellNib, forCellReuseIdentifier: BHNotificationUserCell.reusableIndentifer)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHNotificationHeaderView.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHNotificationHeaderView.reusableIndentifer) as? BHNotificationHeaderView
        headerView?.setup()
        headerView?.delegate = self

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshControl?.endRefreshing()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = NSLocalizedString("Notifications", comment: "")
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
    
    fileprivate func fetch(initial: Bool = false) {
        let completeBlock = {
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
        }

        if initial {
            self.defaultShowActivityIndicatorView()
        }

        userManager.getFollowedUsers() { response in
            switch response {
            case .success(users: _):
                break
            case .failure(error: let error):
                var message: String = ""
                if BHReachabilityManager.shared.isConnected() {
                    message = "Failed to fetch user subscriptions from backend. \(error.localizedDescription)"
                    self.showError(message)
                } else if !initial {
                    message = "The Internet connection appears to be offline"
                    self.showError(message)
                }
            }
            completeBlock()
        }
    }

    fileprivate func unfollowUser(_ userId: String) {
        BHLog.p("\(#function) - userID: \(userId)")
        
        defaultShowActivityIndicatorView()

        userManager.unfollowUser(userId) { response in
            switch response {
            case .success(user: _):
                self.tableView.reloadData()
            case .failure(error: let error):
                self.showError("Failed to unfollow podcast. \(error)")
            }
            self.defaultHideActivityIndicatorView()
        }
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHNotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else if section == 1 {
            return userManager.followedUsers.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHNotificationUserCell", for: indexPath) as! BHNotificationUserCell
        let user = userManager.followedUsers[indexPath.row]
        cell.user = user
        cell.switchChangeClosure = { [weak self] isOn in
            if !isOn {
                self?.unfollowUser(user.id)
            }
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return ""
        } else {
            return NSLocalizedString("New Episodes", comment: "").uppercased()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerView
        } else {
            let header = UITableViewHeaderFooterView()
            header.contentView.backgroundColor = .secondaryBackground()
            header.textLabel?.textColor = .secondary()
            header.textLabel?.font = UIFont.fontWithName(.robotoThin , size: 15)
            return header
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return headerView?.calculateHeight() ?? 60.0
        } else {
            return userManager.followedUsers.count > 0 ? 44.0 : 0
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

// MARK: - BHNotificationHeaderViewDelegate

extension BHNotificationsViewController: BHNotificationHeaderViewDelegate {

    func headerView(_ view: BHNotificationHeaderView, didChange enable: Bool) {
        tableView.reloadData()
    }
}

