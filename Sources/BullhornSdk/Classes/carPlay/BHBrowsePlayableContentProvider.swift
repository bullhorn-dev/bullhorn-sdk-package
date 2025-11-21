
import Foundation
import CarPlay

class BHBrowsePlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title = NSLocalizedString("Browse", comment: "")
    fileprivate(set) var iconName = "carplay-library.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("No podcasts yet", comment: "")

    var carplayInterfaceController: CPInterfaceController?

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

        if BHReachabilityManager.shared.isConnected() {
            exploreManager.fetch(networkId) { _ in
                DispatchQueue.main.async {
                    self.loadItems()
                }
            }
        } else {
            exploreManager.fetchStorage(networkId) { _ in
                DispatchQueue.main.async {
                    self.loadItems()
                }
            }
        }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module, hasSearch: false)
    }
        
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
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
                let model = UICategoryModel(id: 0, title: "Recent Searches", users: recentPodcasts)
                let recent = self.convertCategories([model])
                sections.append(CPListSection(items: recent))
            }
            sections.append(CPListSection(items: items, header: "All Categories", sectionIndexTitle: nil))
        } else {
            sections.append(CPListSection(items: items))
        }

        listTemplate.updateSections(sections)
    }
}

// MARK: - BHNetworkManagerListener

extension BHBrowsePlayableContentProvider: BHNetworkManagerListener {

    func networkManagerDidFetch(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {}
    
    func networkManagerDidUpdateUsers(_ manager: BHNetworkManager) {}
}

// MARK: - BHExploreManagerListener

extension BHBrowsePlayableContentProvider: BHExploreManagerListener {

    func exploreManagerDidFetch(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func exploreManagerDidFetchRecent(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func exploreManagerDidUpdateItems(_ manager: BHExploreManager) {
        DispatchQueue.main.async {
            self.loadItems()
        }
    }
}
