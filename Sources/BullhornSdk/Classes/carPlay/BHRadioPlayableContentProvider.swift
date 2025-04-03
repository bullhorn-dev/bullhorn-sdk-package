
import Foundation
import CarPlay

class BHRadioPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Radio", comment: "")
    fileprivate(set) var iconName: String = "carplay-radio.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var playlist: [BHPost]?

    let manager: BHRadioStreamsManager

    var items = [CPListItem]()

    var listTemplate: CPListTemplate!

    // MARK: - Initialization

    init(manager: BHRadioStreamsManager) {
        self.manager = manager
        self.listTemplate = composeCPListTemplate()
    }

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
        
        let data = self.manager.radios.map({ $0.asPost()! })
        self.items = self.convertEvents(data)
        self.playlist = data
        
        updateSectionsForList()
    }
}

