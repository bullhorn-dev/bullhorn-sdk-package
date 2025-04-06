
import UIKit
import Foundation
import SDWebImage

class BHNotificationsViewController: UIViewController, ActivityIndicatorSupport {
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

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
        
        tableView.reloadData()

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openNotifications)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = NSLocalizedString("Notifications", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Network

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
            return BHNetworkManager.shared.followedUsers.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHNotificationUserCell", for: indexPath) as! BHNotificationUserCell
        let user = BHNetworkManager.shared.followedUsers[indexPath.row]
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
            return BHNetworkManager.shared.followedUsers.count > 0 ? 44.0 : 0
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

