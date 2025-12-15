
import Foundation
import CarPlay
import MediaPlayer

class BHPlayableContentController: NSObject {

    static let shared: BHPlayableContentController = BHPlayableContentController()

    /// A reference to the CPInterfaceController that passes in after connecting to CarPlay.
    private var carplayInterfaceController: CPInterfaceController?
    
    private var tabBarTemplate: CPTabBarTemplate?
    
    /// The CarPlay session configuation contains information on restrictions for the specified interface.
    var sessionConfiguration: CPSessionConfiguration!
    
    /// The observer of the Now Playing item changes.
    var nowPlayingItemObserver: NSObjectProtocol?
    
    /// The observer of the playback state changes.
    var playbackObserver: NSObjectProtocol?
    
    /// Top pushed episodes list
    var episodes = [BHPost]()
    var episodesListItems = [CPListItem]()
    
    ///
    var isConnected: Bool = false

    /// Tab content providers
    fileprivate var providers = [BHPlayableContentProvider]()
    
    fileprivate var playbackRateButton = CPNowPlayingPlaybackRateButton { button in
        BHHybridPlayer.shared.updateNextPlaybackSpeed()
    }

    
    // MARK: - Public

    /// Connects the root template to the CPInterfaceController.
    func connect(to interfaceController: CPInterfaceController, with providers: [BHPlayableContentProvider]) {

        carplayInterfaceController = interfaceController

        sessionConfiguration = CPSessionConfiguration(delegate: self)
        
        self.providers = providers
        self.providers.forEach { $0.loadItems() }

        let tabTemplates = self.providers.map { $0.listTemplate! }
        
        tabBarTemplate = CPTabBarTemplate(templates: tabTemplates)

        carplayInterfaceController?.delegate = self
        carplayInterfaceController?.setRootTemplate(tabBarTemplate!, animated: true, completion: nil)
        
        isConnected = true

        configureNowPlayingTemplate()

        BHHybridPlayer.shared.addListener(self)
    }
    
    /// Called when CarPlay disconnects.
    func disconnect() {
        BHLog.p("Disconnected from CarPlay window.")
        
        providers.forEach({ $0.disconnect() })
        providers = []
        nowPlayingItemObserver = nil
        playbackObserver = nil
        
        isConnected = false
                
        BHHybridPlayer.shared.pause()
        BHHybridPlayer.shared.removeListener(self)
    }


    func reload() {
        providers.forEach {
            $0.loadItems()
        }
        
        episodesListItems.forEach { item in
            let post = self.episodes.first(where: { $0.title == item.text })

            if let validPost = post, let row = episodesListItems.firstIndex(where: {$0.text == post?.title}) {
                var accessoryImage: UIImage?

                if validPost.isDownloaded {
                    accessoryImage = UIImage(systemName: "arrow.down.circle.fill")
                } else if validPost.isRadioStream() || validPost.isLiveStream() {
                    accessoryImage = UIImage(systemName: "dot.radiowaves.forward")
                }
                episodesListItems[row].setAccessoryImage(accessoryImage)
            }
        }
        
        guard let title = BHHybridPlayer.shared.playerItem?.post.title else { return }
        providers.forEach {
            $0.updatePlayingItemForEpisode(title)
        }
    }
    
    func searchPodcasts(_ searchText: String, completion: @escaping (CommonResult) -> Void) {
        BHLog.p("CarPlay search podcasts: \(searchText)")

        BHExploreManager.shared.getUsers(BHAppConfiguration.shared.networkId, text: searchText) { response in
            switch response {
            case .success(users: let users, page: _, pages: _):
                DispatchQueue.main.async {
                    if let provider = self.providers.first {
                        provider.openSearchedPodcasts(searchText, podcasts: users)
                    }
                }
                completion(.success)
            case .failure(error: let error):
                BHLog.w("Failed to fetch searched podcasts - \(error)")
                completion(.failure(error: error))
            }
        }
    }
    
    func searchEpisodes(_ searchText: String, completion: @escaping (CommonResult) -> Void) {
        BHLog.p("CarPlay search episodes: \(searchText)")

        BHExploreManager.shared.getPosts(BHAppConfiguration.shared.networkId, text: searchText) { response in
            switch response {
            case .success(posts: let posts, page: _, pages: _):
                DispatchQueue.main.async {
                    if let provider = self.providers.first {
                        provider.openSearchedEpisodes(searchText, episodes: posts)
                    }
                }
                completion(.success)
            case .failure(error: let error):
                BHLog.w("Failed to fetch searched episodes - \(error)")
                completion(.failure(error: error))
            }
        }
    }
    
