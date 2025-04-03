
import Foundation
import CarPlay

class BHFeedEventsPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Home", comment: "")
    fileprivate(set) var iconName: String = "carplay-home.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var playlist: [BHPost]?

    let manager: BHNetworkManager

    var items = [CPListItem]()

    var listTemplate: CPListTemplate!

    // MARK: - Initialization

    init(manager: BHNetworkManager) {
        self.manager = manager
        self.listTemplate = composeCPListTemplate()    }

    // MARK: - Private

    fileprivate func convertEvents(_ posts: [BHPost]) -> [CPListItem] {
        return posts.map { $0.toCPListItem(with: Bundle.module) }
    }

    fileprivate func feedEventsFilterMethod() -> (BHPost) -> Bool {
        return { $0.recording?.publishUrl != nil }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }

    func loadItems() {
        
        let data = self.manager.posts
        self.items = self.convertEvents(data)
        self.playlist = data
        
        updateSectionsForList()
    }
}
