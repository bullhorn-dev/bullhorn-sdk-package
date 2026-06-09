import Foundation
import CarPlay

class BHHomePlayableContentProvider: BHPlayableContentProvider {

    var identifier: String { return String(describing: self) }

    fileprivate(set) var title: String = NSLocalizedString("Home", comment: "")
    fileprivate(set) var iconName: String = "carplay-home.png"
    fileprivate(set) var emptyListText: String = NSLocalizedString("There is nothing here", comment: "")
    
    var carplayInterfaceController: CPInterfaceController?

    /// True while the initial network fetch is in flight. Used to show a "Loading…"
    /// placeholder only when there is nothing else to display.
    var isLoading = false

    /// Pending coalesced reload (see `scheduleReload()`).
    private var reloadWorkItem: DispatchWorkItem?

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

        isLoading = true
        updateSectionsForList()

        if BHReachabilityManager.shared.isConnected() {
            networkManager.fetch(networkId) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.scheduleReload()
                }
            }
        } else {
            networkManager.fetchStorage(networkId) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.scheduleReload()
                }
            }
        }
    }

    // MARK: - Private

    fileprivate func feedEventsFilterMethod() -> (BHPost) -> Bool {
        return { $0.recording?.publishUrl != nil }
    }

    /// Coalesces bursts of listener callbacks (the fetch completion plus the several
    /// DidFetch / DidUpdate notifications that fire almost simultaneously) into a single
    /// reload. Without this each callback rebuilds the image-row items from scratch,
    /// re-triggering cover downloads and causing visible flicker. Assumes the main thread.
    private func scheduleReload() {
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.loadItems()
        }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    // MARK: - BHPlayableContentProvider

    func composeCPListTemplate() -> CPListTemplate {
        return composeCPListTemplateForTab(sections: [CPListSection(items: items)], in: Bundle.module)
    }
    
    func disconnect() {
        BHLog.p("CarPlay \(#function)")
        reloadWorkItem?.cancel()
        networkManager.removeListener(self)
        userManager.removeListener(self)
    }

    func loadItems() {
        
        liveEpisodes = BHNetworkManager.shared.liveNowPosts
        items = convertEpisodes(liveEpisodes, autoplayContext: nil)

        followedPodcasts = BHUserManager.shared.followedUsers
        followedPodcastsRowItem = convertPodcastsToImageRowItem("Followed Podcasts", podcasts: followedPodcasts, placeholderImage: placeholderImage)
        
        featuredPodcasts = BHNetworkManager.shared.featuredUsers
        featuredPodcastsRowItem = convertPodcastsToImageRowItem("Featured Podcasts", podcasts: featuredPodcasts, placeholderImage: placeholderImage)

        featuredEpisodes = BHNetworkManager.shared.featuredPosts
        featuredEpisodesListItem = convertEpisodesToListItem("Featured Episodes", episodes: featuredEpisodes, autoplayContext: .actual)

        let recentTitle = "Latest Episodes"
        recentEpisodes = BHNetworkManager.shared.posts
        recentEpisodesListItem = convertEpisodesToListItem(recentTitle, episodes: recentEpisodes, autoplayContext: .actual, handler: false)
        recentEpisodesListItem.handler = { item, completion in
            BHLog.p("CarPlay recent episodes list item selected")

            if BHReachabilityManager.shared.isConnected() {
                /// Push the screen with "Loading…" right away, then fill it once posts arrive.
                let listTemplate = self.pushLoadingEpisodesTemplate(title: recentTitle)
                let networkId = BHAppConfiguration.shared.networkId
                BHNetworkManager.shared.fetchPosts(networkId) { result in
                    DispatchQueue.main.async {
                        self.recentEpisodes = BHNetworkManager.shared.posts
                        self.fillEpisodes(self.recentEpisodes, into: listTemplate, autoplayContext: .actual)
                        completion()
                    }
                }
            } else {
                /// Offline: data is already cached, push the populated list directly.
                self.convertEpisodesToCPListTemplate(self.recentEpisodes, title: recentTitle, autoplayContext: .actual)
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
                let model = UICategoryModel(category: BHCategory(id: 0, alias: "followed", shareLink: nil, name: "Followed Podcasts"), users: followedPodcasts)
                let followed = self.convertCategories([model])
                sections.append(CPListSection(items: followed))
            }
        }
        
        if featuredPodcasts.count > 0 {
            if featuredPodcasts.count > 2 {
                sections.append(CPListSection(items: [featuredPodcastsRowItem]))
            } else {
                let model = UICategoryModel(category: BHCategory(id: 0, alias: "featured", shareLink: nil, name: "Featured Podcasts"), users: featuredPodcasts)
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

        /// Show "Loading…" only when the list is otherwise empty and a fetch is in flight.
        /// If anything (incl. offline cache) is already available, show it instead.
        if sections.isEmpty && isLoading {
            sections.append(CPListSection(items: [loadingListItem()]))
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
            self.isLoading = false
            self.scheduleReload()
        }
    }

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }
    
    func networkManagerDidUpdateUsers(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }
}

// MARK: - BHUserManagerListener

extension BHHomePlayableContentProvider: BHUserManagerListener {

    func userManagerDidUpdateFollowedUsers(_ manager: BHUserManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.isLoading = false
            self.scheduleReload()
        }
    }
    
    func userManagerDidFetchPosts(_ manager: BHUserManager) {}
    
    func userManagerDidUpdatePosts(_ manager: BHUserManager) {}
}

