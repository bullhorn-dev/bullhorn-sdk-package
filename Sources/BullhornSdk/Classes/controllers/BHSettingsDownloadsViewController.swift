
import UIKit
import Foundation
import SDWebImage

class BHSettingsDownloadsViewController: UIViewController, ActivityIndicatorSupport {
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var settingsManager = BHSettingsManager.shared

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let cellNib = UINib(nibName: "BHSettingUserCell", bundle: bundle)

        tableView.register(cellNib, forCellReuseIdentifier: BHSettingUserCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        configureNavigationItems()
        configureRefreshControl()

        fetch(initial: true)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openDownloadsSettings)
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
        navigationItem.title = NSLocalizedString("Downloads Settings", comment: "")
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
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
        }

        if initial {
            self.defaultShowActivityIndicatorView()
        }

        if let user = BHAccountManager.shared.user {
            BHUserManager.shared.getFollowedUsers(user.id) { response in
                switch response {
                case .success(users: _):
                    break
                case .failure(error: let error):
                    if BHReachabilityManager.shared.isConnected() {
                        self.showError("Failed to fetch user downloads settings from backend. \(error.localizedDescription)")
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

    fileprivate func enableUserAutoDownloads(_ userId: String, enable: Bool) {
        BHLog.p("\(#function) - userID: \(userId), enable: \(enable)")
        
        defaultShowActivityIndicatorView()

        settingsManager.enableUserDownloads(userId, enable: enable) { response in
            switch response {
            case .success(user: let user):
                BHUserManager.shared.updateUserNotifications(user)
                self.tableView.reloadData()
            case .failure(error: let error):
                self.showError("Failed to enable podcast notifications. \(error)")
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

extension BHSettingsDownloadsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BHUserManager.shared.followedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHSettingUserCell", for: indexPath) as! BHSettingUserCell
        let user = BHUserManager.shared.followedUsers[indexPath.row]
        cell.user = user
        cell.type = .downloads
        cell.switchChangeClosure = { [weak self] isOn in
            self?.enableUserAutoDownloads(user.id, enable: isOn)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Auto Download Episodes", comment: "").uppercased()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.contentView.backgroundColor = .fxPrimaryBackground()
        header.textLabel?.textColor = .secondary()
        header.textLabel?.font = UIFont.fontWithName(.robotoThin , size: 15)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return BHUserManager.shared.followedUsers.count > 0 ? 44.0 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

