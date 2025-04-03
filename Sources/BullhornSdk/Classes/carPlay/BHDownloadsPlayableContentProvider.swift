
import Foundation
import CarPlay

class BHDownloadsPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title = NSLocalizedString("Downloads", comment: "")
    fileprivate(set) var iconName = "carplay-downloads.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("No episode downloaded yet", comment: "")

    var playlist: [BHPost]?

    let manager: BHDownloadsManager

    var items = [CPListItem]()

    var listTemplate: CPListTemplate!

    // MARK: - Initialization

    init(manager: BHDownloadsManager) {
        self.manager = manager
        self.listTemplate = composeCPListTemplate()
    }

    // MARK: - Private

    fileprivate func convertDownloadItems(_ downloadItems: [BHDownloadItem]) -> [CPListItem] {
        return downloadItems.map { $0.post.toCPListItem(with: Bundle.module) }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }

    func loadItems() {

        let data = self.manager.completedItems
        self.items = self.convertDownloadItems(data)
        self.playlist = self.manager.items.map({ $0.post })
        
        updateSectionsForList()
    }
}
