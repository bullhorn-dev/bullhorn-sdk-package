
import Foundation
import CarPlay
import MediaPlayer

class BHPlayableContentController: NSObject {

    /// A reference to the CPInterfaceController that passes in after connecting to CarPlay.
    private var carplayInterfaceController: CPInterfaceController?
    
    private var tabBarTemplate: CPTabBarTemplate?
    
    /// The CarPlay session configuation contains information on restrictions for the specified interface.
    var sessionConfiguration: CPSessionConfiguration!
    
    /// The observer of the Now Playing item changes.
    var nowPlayingItemObserver: NSObjectProtocol?
    
    /// The observer of the playback state changes.
    var playbackObserver: NSObjectProtocol?

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
                
        BHHybridPlayer.shared.pause()
        BHHybridPlayer.shared.removeListener(self)
    }


    func reload() {
        providers.forEach {
            $0.loadItems()
        }
        
        guard let title = BHHybridPlayer.shared.playerItem?.post.title else { return }
        providers.forEach {
            $0.updatePlayingItemForEpisode(title)
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
            
            providers.forEach({ $0.updatePlayingItemForEpisode(title) })
                        
            if !topTemplate.isMember(of: CPNowPlayingTemplate.self) {
                carplayInterfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true)
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
            carplayInterfaceController?.popToRootTemplate(animated: true)
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
