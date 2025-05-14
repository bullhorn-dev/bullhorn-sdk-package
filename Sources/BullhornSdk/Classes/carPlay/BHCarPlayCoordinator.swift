
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

        initProviders(interfaceController)
        
        let networkId = BHAppConfiguration.shared.networkId

        if BHReachabilityManager.shared.isConnected() {
            feedManager.fetchPosts(networkId) { _ in }
            radioManager.fetch(networkId) { _ in }
        } else {
            feedManager.fetchStorageEpisodes(networkId) { _ in }
            radioManager.fetchStorageRadios(networkId) { _ in }
        }
        downloadsManager.updateItems()

        carPlayController.connect(to: interfaceController, with: providers)
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .carplay, action: .ui, banner: .carplayConnect)
        BHTracker.shared.trackEvent(with: request)
    }
    
    /// Called when CarPlay disconnects.
    public func disconnect() {
        BHLog.p("Disconnected from CarPlay window.")
        
        carPlayController.disconnect()
        
        feedManager.removeListener(self)
        radioManager.removeListener(self)
        downloadsManager.removeListener(self)
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .carplay, action: .ui, banner: .carplayDisconnect)
        BHTracker.shared.trackEvent(with: request)
    }

    // MARK: - Private

    fileprivate func initProviders(_ interfaceController: CPInterfaceController) {

        let postEvents = BHFeedEventsPlayableContentProvider.init(with: feedManager, interfaceController: interfaceController)
        let radioEvents = BHRadioPlayableContentProvider(with: radioManager, interfaceController: interfaceController)
        let downloads = BHDownloadsPlayableContentProvider(with: downloadsManager, interfaceController: interfaceController)

        providers = [postEvents, radioEvents, downloads]
    }
}

// MARK: - BHNetworkManagerListener

extension BHCarPlayCoordinator: BHNetworkManagerListener {

    func networkManagerDidUpdatePosts(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.carPlayController.reload()
        }
    }
    
    func networkManagerDidFetchPosts(_ manager: BHNetworkManager) {
        BHLog.p("CarPlay \(#function)")

        DispatchQueue.main.async {
            self.carPlayController.reload()
        }
    }
}

// MARK: - BHRadioStreamsListener

extension BHCarPlayCoordinator: BHRadioStreamsListener {
    
    func radioStreamsManager(_ manager: BHRadioStreamsManager, radioDidChange radio: BHRadio) {
        BHLog.p("CarPlay \(#function)")

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
