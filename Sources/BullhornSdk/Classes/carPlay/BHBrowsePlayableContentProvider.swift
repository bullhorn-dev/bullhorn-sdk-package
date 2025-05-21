
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

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        self.listTemplate = composeCPListTemplate()
        self.carplayInterfaceController = interfaceController
        self.placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: Bundle.module, with: nil)
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
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
            sections.append(CPListSection(items: [recentPodcastsRowItem]))
            sections.append(CPListSection(items: items, header: "Categories", sectionIndexTitle: nil))
        } else {
            sections.append(CPListSection(items: items))
        }

        listTemplate.updateSections(sections)
    }
}

