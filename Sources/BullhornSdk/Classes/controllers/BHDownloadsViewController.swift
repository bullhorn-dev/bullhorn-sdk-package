
import UIKit
import Foundation

class BHDownloadsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let PostDetailsSegueIdentifier = "DownloadsVC.PostDetailsSegueIdentifier"
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var selectedPost: BHPost?
    
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
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openDownloads)
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
        }
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Downloaded Episodes", comment: "")
        navigationItem.largeTitleDisplayMode = .never

        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash")?.withConfiguration(config), style: .plain, target: self, action: #selector(removeAllButtonAction(_:)))
        navigationItem.rightBarButtonItem?.isEnabled = BHDownloadsManager.shared.items.count > 0
    }
    
    override func openPostDetails(_ post: BHPost?) {
        selectedPost = post
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHDownloadsManager.shared.items.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_downloads_placeholder.png", in: bundle, with: nil)

            tableView.setEmptyMessage("No episode downloaded yet", image: image)
        } else {
            tableView.restore()
        }

        return BHDownloadsManager.shared.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPostCell", for: indexPath) as! BHPostCell
        cell.post = BHDownloadsManager.shared.items[indexPath.row].post
        cell.playlist = BHDownloadsManager.shared.items.map({ $0.post })
        cell.shareBtnTapClosure = { [weak self] url in
            self?.presentShareDialog(with: [url], configureBlock: { controller in
                controller.popoverPresentationController?.sourceView = cell.shareButton
            })
        }
        cell.errorClosure = { [weak self] message in
            self?.showError(message)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPostDetails(BHDownloadsManager.shared.items[indexPath.row].post)
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
