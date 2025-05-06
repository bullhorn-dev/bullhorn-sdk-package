
import CarPlay
import Foundation

protocol BHPlayableContentProvider {

    var identifier: String { get }
    var title: String { get }
    var iconName: String { get }
    var emptyListText: String { get }
    
    var playlist: [BHPost]? { get }

    var items: [CPListItem] { get }

    var carplayInterfaceController: CPInterfaceController? { get }

    var listTemplate: CPListTemplate! { get }

    func composeCPListTemplate() -> CPListTemplate
    func loadItems()
}

extension BHPlayableContentProvider {

    func composeCPListTemplateForTab(sections: [CPListSection], in bundle: Bundle) -> CPListTemplate {
        let configuration = CPAssistantCellConfiguration(position: .top, visibility: .off, assistantAction: .playMedia)
        let playlistTemplate = CPListTemplate(title: title, sections: [CPListSection(items: items)], assistantCellConfiguration: configuration)

        playlistTemplate.tabTitle = title
        playlistTemplate.emptyViewSubtitleVariants = [emptyListText]
        playlistTemplate.tabImage = UIImage.init(named: iconName, in: bundle, with: nil)

        return playlistTemplate
    }
    
    func updateSectionsForList() {
        
        listTemplate.updateSections([CPListSection(items: items)])
        
        for (index,item) in items.enumerated() {
            item.handler = { item, completion in
                BHLog.p("CarPlay item selected")
                
                if let post = self.playlist?[index] {
                    if BHHybridPlayer.shared.isPostPlaying(post.id) {
                        if let topTemplate = carplayInterfaceController?.topTemplate, !topTemplate.isMember(of: CPNowPlayingTemplate.self) {
                            carplayInterfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
                        }
                    } else {
                        BHHybridPlayer.shared.playRequest(with: post, playlist: self.playlist, context: "carplay")
                    }
                }
                
                if let listItem = item as? CPListItem {
                    self.updatePlayingItem(listItem)
                }

                completion()
            }
        }
    }
    
    func updatePlayingItem(_ item: CPListItem?) {
        
        items.forEach({ $0.isPlaying = false })
            
        guard let validItem = item else { return }
        
        validItem.isPlaying = true
        validItem.playingIndicatorLocation = .trailing
    }
    
    func updatePlayingItemForEpisode(_ title: String) {

        let item = items.first(where: { $0.text == title })
        updatePlayingItem(item)
    }
}
