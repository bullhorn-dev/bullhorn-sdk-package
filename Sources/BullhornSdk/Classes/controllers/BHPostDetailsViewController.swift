
import UIKit
import Foundation
import SDWebImage

enum BHPostTabs: Int {
    case details = 0
    case transcript
}

class BHPostDetailsViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    fileprivate static let UserDetailsSegueIdentifier = "PostDetailsVC.UserDetailsSegueIdentifier"

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    fileprivate var refreshControl: UIRefreshControl?

    fileprivate var headerView: BHPostHeaderView?

    fileprivate var postsManager = BHPostsManager()

    fileprivate var selectedUser: BHUser?
    
    fileprivate var shouldShowHeader: Bool = false
    
    fileprivate var selectedIndexPaths = Set<IndexPath>()

    var post: BHPost?
    var selectedTab: BHPostTabs = .details
    var context: String?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        bottomView.backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        let descriptionCellNib = UINib(nibName: "BHPostDescriptionCell", bundle: bundle)
        let transcriptCellNib = UINib(nibName: "BHPostTranscriptCell", bundle: bundle)
        let headerNib = UINib(nibName: "BHPostHeaderView", bundle: bundle)

        tableView.register(descriptionCellNib, forCellReuseIdentifier: BHPostDescriptionCell.reusableIndentifer)
        tableView.register(transcriptCellNib, forCellReuseIdentifier: BHPostTranscriptCell.reusableIndentifer)
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
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        refreshControl?.resetUIState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        refreshControl?.endRefreshing()
        
        postsManager.post = nil
        postsManager.transcript = nil
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Episode Details", comment: "")
        
        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis")?.withConfiguration(config), style: .plain, target: self, action: #selector(openOptionsAction(_:)))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "More Options"

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
    
    fileprivate func fetch(initial: Bool = false) {
        guard let validPost = post else { return }

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

            postsManager.fetchStorage(postId: validPost.id) { response in
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

        postsManager.fetch(postId: validPost.id, context: context, loadTranscript: validPost.hasTranscript) { response in
            switch response {
            case .success:
                break
            case .failure(error: _):
                if BHReachabilityManager.shared.isConnected() {
                    self.showError("Failed to load episode details. This episode is no longer available.")
                } else if !initial {
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }
    
    fileprivate func refreshTranscriptForPosition(_ position: Double = 0) {
        
        if !UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled { return }

        if position < 0 && selectedTab == .transcript {
            selectedIndexPaths.removeAll()
            tableView.reloadData()
        }
        
        guard let validPost = post else { return }
        guard let playerPost = BHHybridPlayer.shared.post else { return }

        if validPost.id != playerPost.id { return }
        if selectedTab != .transcript { return }

        if let index = BHHybridPlayer.shared.transcript?.segmentIndex(for: position), index >= 0 {
            let indexPath = IndexPath(row: index, section: 0)

            var indexPathsToReload = selectedIndexPaths
            indexPathsToReload.insert(indexPath)

            selectedIndexPaths.removeAll()
            selectedIndexPaths.insert(indexPath)

            tableView.reloadRows(at: Array(indexPathsToReload), with: .none)
        } else {
            selectedIndexPaths.removeAll()
            tableView.reloadData()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHPostDetailsViewController.UserDetailsSegueIdentifier, let vc = segue.destination as? BHUserDetailsViewController {
            vc.user = selectedUser
        }
    }
    
    // MARK: - Private
    
    override func onPlayerPositionChanged(_ position: Double, duration: Double) {
        super.onPlayerPositionChanged(position, duration: duration)
        refreshTranscriptForPosition(position)
    }
    
    override func onPlayerPlaybackCompleted() {
        super.onPlayerPlaybackCompleted()
        refreshTranscriptForPosition(-1)
    }

    override func openUserDetails(_ user: BHUser?) {
        selectedUser = user
        performSegue(withIdentifier: BHPostDetailsViewController.UserDetailsSegueIdentifier, sender: self)
    }
    
    private func openPlayer(position: Double) {
        guard let validPost = post else { return }
        
        if BHHybridPlayer.shared.isPostActive(validPost.id) {
            BHHybridPlayer.shared.seek(to: position, resume: true)
        } else {
            BHHybridPlayer.shared.playRequest(with: validPost, playlist: [], position: position)
        }
        BHHybridPlayer.shared.isTranscriptActive = true
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
        if !shouldShowHeader { return 0 }
        
        switch selectedTab {
        case .details:
            headerView?.tabTitleLabel.alpha = 1
            tableView.restore()
            return 1
        case .transcript:
            if postsManager.transcriptSegments.count == 0 && !activityIndicator.isAnimating {
                let bundle = Bundle.module
                let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)

                tableView.setEmptyMessage("Transcript is not available", image: image, topOffset: (headerView?.calculateHeight() ?? 120) / 2)
            } else {
                tableView.restore()
            }
            headerView?.tabTitleLabel.alpha = postsManager.transcriptSegments.count > 0 ? 1 : 0

            return postsManager.transcriptSegments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .details:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostDescriptionCell.reusableIndentifer, for: indexPath) as! BHPostDescriptionCell
            cell.text = postsManager.post?.description
            return cell
        case .transcript:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostTranscriptCell.reusableIndentifer, for: indexPath) as! BHPostTranscriptCell
            cell.isSelected = selectedIndexPaths.contains(indexPath)
            cell.postId = post?.id
            cell.segment = postsManager.transcriptSegments[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowHeader {
            headerView?.setup(selectedTab)
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
        case .details:
            break
        case .transcript:
            if UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled {
                openPlayer(position: postsManager.transcriptSegments[indexPath.row].start)
            }
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

    func postHeaderView(_ view: BHPostHeaderView, didSelectTabBarItem item: BHPostTabs) {
        selectedTab = item
        tableView.reloadData()
    }
    
    func postHeaderView(_ view: BHPostHeaderView, didGetError message: String) {
        showError(message)
    }
}

