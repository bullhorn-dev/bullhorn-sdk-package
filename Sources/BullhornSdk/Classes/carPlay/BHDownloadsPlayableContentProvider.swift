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

    let downloadsManager: BHDownloadsManager!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        downloadsManager = BHDownloadsManager.shared

        listTemplate = composeCPListTemplate()
        carplayInterfaceController = interfaceController

        downloadsManager.addListener(self)
        downloadsManager.updateItems()
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
        downloadsManager.removeListener(self)
    }

    func loadItems() {
        let data = downloadsManager.completedItems
        self.items = self.convertDownloadItems(data)
        self.playlist = data.map({ $0.post })
        
        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        listTemplate.updateSections([CPListSection(items: items)])
        
        for (index, item) in items.enumerated() {
            item.handler = { [weak self] item, completion in
                guard let self = self else { completion(); return }
                BHLog.p("CarPlay item selected")
                
                if let playlist = self.playlist, index < playlist.count {
                    let post = playlist[index]
                    let orderedQueue = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: playlist, order: .straight)
                    self.play(post, playlist: orderedQueue, autoplayContext: nil)
                }
                
                if let listItem = item as? CPListItem {
                    self.updatePlayingItem(listItem, items: self.items)
                }

                completion()
            }
        }
    }
}

// MARK: - BHDownloadsManagerListener

extension BHDownloadsPlayableContentProvider: BHDownloadsManagerListener {

    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem) {
        if item.status == .success {
            DispatchQueue.main.async {
                self.loadItems()
            }
        }
    }

    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem) {}

    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool) {
        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager) {
        DispatchQueue.main.async {
            self.loadItems()
        }
    }
}

