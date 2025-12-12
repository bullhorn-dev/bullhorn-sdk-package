
import UIKit
import Foundation

class BHDownloadsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let PostDetailsSegueIdentifier = "DownloadsVC.PostDetailsSegueIdentifier"
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var selectedPost: BHPost?
    fileprivate var selectedTab: BHPostTabs = .details
    
    let dateFormatter: DateFormatter = DateFormatter()

    // MARK: - Lifecycle
    
    deinit {
        BHDownloadsManager.shared.removeListener(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()
        
        bottomView.backgroundColor = .primaryBackground()
        
        let bundle = Bundle.module
        let postCellNib = UINib(nibName: "BHPostCell", bundle: bundle)
        
        tableView.register(postCellNib, forCellReuseIdentifier: BHPostCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        tableView.backgroundColor = .primaryBackground()

        configureNavigationItems()
        
        BHDownloadsManager.shared.addListener(self)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openDownloads)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        BHDownloadsManager.shared.updateItems()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
        
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == BHDownloadsViewController.PostDetailsSegueIdentifier, let vc = segue.destination as? BHPostDetailsViewController {
            vc.post = selectedPost
            vc.selectedTab = selectedTab
        }
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Downloaded Episodes", comment: "")
        navigationItem.largeTitleDisplayMode = .never

        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash")?.withConfiguration(config), style: .plain, target: self, action: #selector(removeAllButtonAction(_:)))
        navigationItem.rightBarButtonItem?.isEnabled = BHDownloadsManager.shared.items.count > 0
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Remove downloads"
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }
    
    override func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {
        selectedPost = post
        selectedTab = tab
        performSegue(withIdentifier: BHDownloadsViewController.PostDetailsSegueIdentifier, sender: self)
    }

    @objc fileprivate func removeAllButtonAction(_ sender: Any) {
        
        let alert = UIAlertController.init(title: "Do you really want to remove all downloads?", message: "All downloads will be removed from the device memory.", preferredStyle: .alert)

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction.init(title: "Remove All", style: .destructive) { _ in
            BHDownloadsManager.shared.removeAll()
        })

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHDownloadsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return BHDownloadsManager.shared.groupedItems[section].date.prettyString()
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = .primaryBackground()
        header.textLabel?.textColor = .secondary()
        header.textLabel?.font = UIFont.fontWithName(.robotoMedium , size: 16)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if BHDownloadsManager.shared.groupedItems.count == 1 {
            return 0
        }
        return 50.0
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        if BHDownloadsManager.shared.groupedItems.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_downloads_placeholder.png", in: bundle, with: nil)

            tableView.setEmptyMessage("No episode downloaded yet", image: image)
        } else {
            tableView.restore()
        }

        return BHDownloadsManager.shared.groupedItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BHDownloadsManager.shared.groupedItems[section].posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        let post = BHDownloadsManager.shared.groupedItems[indexPath.section].posts[indexPath.row]
        cell.post = post
        
        let posts = BHDownloadsManager.shared.items.map({ $0.post })
        cell.playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: posts, order: .straight)

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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(BHDownloadsManager.shared.groupedItems[indexPath.section].posts[indexPath.row])
    }
}

// MARK: - BHDownloadsManagerListener

extension BHDownloadsViewController: BHDownloadsManagerListener {
    
    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem) {}

    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem) {
        if item.status == .start {
            DispatchQueue.main.async {
                self.configureNavigationItems()
                self.tableView.reloadData()
            }
        }
    }
    
    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool) {
        DispatchQueue.main.async {
            self.configureNavigationItems()
            self.tableView.reloadData()
        }
    }
    
    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
