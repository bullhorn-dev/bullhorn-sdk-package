
import UIKit
import Foundation

class BHPlayerContainingViewController: UIViewController {

    @IBOutlet weak var miniPlayerView: BHMiniPlayerView!

    var searchController: UISearchController?
    var searchActive = false

    private var isActivatingSearch = false
    private var searchLeftContainer: UIView?
    private var searchMagnifierImageView: UIImageView?
    private var searchSpinner: UIActivityIndicatorView?

    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // The interactive mini player is a single app-wide instance installed
        // by BHMiniPlayerManager directly into the main window, above the root
        // view controller. The storyboard-embedded view stays only as a layout
        // spacer reserving space at the bottom.
        miniPlayerView.isSpacer = true

        miniPlayerView.constraints
            .first { ($0.firstItem as? UIView) === miniPlayerView
                && $0.firstAttribute == .height
                && $0.secondItem == nil
                && $0.relation == .equal }
            .map { $0.priority = UILayoutPriority(999) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        BHHybridPlayer.shared.addListener(self)
        BHMiniPlayerManager.shared.navigationRouter = self
        BHMiniPlayerManager.shared.containingScreenWillAppear()
        updateMiniPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideTopMessageView()

        if isMovingFromParent || isBeingDismissed {
            deactivateNavigationSearch()
        } else {
            searchController?.searchBar.resignFirstResponder()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        BHMiniPlayerManager.shared.containingScreenDidDisappear()
        BHHybridPlayer.shared.removeListener(self)
    }
    
    // MARK: - Private

    private func updateMiniPlayer() {
        if BHHybridPlayer.shared.playerItem == nil {
            miniPlayerView.isHidden = true
            return
        }
        miniPlayerView.isHidden = false
    }
    
    // MARK: - Internal (to override)
    
    func openUserDetails(_ user: BHUser?) {}
    
    func openPostDetails(_ post: BHPost?, tab: BHPostTabs = .details) {}
    
    func onPlayerStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        updateMiniPlayer()
    }
    
    func onPlayerPositionChanged(_ position: Double, duration: Double) {}

    func onPlayerPlaybackCompleted() {}

    // MARK: - Navigation search hooks (to override)

    /// The scroll view whose insets/offset the search machinery manages.
    func searchManagedTableView() -> UITableView? { return nil }

    /// Placeholder shown both in the in-content field and the navigation search bar.
    func searchBarPlaceholder() -> String {
        return NSLocalizedString("Search podcasts or episodes", comment: "")
    }

    /// Perform the actual fetch/filter for the given query.
    func performSearch(with text: String) {}

    /// Called after the navigation search bar appeared (collapse the header, etc.).
    func searchDidBecomeActive() {}

    /// Called after the navigation search bar was dismissed (restore the header, etc.).
    func searchDidResignActive() {}

    /// Whether the list already has results to show. When true, the redundant
    /// empty-query fetch that fires on activation is skipped.
    func hasExistingSearchResults() -> Bool { return false }

    // MARK: - Navigation search engine (shared)

    /// Build a fresh, styled search controller for a single search session.
    func makeSearchController() -> UISearchController {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.searchBar.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.hidesNavigationBarDuringPresentation = false
        sc.searchBar.placeholder = searchBarPlaceholder()
        styleSearchBar(sc.searchBar)
        return sc
    }

    func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .onAccent()

        let textField = searchBar.searchTextField
        textField.font = .settingsSecondaryText()
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .primary()
        textField.tintColor = .accent()
        textField.layer.cornerRadius = 18
        textField.clipsToBounds = true

        searchBar.setTextFiledColor(color: .cardBackground())
        searchBar.setClearButtonColor(to: .tertiary())
        searchBar.setPlaceholderTextColor(to: .secondary())

