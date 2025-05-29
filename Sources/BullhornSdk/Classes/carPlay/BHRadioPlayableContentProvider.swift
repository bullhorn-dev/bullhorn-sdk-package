
import Foundation
import CarPlay

class BHRadioPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Radio", comment: "")
    fileprivate(set) var iconName: String = "carplay-radio.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var carplayInterfaceController: CPInterfaceController?

    var items = [CPListItem]()
    var playlist: [BHPost]?

    var listTemplate: CPListTemplate!

    let radioManager: BHRadioStreamsManager!
    let networkManager: BHNetworkManager!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        radioManager = BHRadioStreamsManager.shared
        networkManager = BHNetworkManager.shared

        radioManager.addListener(self)
        networkManager.addListener(self)

        carplayInterfaceController = interfaceController
        listTemplate = composeCPListTemplate()
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }
    
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
        radioManager.removeListener(self)
        networkManager.removeListener(self)
    }

    func loadItems() {
        
        let data = BHRadioStreamsManager.shared.radios.map({ $0.asPost()! })
        self.items = self.convertEpisodes(data)
        self.playlist = data

        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        listTemplate.updateSections([CPListSection(items: items)])
    }
}

// MARK: - BHRadioStreamsListener

extension BHRadioPlayableContentProvider: BHRadioStreamsListener {
    
    func radioStreamsManager(_ manager: BHRadioStreamsManager, radioDidChange radio: BHRadio) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }
}

// MARK: - BHNetworkManagerListener

extension BHRadioPlayableContentProvider: BHNetworkManagerListener {

    func networkManagerDidFetch(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {}
    
    func networkManagerDidUpdateUsers(_ manager: BHNetworkManager) {}
}
