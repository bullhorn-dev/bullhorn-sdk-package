
import Foundation
import CarPlay

class BHHomePlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Home", comment: "")
    fileprivate(set) var iconName: String = "carplay-home.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var carplayInterfaceController: CPInterfaceController?

    var followedPodcasts = [BHUser]()
    var featuredPodcasts = [BHUser]()
    var liveEpisodes = [BHPost]()
    var featuredEpisodes = [BHPost]()
    var recentEpisodes = [BHPost]()

    var followedPodcastsRowItem = CPListImageRowItem()
    var featuredPodcastsRowItem = CPListImageRowItem()
    var items = [CPListItem]() /// live episodes
    var featuredEpisodesListItem = CPListItem()
    var recentEpisodesListItem = CPListItem()

    var listTemplate: CPListTemplate!
    
    var placeholderImage: UIImage!

    let networkManager: BHNetworkManager!
    let userManager: BHUserManager!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        networkManager = BHNetworkManager.shared
        userManager = BHUserManager.shared

        networkManager.addListener(self)
        userManager.addListener(self)

        listTemplate = composeCPListTemplate()
        carplayInterfaceController = interfaceController
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: Bundle.module, with: nil)
                
        let networkId = BHAppConfiguration.shared.networkId

        if BHReachabilityManager.shared.isConnected() {
            networkManager.fetch(networkId) { _ in
                DispatchQueue.main.async {
                    self.loadItems()
                }
            }
        } else {
            networkManager.fetchStorage(networkId) { _ in
                DispatchQueue.main.async {
                    self.loadItems()
                }
            }
        }
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
        networkManager.removeListener(self)
        userManager.removeListener(self)
    }

    func loadItems() {
        
        liveEpisodes = BHNetworkManager.shared.liveNowPosts
        items = convertEpisodes(liveEpisodes)

        followedPodcasts = BHUserManager.shared.followedUsers
        followedPodcastsRowItem = convertPodcastsToImageRowItem("Followed Podcasts", podcasts: followedPodcasts, placeholderImage: placeholderImage)
        
        featuredPodcasts = BHNetworkManager.shared.featuredUsers
        featuredPodcastsRowItem = convertPodcastsToImageRowItem("Featured Podcasts", podcasts: featuredPodcasts, placeholderImage: placeholderImage)

        featuredEpisodes = BHNetworkManager.shared.featuredPosts
        featuredEpisodesListItem = convertEpisodesToListItem("Featured Episodes", episodes: featuredEpisodes)

        let recentTitle = "Latest Episodes"
        recentEpisodes = BHNetworkManager.shared.posts
        recentEpisodesListItem = convertEpisodesToListItem(recentTitle, episodes: recentEpisodes, handler: false)
        recentEpisodesListItem.handler = { item, completion in
            BHLog.p("CarPlay recent episodes list item selected")

            if BHReachabilityManager.shared.isConnected() {
                let networkId = BHAppConfiguration.shared.networkId
                BHNetworkManager.shared.fetchPosts(networkId) { result in
                    DispatchQueue.main.async {
                        self.recentEpisodes = BHNetworkManager.shared.posts
                        self.convertEpisodesToCPListTemplate(self.recentEpisodes, title: recentTitle)
                        completion()
                    }
                }
            } else {
                self.convertEpisodesToCPListTemplate(self.recentEpisodes, title: recentTitle)
                completion()
            }
        }

        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        var sections: [CPListSection] = []

        if liveEpisodes.count > 0 {
            sections.append(CPListSection(items: items, header: "Live Episodes", sectionIndexTitle: nil))
        }
        
        if followedPodcasts.count > 0 {
            if followedPodcasts.count > 2 {
                sections.append(CPListSection(items: [followedPodcastsRowItem]))
            } else {
                let model = UICategoryModel(category: BHUserCategory(id: 0, alias: "followed", shareLink: nil, name: "Followed Podcasts"), users: followedPodcasts)
                let followed = self.convertCategories([model])
                sections.append(CPListSection(items: followed))
            }
        }
        
        if featuredPodcasts.count > 0 {
            if featuredPodcasts.count > 2 {
                sections.append(CPListSection(items: [featuredPodcastsRowItem]))
            } else {
                let model = UICategoryModel(category: BHUserCategory(id: 0, alias: "featured", shareLink: nil, name: "Featured Podcasts"), users: featuredPodcasts)
                let featured = self.convertCategories([model])
                sections.append(CPListSection(items: featured))
            }
        }
        
        if featuredEpisodes.count > 0 {
            sections.append(CPListSection(items: [featuredEpisodesListItem]))
        }
        
        if recentEpisodes.count > 0 {
            sections.append(CPListSection(items: [recentEpisodesListItem]))
        }

        listTemplate.updateSections(sections)
        listTemplate.tabTitle = title
    }
}

// MARK: - BHNetworkManagerListener

extension BHHomePlayableContentProvider: BHNetworkManagerListener {

    func networkManagerDidFetch(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }
    
    func networkManagerDidUpdateUsers(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }
}

// MARK: - BHUserManagerListener

extension BHHomePlayableContentProvider: BHUserManagerListener {

    func userManagerDidUpdateFollowedUsers(_ manager: BHUserManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.loadItems()
        }
    }
    
    func userManagerDidFetchPosts(_ manager: BHUserManager) {}
    
    func userManagerDidUpdatePosts(_ manager: BHUserManager) {}
}