        searchBar.setPositionAdjustment(UIOffset(horizontal: -2, vertical: 0), for: .clear)
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 2, vertical: 0)

        let contentSize: CGFloat = 20
        let horizontalPadding: CGFloat = 2
        let container = UIView(frame: CGRect(x: 0, y: 0, width: contentSize + horizontalPadding * 2, height: contentSize))

        let magnifier = UIImageView(image: UIImage(systemName: "magnifyingglass")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)))
        magnifier.tintColor = .secondary()
        magnifier.contentMode = .center
        magnifier.frame = container.bounds
        container.addSubview(magnifier)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .secondary()
        spinner.hidesWhenStopped = true
        spinner.frame = container.bounds
        container.addSubview(spinner)

        searchLeftContainer = container
        searchMagnifierImageView = magnifier
        searchSpinner = spinner

        textField.leftView = container
        textField.leftViewMode = .always
    }

    /// Entry point: call this from the in-content search field tap.
    func activateNavigationSearch() {
        let sc = makeSearchController()
        searchController = sc
        isActivatingSearch = true

        navigationItem.searchController = sc
        navigationItem.hidesSearchBarWhenScrolling = false

        /// let the navigation bar lay out the bar, then activate it with the native animation
        DispatchQueue.main.async {
            sc.isActive = true
            sc.searchBar.becomeFirstResponder()
        }
    }

    func deactivateNavigationSearch() {
        isActivatingSearch = false
        searchLeftContainer = nil
        searchMagnifierImageView = nil
        searchSpinner = nil
        if searchController?.isActive == true {
            searchController?.isActive = false
        }
        navigationItem.searchController = nil
        searchController = nil
    }

    func setSearchBarLoading(_ loading: Bool) {
        guard let magnifier = searchMagnifierImageView, let spinner = searchSpinner else { return }

        if loading {
            magnifier.isHidden = true
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            magnifier.isHidden = false
        }
    }

    enum SearchHeaderReloadStyle {
        case sectionFade
        case crossDissolve
        case none
    }

    func reloadSearchHeader(scrollToTopWhenDone: Bool, style: SearchHeaderReloadStyle = .sectionFade) {
        guard let tableView = searchManagedTableView() else { return }

        let completion = { [weak self] in
            if scrollToTopWhenDone {
                self?.scrollSearchableToTop(animated: true)
            }
        }

        switch style {
        case .sectionFade:
            tableView.performBatchUpdates({
                tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }, completion: { _ in
                completion()
            })
        case .crossDissolve:
            UIView.transition(with: tableView, duration: 0.3, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                tableView.reloadData()
                tableView.layoutIfNeeded()
            }, completion: { _ in
                completion()
            })
        case .none:
            UIView.performWithoutAnimation {
                tableView.reloadData()
                tableView.layoutIfNeeded()
            }
            completion()
        }
    }

    func scrollSearchableToTop(animated: Bool) {
        guard let tableView = searchManagedTableView(), tableView.numberOfSections > 0 else { return }
        let topOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        tableView.setContentOffset(topOffset, animated: animated)
    }

    @objc fileprivate func runSearchDebounced() {
        performSearch(with: searchController?.searchBar.text ?? "")
    }
}


// MARK: - BHHybridPlayerListener

extension BHPlayerContainingViewController: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.updateMiniPlayer()
        }
    }
        
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {
        DispatchQueue.main.async {
            var message = "Failed to play episode. "
            
            if BHReachabilityManager.shared.isConnected() {
                if let validError = error {
                    message += " \(validError.localizedDescription)"
                }
            } else {
                message += "The Internet connection is lost."
            }
            if !BHHybridPlayer.shared.isFullScreen {
                self.showError(message)
            }
            self.onPlayerPlaybackCompleted()
        }
    }

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.onPlayerStateChanged(state, stateFlags: stateFlags)
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async {
            self.onPlayerPositionChanged(position, duration: duration)
        }
    }
    
    func hybridPlayerDidFinishPlaying(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.onPlayerPlaybackCompleted()
            self.updateMiniPlayer()
        }
    }
    
    func hybridPlayerDidClose(_ player: BHHybridPlayer) {
        DispatchQueue.main.async {
            self.updateMiniPlayer()
            self.onPlayerPlaybackCompleted()
        }
    }
}

// MARK: - BHPlayerBaseViewControllerDelegate

extension BHPlayerContainingViewController: BHPlayerBaseViewControllerDelegate {
    
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenUser user: BHUser) {
        openUserDetails(user)
    }
    
    func playerViewController(_ vc: BHPlayerBaseViewController, didRequestOpenPost post: BHPost) {
        openPostDetails(post)
    }
}

// MARK: - Navigation search delegates (shared)

extension BHPlayerContainingViewController: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {

    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""

        /// the search controller fires this once on activation with an empty query —
        /// skip that redundant fetch if we already have data to show
        if isActivatingSearch {
            isActivatingSearch = false
            if text.isEmpty && hasExistingSearchResults() {
                return
            }
        }

        /// debounce: don't fire a request on every keystroke
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(runSearchDebounced), object: nil)

        if text.isEmpty || text.count > 2 {
            perform(#selector(runSearchDebounced), with: nil, afterDelay: 0.35)
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        searchActive = true
        searchManagedTableView()?.bounces = false
        searchDidBecomeActive()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        searchActive = false
        searchManagedTableView()?.bounces = true
        deactivateNavigationSearch()
        searchDidResignActive()
    }
}
