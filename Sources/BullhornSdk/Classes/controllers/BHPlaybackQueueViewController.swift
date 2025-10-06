
import UIKit
import Foundation

class BHPlaybackQueueViewController: UIViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var selectedPost: BHPost?
    fileprivate var selectedTab: BHPostTabs = .details
    
    let dateFormatter: DateFormatter = DateFormatter()

    // MARK: - Lifecycle
    
    deinit {
//        BHHybridPlayer.shared.removeListener(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        configureNavigationItems()

        overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        let bundle = Bundle.module
        let queueCellNib = UINib(nibName: "BHPlaybackQueueCell", bundle: bundle)
        
        tableView.register(queueCellNib, forCellReuseIdentifier: BHPlaybackQueueCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .divider()
        tableView.reloadData()
        
        BHHybridPlayer.shared.addListener(self)

        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openQueue)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Playback Queue", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(onClose(_:)))
    }
    
    // MARK: - Actions
    
    @objc fileprivate func onClose(_ sender: Any) {
        self.navigationController?.dismiss(animated: true)
    }

    // MARK: - Notifications
    
    @objc fileprivate func onUserInterfaceStyleChangedNotification(notification: Notification) {
        guard let dict = notification.userInfo as? NSDictionary else { return }
        guard let value = dict["style"] as? Int else { return }
        
        let style = UIUserInterfaceStyle(rawValue: value) ?? .light

        overrideUserInterfaceStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHPlaybackQueueViewController: UITableViewDataSource, UITableViewDelegate {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHHybridPlayer.shared.playbackQueue.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_downloads_placeholder.png", in: bundle, with: nil)

            tableView.setEmptyMessage("No episodes in playback queue yet", image: image)
        } else {
            tableView.restore()
        }

        return BHHybridPlayer.shared.playbackQueue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPlaybackQueueCell", for: indexPath) as! BHPlaybackQueueCell
        let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
        cell.item = item
        cell.isActive = BHHybridPlayer.shared.isInPlayer(item.post.id)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
        
        BHHybridPlayer.shared.playRequest(with: item.post, playlist: [])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.row == 0 { return UISwipeActionsConfiguration(actions: []) }
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, complete in
            let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
            
            BHHybridPlayer.shared.removeFromPlaybackQueue(item.id)
            self.tableView.reloadData()
            
            complete(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.image?.withTintColor(.onAccent())
        delete.backgroundColor = .accent()

        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.showsReorderControl = indexPath.row == 0 ? false : self.tableView(tableView, canMoveRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if destinationIndexPath.row == 0 { return }
        
        let movedItem = BHHybridPlayer.shared.playbackQueue.remove(at: sourceIndexPath.row)
        BHHybridPlayer.shared.playbackQueue.insert(movedItem, at: destinationIndexPath.row)
    }
}

// MARK: - BHHybridPlayerListener

extension BHPlaybackQueueViewController: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

}

