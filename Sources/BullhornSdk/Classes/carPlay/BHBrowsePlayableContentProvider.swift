import Foundation
import CarPlay

class BHBrowsePlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title = NSLocalizedString("Browse", comment: "")
    fileprivate(set) var iconName = "carplay-library.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("No podcasts yet", comment: "")

    var carplayInterfaceController: CPInterfaceController?

    /// True while the initial network fetch is in flight. Used to show a "Loading…"
    /// placeholder only when there is nothing else to display.
    var isLoading = false

    /// Pending coalesced reload (see `scheduleReload()`).
    private var reloadWorkItem: DispatchWorkItem?

    var items = [CPListItem]()

    var recentPodcasts = [BHUser]()
    var recentPodcastsRowItem = CPListImageRowItem()

    var listTemplate: CPListTemplate!

    var placeholderImage: UIImage!
    
    let networkManager: BHNetworkManager!
    let exploreManager: BHExploreManager!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        networkManager = BHNetworkManager.shared
        exploreManager = BHExploreManager.shared
        
        networkManager.addListener(self)
        exploreManager.addListener(self)

        listTemplate = composeCPListTemplate()
        carplayInterfaceController = interfaceController
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: Bundle.module, with: nil)
        
        let networkId = BHAppConfiguration.shared.networkId

        isLoading = true
        updateSectionsForList()

        if BHReachabilityManager.shared.isConnected() {
            exploreManager.fetch(networkId) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.scheduleReload()
                }
            }
        } else {
            exploreManager.fetchStorage(networkId) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.scheduleReload()
                }
            }
        }
    }

    // MARK: - Private

    /// Coalesces bursts of listener callbacks into a single reload. Without this each
    /// callback rebuilds the image-row item from scratch, re-triggering cover downloads
    /// and causing visible flicker. Assumes the main thread.
    private func scheduleReload() {
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.loadItems()
        }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module, hasSearch: false)
    }
        
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
        reloadWorkItem?.cancel()
        networkManager.removeListener(self)
        exploreManager.removeListener(self)
    }

    func loadItems() {

        BHNetworkManager.shared.splitUsersForCarPlay()

        let data = BHNetworkManager.shared.carPlaySplittedUsers
        self.items = self.convertCategories(data)

        recentPodcasts = BHExploreManager.shared.recentUsers
        recentPodcastsRowItem = convertPodcastsToImageRowItem("Recent Searches", podcasts: recentPodcasts, placeholderImage: placeholderImage)

        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        var sections: [CPListSection] = []
        
        if recentPodcasts.count > 0 {
            if recentPodcasts.count > 2 {
                sections.append(CPListSection(items: [recentPodcastsRowItem]))
            } else {
                let model = UICategoryModel(category: BHCategory(id: 0, alias: "recent-searches", shareLink: nil, name: "Recent Searches"), users: recentPodcasts)
                let recent = self.convertCategories([model])
                sections.append(CPListSection(items: recent))
            }
            if items.count > 0 {
                sections.append(CPListSection(items: items, header: "All Categories", sectionIndexTitle: nil))
            }
        } else if items.count > 0 {
            sections.append(CPListSection(items: items))
        }

        /// Show "Loading…" only when the list is otherwise empty and a fetch is in flight.
        /// If anything (incl. offline cache) is already available, show it instead.
        if sections.isEmpty && isLoading {
            sections.append(CPListSection(items: [loadingListItem()]))
        }

        listTemplate.updateSections(sections)
    }
}

// MARK: - BHNetworkManagerListener

extension BHBrowsePlayableContentProvider: BHNetworkManagerListener {

    func networkManagerDidFetch(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {}
    
    func networkManagerDidUpdateUsers(_ manager: BHNetworkManager) {}
}

// MARK: - BHExploreManagerListener

extension BHBrowsePlayableContentProvider: BHExploreManagerListener {

    func exploreManagerDidFetch(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }

    func exploreManagerDidFetchRecent(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }

    func exploreManagerDidUpdateItems(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }
}

