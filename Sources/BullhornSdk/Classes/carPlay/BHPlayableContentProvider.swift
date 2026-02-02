
import CarPlay
import Foundation
import SDWebImage

// MARK: - Images Result

enum ImagesResult {
    case success(images: [UIImage])
    case failure(error: Error)
}

protocol BHPlayableContentProvider {

    var identifier: String { get }
    var title: String { get }
    var iconName: String { get }
    var emptyListText: String { get }
    var items: [CPListItem] { get }
    var carplayInterfaceController: CPInterfaceController? { get }
    var listTemplate: CPListTemplate! { get }

    func composeCPListTemplate() -> CPListTemplate
    func loadItems()
    func disconnect()
}

extension BHPlayableContentProvider {
    
    // MARK: - Tab

    func composeCPListTemplateForTab(sections: [CPListSection], in bundle: Bundle, hasSearch: Bool = false) -> CPListTemplate {
        let configuration = CPAssistantCellConfiguration(position: .top, visibility: hasSearch ? .always: .off, assistantAction: .playMedia)
        let listTemplate = CPListTemplate(title: title, sections: sections, assistantCellConfiguration: configuration)

        listTemplate.tabTitle = title
        listTemplate.emptyViewSubtitleVariants = [emptyListText]
        listTemplate.tabImage = UIImage.init(named: iconName, in: bundle, with: nil)

        return listTemplate
    }

    // MARK: - Episodes

    func convertEpisodes(_ episodes: [BHPost]) -> [CPListItem] {
        let items = episodes.map { $0.toCPListItem(with: Bundle.module) }

        for (index, item) in items.enumerated() {
            item.handler = { item, completion in
                BHLog.p("CarPlay \(title) item selected")
                
                if index < episodes.count {
                    let post = episodes[index]
                    let playlist = BHHybridPlayer.shared.composeOrderedQueue(post.id, posts: episodes, order: .straight)
                    
                    self.play(post, playlist: playlist)
                    
                    /// update playing item
                    if let listItem = item as? CPListItem {
                        updatePlayingItem(listItem, items: items)
                    }
                }

                completion()
            }
        }
        
        /// update playing item
        updatePlayingItem(nil, items: items)

        return items
    }

    func convertEpisodesToCPListTemplate(_ episodes: [BHPost], title: String) {
        let items = self.convertEpisodes(episodes)

        BHPlayableContentController.shared.episodes = episodes
        BHPlayableContentController.shared.episodesListItems = items

        let configuration = CPAssistantCellConfiguration(position: .top, visibility: .off, assistantAction: .playMedia)
        let listTemplate = CPListTemplate(title: title, sections: [CPListSection(items: items)], assistantCellConfiguration: configuration)
        listTemplate.emptyViewSubtitleVariants = [self.emptyListText]

        self.carplayInterfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    func convertEpisodesToListItem(_ title: String, episodes: [BHPost], handler: Bool = true) -> CPListItem {
        let listItem = CPListItem(text: title, detailText: "", image: nil, accessoryImage: nil, accessoryType: .disclosureIndicator)

        if handler {
            listItem.handler = { item, completion in
                BHLog.p("CarPlay \(title) list item selected")
                convertEpisodesToCPListTemplate(episodes, title: title)
                completion()
            }
        }
        
        return listItem
    }
    
    // MARK: - Podcasts

    func convertPodcasts(_ podcasts: [BHUser]) -> [CPListItem] {
        let items = podcasts.map { $0.toCPListItem(with: Bundle.module) }

        for (index, item) in items.enumerated() {
            item.handler = { item, completion in
                BHLog.p("CarPlay \(title) item selected")
                
                if index < podcasts.count {
                    let user = podcasts[index]
                    let userManager = BHUserManager()
                    
                    userManager.getUserPosts(user.id, text: "") { response in
                        DispatchQueue.main.async {
                            switch response {
                            case .success(posts: let posts, page: _, pages: _):
                                convertEpisodesToCPListTemplate(posts, title: "Podcast Episodes")
                            case .failure(error: let error):
                                BHLog.w("User posts load failed \(error.localizedDescription)")
                                
                                var message = "Failed to load podcast episodes. "
                                if BHReachabilityManager.shared.isConnected() {
                                    message += " \(error.localizedDescription)"
                                } else {
                                    message += "The Internet connection is lost."
                                }
                                
                                presentAlert(message)
                            }
                        }
                    }
                }
                completion()
            }
        }
        
        return items
    }
    
    func convertPodcastsToCPListTemplate(title: String, podcasts: [BHUser]) {
        let items = self.convertPodcasts(podcasts)
        let configuration = CPAssistantCellConfiguration(position: .top, visibility: .off, assistantAction: .playMedia)
        let listTemplate = CPListTemplate(title: title, sections: [CPListSection(items: items)], assistantCellConfiguration: configuration)
        listTemplate.emptyViewSubtitleVariants = [self.emptyListText]

        self.carplayInterfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    func convertPodcastsToImageRowItem(_ title: String, podcasts: [BHUser], placeholderImage: UIImage, imagesCount: Int = CPMaximumNumberOfGridImages) -> CPListImageRowItem {
        let allowedPodcasts = podcasts.prefix(imagesCount)
        let images = allowedPodcasts.map({ _ in placeholderImage })

        let listImageRowItem = CPListImageRowItem(text: title, images: images)

        let urls = allowedPodcasts.map({ $0.coverUrl })
        fetchImages(urls, placeholderImage: placeholderImage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(images: let images):
                    listImageRowItem.update(images)
                case .failure(error: let error):
                    BHLog.w("CarPlay failed to load images for ImageRowItem. \(error)")
                }
            }
        }

        listImageRowItem.listImageRowHandler = { item, index, completion in
            BHLog.p("CarPlay \(title) image item \(index) selected")
            
            if index < podcasts.count {
                let user = podcasts[index]
                let userManager = BHUserManager()
                
                userManager.getUserPosts(user.id, text: "") { response in
                    DispatchQueue.main.async {
                        switch response {
                        case .success(posts: let posts, page: _, pages: _):
                            convertEpisodesToCPListTemplate(posts, title: "Podcast Episodes")
                        case .failure(error: let error):
                            BHLog.w("User posts load failed \(error.localizedDescription)")
                            
                            var message = "Failed to load podcast episodes. "
                            if BHReachabilityManager.shared.isConnected() {
                                message += " \(error.localizedDescription)"
                            } else {
                                message += "The Internet connection is lost."
                            }
                            
                            presentAlert(message)
                        }
                    }
                }
            }
            completion()
        }
        listImageRowItem.handler = { item, completion in
            BHLog.p("CarPlay \(title) list item selected")
            self.convertPodcastsToCPListTemplate(title: title, podcasts: podcasts)
            completion()
        }
        
        return listImageRowItem
    }
    