    func presentAlert(title: String, message: String? = nil) {
        guard let interfaceController = carplayInterfaceController else { return }
        
        if interfaceController.presentedTemplate?.isMember(of: CPAlertTemplate.self) == true {
            BHLog.p("CarPlay CPAlertTemplate is already presented")
            return
        }
        
        BHLog.p("CarPlay present CPAlertTemplate, title: \(title), message: \(message ?? "nil")")

        let titleVariants = message == nil ? [title] : [title, message!]
        let okAction = CPAlertAction(title: "OK", style: .default) { action in
            self.carplayInterfaceController?.dismissTemplate(animated: true, completion: nil)
        }
        let actions = [okAction]
        let alert = CPAlertTemplate(titleVariants: titleVariants, actions: actions)

        interfaceController.presentTemplate(alert, animated: true, completion: nil)
    }
    
    func dismissAlertIfNeeded() {
        guard let interfaceController = carplayInterfaceController else { return }
        
        if interfaceController.presentedTemplate?.isMember(of: CPAlertTemplate.self) == true {
            interfaceController.dismissTemplate(animated: true, completion: nil)
        }
    }

    // MARK: - Private
    
    /// Add observers for playback and Now Playing item.
    private func configureNowPlayingTemplate() {
        CPNowPlayingTemplate.shared.add(self)
    }
    
    private func updatePlaybackRateButton() {
        if BHHybridPlayer.shared.playerItem?.isStream == true {
            playbackRateButton.isEnabled = false
            CPNowPlayingTemplate.shared.updateNowPlayingButtons([])
        } else {
            playbackRateButton.isEnabled = true
            CPNowPlayingTemplate.shared.updateNowPlayingButtons([playbackRateButton])
        }
    }
}

extension BHPlayableContentController: CPSessionConfigurationDelegate {

    internal func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        BHLog.w("CarPlay limited UI changed: \(limitedUserInterfaces)")
    }
}

// MARK: - BHHybridPlayerListener

extension BHPlayableContentController: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        guard let title = player.playerItem?.post.title else { return }
        guard let topTemplate = carplayInterfaceController?.topTemplate else { return }
        
        switch state {
        case .initializing:
            
            dismissAlertIfNeeded()

            providers.forEach({ $0.updatePlayingItemForEpisode(title) })
                        
            if !topTemplate.isMember(of: CPNowPlayingTemplate.self) {
                carplayInterfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            } else {
                updatePlaybackRateButton()
            }
        default:
            break
        }
    }
    
    func hybridPlayerDidClose(_ player: BHHybridPlayer) {
        guard let topTemplate = carplayInterfaceController?.topTemplate else { return }

        providers.forEach({ $0.updatePlayingItem(nil, items: $0.items) })

        if topTemplate.isMember(of: CPNowPlayingTemplate.self) {
            carplayInterfaceController?.popToRootTemplate(animated: true, completion: nil)
        }
    }
    
    func hybridPlayerDidFailedToPlay(_ player: BHHybridPlayer, error: Error?) {
        DispatchQueue.main.async {
            var message = "Failed to play episode."

            if BHReachabilityManager.shared.isConnected() {
                if let validError = error {
                    message += " \(validError.localizedDescription)"
                }
            } else {
                message += "The Internet connection is lost."
            }

            self.presentAlert(title: message)
        }
    }
}

// MARK: - CPNowPlayingTemplateObserver

extension BHPlayableContentController: CPNowPlayingTemplateObserver {

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
    
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {}
}

// MARK: - CPInterfaceControllerDelegate

extension BHPlayableContentController: CPInterfaceControllerDelegate {

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        BHLog.p("CarPlay \(aTemplate.tabTitle ?? "Unknown") will appear.")
        
        if aTemplate.isMember(of: CPNowPlayingTemplate.self) {
            updatePlaybackRateButton()
        }
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        BHLog.p("CarPlay \(aTemplate.tabTitle ?? "Unknown") did appear.")
        
        if let title = aTemplate.tabTitle {
            var banner: BHTrackBanner

            if title == "Home" {
                banner = .carplayOpenHome
            } else if title == "Browse" {
                banner = .carplayOpenBrowse
            } else if title == "Radio" {
                banner = .carplayOpenRadio
            } else {
                banner = .carplayOpenDownloads
            }
            
            /// track stats
            let request = BHTrackEventRequest.createRequest(category: .carplay, action: .ui, banner: banner)
            BHTracker.shared.trackEvent(with: request)
        }
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        BHLog.p("CarPlay \(aTemplate.tabTitle ?? "Unknown") will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        BHLog.p("CarPlay \(aTemplate.tabTitle ?? "Unknown") did disappear.")
    }
}
