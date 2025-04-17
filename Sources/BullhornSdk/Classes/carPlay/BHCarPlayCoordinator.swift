
import CarPlay
import Foundation

public class BHCarPlayCoordinator {
    
    let feedManager: BHNetworkManager
    let radioManager: BHRadioStreamsManager
    let downloadsManager: BHDownloadsManager

    var providers = [BHPlayableContentProvider]()

    let carPlayController = BHPlayableContentController.init()

    // MARK: - Initialization

    public init() {

        feedManager = BHNetworkManager.shared
        radioManager = BHRadioStreamsManager.shared
        downloadsManager = BHDownloadsManager.shared

        feedManager.addListener(self)
        radioManager.addListener(self)
        downloadsManager.addListener(self)
    }
        
    // MARK: CPTemplateApplicationSceneDelegate
    
    /// Connects the root template to the CPInterfaceController.
    public func connect(_ interfaceController: CPInterfaceController) {
        BHLog.p("Connected to CarPlay window.")

        initProviders()

        downloadsManager.fetchStorageItems()
        feedManager.fetchStorageEpisodes(BHAppConfiguration.shared.networkId) { _ in }
        radioManager.fetchStorageRadios(BHAppConfiguration.shared.networkId) { _ in }

        carPlayController.connect(to: interfaceController, with: providers)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .connectCarPlay)
        BHTracker.shared.trackEvent(with: request)
    }
    
    /// Called when CarPlay disconnects.
    public func disconnect() {
        BHLog.p("Disconnected from CarPlay window.")
        
        carPlayController.disconnect()
        
        feedManager.removeListener(self)
        radioManager.removeListener(self)
        downloadsManager.removeListener(self)
    }

    // MARK: - Private

    fileprivate func initProviders() {

        let postEvents = BHFeedEventsPlayableContentProvider.init(manager: feedManager)
        let radioEvents = BHRadioPlayableContentProvider(manager: radioManager)
        let downloads = BHDownloadsPlayableContentProvider(manager: downloadsManager)

        providers = [postEvents, radioEvents, downloads]
    }
}

// MARK: - BHNetworkManagerListener

extension BHCarPlayCoordinator: BHNetworkManagerListener {

    func networkManagerDidFetchPosts(_ manager: BHNetworkManager) {
        DispatchQueue.main.async {
            self.carPlayController.reload()
        }
    }
}

// MARK: - BHRadioStreamsListener

extension BHCarPlayCoordinator: BHRadioStreamsListener {
    
    func radioStreamsManager(_ manager: BHRadioStreamsManager, radioDidChange radio: BHRadio) {
        DispatchQueue.main.async {
            self.carPlayController.reload()
        }
    }
}

// MARK: - BHDownloadsManagerListener

extension BHCarPlayCoordinator: BHDownloadsManagerListener {

    func downloadsManager(_ manager: BHDownloadsManager, itemStateUpdated item: BHDownloadItem) {
        if item.status == .success || item.status == .start {
            DispatchQueue.main.async {
                self.carPlayController.reload()
            }
        }
    }
    
    func downloadsManager(_ manager: BHDownloadsManager, itemProgressUpdated item: BHDownloadItem) {}
    
    func downloadsManager(_ manager: BHDownloadsManager, allRemoved status: Bool) {
        DispatchQueue.main.async {
            self.carPlayController.reload()
        }
    }
    
    func downloadsManagerItemsUpdated(_ manager: BHDownloadsManager) {}
}
