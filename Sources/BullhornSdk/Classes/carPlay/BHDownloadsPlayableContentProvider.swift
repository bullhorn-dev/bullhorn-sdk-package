
import Foundation
import CarPlay

class BHDownloadsPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title = NSLocalizedString("Downloads", comment: "")
    fileprivate(set) var iconName = "carplay-downloads.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("No episode downloaded yet", comment: "")

    var playlist: [BHPost]?

    var carplayInterfaceController: CPInterfaceController?

    var items = [CPListItem]()

    var listTemplate: CPListTemplate!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        listTemplate = composeCPListTemplate()
        carplayInterfaceController = interfaceController
        
        BHDownloadsManager.shared.updateItems()
    }

    // MARK: - Private

    fileprivate func convertDownloadItems(_ downloadItems: [BHDownloadItem]) -> [CPListItem] {
        return downloadItems.map { $0.post.toCPListItem(with: Bundle.module) }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }
    
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
    }

    func loadItems() {

        let data = BHDownloadsManager.shared.completedItems
        self.items = self.convertDownloadItems(data)
        self.playlist = BHDownloadsManager.shared.items.map({ $0.post })
        
        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        listTemplate.updateSections([CPListSection(items: items)])
        
        for (index,item) in items.enumerated() {
            item.handler = { item, completion in
                BHLog.p("CarPlay item selected")
                
                if let post = self.playlist?[index] {
                    let playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: self.playlist, order: .straight)
                    self.play(post, playlist: playlist)
                }
                
                if let listItem = item as? CPListItem {
                    self.updatePlayingItem(listItem, items: self.items)
                }

                completion()
            }
        }
    }
}