    func openSearchedPodcasts(_ searchText: String, podcasts: [BHUser]) {
        convertPodcastsToCPListTemplate(title: "Search for: \(searchText)", podcasts: podcasts)
    }

    func openSearchedEpisodes(_ searchText: String, episodes: [BHPost]) {
        convertEpisodesToCPListTemplate(episodes, title: "Search for: \(searchText)")
    }

    // MARK: - Categories
    
    func convertCategories(_ models: [UICategoryModel]) -> [CPListItem] {
        let items = models.map { $0.toCPListItem() }

        for (index, item) in items.enumerated() {
            item.handler = { item, completion in
                BHLog.p("CarPlay \(title) category item selected")
                
                if index < models.count {
                    let model = models[index]
                    
                    convertPodcastsToCPListTemplate(title: model.category.name ?? "Undefined", podcasts: model.users)
                }
                completion()
            }
        }
        
        return items
    }

    // MARK: - Utils

    func play(_ episode: BHPost, playlist: [BHPost]?) {
        if BHHybridPlayer.shared.isPostPlaying(episode.id) {
            if let topTemplate = self.carplayInterfaceController?.topTemplate, !topTemplate.isMember(of: CPNowPlayingTemplate.self) {
                self.carplayInterfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
        } else {
            let fileUrl: URL? = BHDownloadsManager.shared.getFileUrl(episode.id)
            
            if fileUrl == nil && !BHReachabilityManager.shared.isConnected() {
                presentAlert("Failed to play episode. The Internet connection is lost.")
            } else {
                BHHybridPlayer.shared.playRequest(with: episode, playlist: playlist, context: .carplay)
            }
        }
    }

    func updatePlayingItem(_ item: CPListItem?, items: [CPListItem]) {
        
        if item != nil {
            items.forEach({ $0.isPlaying = false })
            
            item?.isPlaying = true
            item?.playingIndicatorLocation = .trailing
            
            return
        }
        
        if let validPost = BHHybridPlayer.shared.post {
            items.forEach({
                if $0.text == validPost.title {
                    $0.isPlaying = true
                    $0.playingIndicatorLocation = .trailing
                } else {
                    $0.isPlaying = false
                }
            })
        } else {
            items.forEach({ $0.isPlaying = false })
        }
    }
    
    func updatePlayingItemForEpisode(_ title: String) {

        let item = items.first(where: { $0.text == title })
        updatePlayingItem(item, items: items)
        updatePlayingItem(item, items: BHPlayableContentController.shared.episodesListItems)
    }
    
    func presentAlert(_ message: String) {
        
        BHLog.p("CarPlay present alert, message: \(message)")

        let okAction = CPAlertAction(title: "OK", style: .default) { action in
            self.carplayInterfaceController?.dismissTemplate(animated: true, completion: nil)
        }
        let alert = CPAlertTemplate(titleVariants: [message], actions: [okAction])

        carplayInterfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
        
    internal func fetchImages(_ urls: [URL?], placeholderImage: UIImage, completion: @escaping (ImagesResult) -> Void) {

        let fetchGroup = DispatchGroup()
        var images = [UIImage]()
        
        for url in urls {
            
            fetchGroup.enter()
            
            SDWebImageManager.shared.loadImage(with: url) { _, _, _ in
                //
            } completed: { image, data, error, _, finished, _ in
                if finished && error == nil {
                    images.append(image ?? placeholderImage)
                } else if error != nil {
                    images.append(placeholderImage)
//                    responseError = error
                }
                fetchGroup.leave()
            }
        }
                                
        fetchGroup.notify(queue: .main) {
            completion(.success(images: images))
        }
    }
}
