
import Foundation
import CarPlay

class BHHomePlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Home", comment: "")
    fileprivate(set) var iconName: String = "carplay-home.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var items = [CPListItem]() /// live episodes

    var carplayInterfaceController: CPInterfaceController?

    var followedPodcasts = [BHUser]()
    var featuredPodcasts = [BHUser]()
    var liveEpisodes = [BHPost]()
    var featuredEpisodes = [BHPost]()
    var recentEpisodes = [BHPost]()

    var followedPodcastsRowItem = CPListImageRowItem()
    var featuredPodcastsRowItem = CPListImageRowItem()
    var liveItems = [CPListItem]()
    var featuredEpisodesListItem = CPListItem()
    var recentEpisodesRowItem = CPListItem()

    var listTemplate: CPListTemplate!
    
    var placeholderImage: UIImage!

    // MARK: - Initialization

    init(with interfaceController: CPInterfaceController) {
        self.listTemplate = composeCPListTemplate()
        self.carplayInterfaceController = interfaceController
        self.placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: Bundle.module, with: nil)
    }

    // MARK: - Private

    fileprivate func feedEventsFilterMethod() -> (BHPost) -> Bool {
        return { $0.recording?.publishUrl != nil }
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }

    func loadItems() {
        
        liveEpisodes = BHNetworkManager.shared.liveNowPosts
        liveItems = convertEpisodes(liveEpisodes)

        followedPodcasts = BHUserManager.shared.followedUsers
        followedPodcastsRowItem = convertPodcastsToImageRowItem("Followed Podcasts", podcasts: followedPodcasts, placeholderImage: placeholderImage, imagesCount: 3)
        
        featuredPodcasts = BHNetworkManager.shared.featuredUsers
        featuredPodcastsRowItem = convertPodcastsToImageRowItem("Featured Podcasts", podcasts: featuredPodcasts, placeholderImage: placeholderImage)

        featuredEpisodes = BHNetworkManager.shared.featuredPosts
        featuredEpisodesListItem = convertEpisodesToListItem("Featured Episodes", episodes: featuredEpisodes)

        recentEpisodes = BHNetworkManager.shared.posts
        recentEpisodesRowItem = convertEpisodesToListItem("Latest Episodes", episodes: recentEpisodes)

        updateSectionsForList()
    }
    
    func updateSectionsForList() {
        
        var sections: [CPListSection] = []

        if liveEpisodes.count > 0 {
            sections.append(CPListSection(items: liveItems))
        }
        
        if followedPodcasts.count > 0 {
            sections.append(CPListSection(items: [followedPodcastsRowItem]))
        }
        
        if featuredPodcasts.count > 0 {
            sections.append(CPListSection(items: [featuredPodcastsRowItem]))
        }
        
        if featuredEpisodes.count > 0 {
            sections.append(CPListSection(items: [featuredEpisodesListItem]))
        }
        
        if recentEpisodes.count > 0 {
            sections.append(CPListSection(items: [recentEpisodesRowItem]))
        }

        listTemplate.updateSections(sections)
        listTemplate.tabTitle = title
    }
}
