
import UIKit
import Foundation
import SDWebImage

class BHRadioViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var headerView: BHRadioHeaderView?

    fileprivate var refreshControl: UIRefreshControl?
    
    fileprivate var shouldShowHeader: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let radioCellNib = UINib(nibName: "BHRadioCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHRadioHeaderView", bundle: bundle)

        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHRadioHeaderView.reusableIndentifer)
        tableView.register(radioCellNib, forCellReuseIdentifier: BHRadioCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHRadioHeaderView.reusableIndentifer) as? BHRadioHeaderView
        headerView?.initialize()
        
        configureNavigationItems()
        configureRefreshControl()

        fetch(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionChangedNotification(notification:)), name: BHReachabilityManager.ConnectionChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIdChangedNotification(notification:)), name: BullhornSdk.NetworkIdChangedNotification, object: nil)
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

        navigationItem.title = NSLocalizedString("Live Radio Streams", comment: "")
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
        
        let networkId = BHAppConfiguration.shared.networkId
        
        let completeBlock = {
            self.shouldShowHeader = BHRadioStreamsManager.shared.radios.count > 0
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
            self.headerView?.reloadData()
        }

        if isInitial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()

            BHRadioStreamsManager.shared.fetchStorage(networkId) { response in
                switch response {
                case .success:
                    let showHeader = BHRadioStreamsManager.shared.radios.count > 0
                    if showHeader || !BHReachabilityManager.shared.isConnected() {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch radios from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        BHRadioStreamsManager.shared.fetch(networkId) { response in
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
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch()
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
        
        DataBaseManager.shared.dataStack.drop() { error in
            if let validError = error {
                debugPrint("Failed to drop data base: \(validError.debugDescription)")
            }
            
            self.fetch(true)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHRadioViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let bundle = Bundle.module
        let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
        
        if BHRadioStreamsManager.shared.otherRadios.count < 1 && !activityIndicator.isAnimating {
            let message = BHReachabilityManager.shared.isConnected() ? "Nothing to show" : "The Internet connection appears to be offline"
            tableView.setEmptyMessage(message, image: image)
        } else {
            tableView.restore()
        }

        return BHRadioStreamsManager.shared.otherRadios.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHRadioCell.reusableIndentifer, for: indexPath) as! BHRadioCell
        cell.radio = BHRadioStreamsManager.shared.otherRadios[indexPath.row]
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(BHRadioStreamsManager.shared.hasRadioStreams)
            return headerView
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight(BHRadioStreamsManager.shared.hasRadioStreams) ?? 100
        } else {
            return 0
        }
    }
}


