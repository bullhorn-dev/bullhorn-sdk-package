
import Foundation
import CarPlay

class BHRadioPlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Radio", comment: "")
    fileprivate(set) var iconName: String = "carplay-radio.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var carplayInterfaceController: CPInterfaceController?

    var items = [CPListItem]()

    var streams = [BHStream]()
    var streamsRowItem = CPListImageRowItem()

    var listTemplate: CPListTemplate!
    var placeholderImage: UIImage!

    let radioManager: BHRadioStreamsManager!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        radioManager = BHRadioStreamsManager.shared
        radioManager.addListener(self)

        carplayInterfaceController = interfaceController
        listTemplate = composeCPListTemplate()
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: Bundle.module, with: nil)
    }

    // MARK: - Private

    fileprivate func feedEventsFilterMethod() -> (BHPost) -> Bool {
        return { $0.recording?.publishUrl != nil }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }
    
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
        radioManager.removeListener(self)
    }

    func loadItems() {
        
        let post = BHRadioStreamsManager.shared.radios.first?.asPost()
        streams = BHRadioStreamsManager.shared.radios.first?.streams ?? []
        streamsRowItem = convertRadioStreamsToImageRowItem("Live Radio Streams", streams: streams, post: post, placeholderImage: placeholderImage)

        let radios = BHRadioStreamsManager.shared.otherRadios.map({ $0.asPost()! })
        self.items = self.convertEpisodes(radios)
        
        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        var sections: [CPListSection] = []

        if streams.count > 0 {
            sections.append(CPListSection(items: [streamsRowItem]))
        }

        sections.append(CPListSection(items: items))

        listTemplate.updateSections(sections)
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
