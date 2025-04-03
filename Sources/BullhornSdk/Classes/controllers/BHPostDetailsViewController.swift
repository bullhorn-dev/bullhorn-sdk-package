
import UIKit
import Foundation
import SDWebImage

class BHPostDetailsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let UserDetailsSegueIdentifier = "PostDetailsVC.UserDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var headerView: BHPostHeaderView?
    fileprivate var selectedTab: BHPostHeaderView.Tabs = .details

    fileprivate var postsManager = BHPostsManager()

    fileprivate var selectedUser: BHUser?
    
    fileprivate var shouldShowHeader: Bool = false

    var post: BHPost?
    var context: String?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let userCellNib = UINib(nibName: "BHUserCell", bundle: bundle)
        let postCellNib = UINib(nibName: "BHPostDescriptionCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHPostHeaderView", bundle: bundle)

        tableView.register(userCellNib, forCellReuseIdentifier: BHUserCell.reusableIndentifer)
        tableView.register(postCellNib, forCellReuseIdentifier: BHPostDescriptionCell.reusableIndentifer)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHPostHeaderView.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHPostHeaderView.reusableIndentifer) as? BHPostHeaderView
        headerView?.delegate = self
        headerView?.postsManager = postsManager

        configureNavigationItems()
        configureRefreshControl()

        fetch(initial: true)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .openEpisode, context: post?.shareLink.absoluteString, podcastId: post?.user.id, podcastTitle: post?.user.fullName, episodeId: post?.id, episodeTitle: post?.title)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl?.resetUIState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Episode Details", comment: "")
        
        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis")?.withConfiguration(config), style: .plain, target: self, action: #selector(openOptionsAction(_:)))
    }
    
    fileprivate func configureRefreshControl() {
        
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    fileprivate func fetch(initial: Bool = false) {
        guard let p = post else { return }

        let completeBlock = {
            self.shouldShowHeader = true
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
            self.headerView?.reloadData()
        }

        if initial {
            self.shouldShowHeader = false
            self.defaultShowActivityIndicatorView()

            postsManager.fetchStorage(userId: p.user.id, postId: p.id) { response in
                switch response {
                case .success:
                    if self.postsManager.post != nil {
                        completeBlock()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch post details from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        postsManager.fetch(userId: p.user.id, postId: p.id, context: context) { response in
            switch response {
            case .success:
                break
            case .failure(error: let error):
                var message: String = ""
                if BHReachabilityManager.shared.isConnected() {
                    message = "Failed to load episode details. This episode no longer available."
                    self.showError(message)
                } else if !initial {
                    message = "The Internet connection appears to be offline"
                    self.showError(message)
                }
            }
            completeBlock()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHPostDetailsViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        }
    }
    
    // MARK: - Private
    
    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHPostDetailsViewController.UserDetailsSegueIdentifier, sender: self)
    }

    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch()
    }
    
    @objc fileprivate func openOptionsAction(_ sender: Any) {
        let optionsSheet = BHPostOptionsBottomSheet()
        optionsSheet.post = post
        optionsSheet.preferredSheetSizing = .fit
        optionsSheet.panToDismissEnabled = true
        present(optionsSheet, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHPostDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTab {
        case .details:
            headerView?.tabTitleLabel.alpha = 1
            tableView.restore()
            return 1
        case .related:
            if postsManager.recommendedUsers.count == 0 {
                let bundle = Bundle.module
                let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)

                tableView.setEmptyMessage("There are no similar podcasts", image: image, topOffset: (headerView?.calculateHeight() ?? 120) / 2)
            } else {
                tableView.restore()
            }
            headerView?.tabTitleLabel.alpha = postsManager.recommendedUsers.count > 0 ? 1 : 0

            return postsManager.recommendedUsers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .details:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostDescriptionCell.reusableIndentifer, for: indexPath) as! BHPostDescriptionCell
            cell.text = postsManager.post?.description
            return cell
        case .related:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHUserCell.reusableIndentifer, for: indexPath) as! BHUserCell
            cell.user = postsManager.recommendedUsers[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup()
            return headerView
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowHeader {
            return headerView?.calculateHeight() ?? 120
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch selectedTab {
        case .details: break
        case .related: openUserDetails(postsManager.recommendedUsers[indexPath.row])
        }
    }
}

// MARK: - BHPostHeaderViewDelegate

extension BHPostDetailsViewController: BHPostHeaderViewDelegate {

    func postHeaderView(_ view: BHPostHeaderView, didSelectShare shareLink: URL) {
        presentShareDialog(with: [shareLink], configureBlock: { controller in
            controller.popoverPresentationController?.sourceView = view.shareButton
        })
    }    
    
    func postHeaderView(_ view: BHPostHeaderView, didSelectUser user: BHUser) {
        openUserDetails(user)
    }

    func postHeaderView(_ view: BHPostHeaderView, didSelectTabBarItem item: BHPostHeaderView.Tabs) {
        selectedTab = item
        tableView.reloadData()
    }
}

