
import CarPlay
import Foundation

public class BHCarPlayCoordinator {
    
    let networkManager: BHNetworkManager
    let radioManager: BHRadioStreamsManager
    let downloadsManager: BHDownloadsManager

    var providers = [BHPlayableContentProvider]()

    let carPlayController = BHPlayableContentController.init()

    // MARK: - Initialization

    public init() {

        networkManager = BHNetworkManager.shared
        radioManager = BHRadioStreamsManager.shared
        downloadsManager = BHDownloadsManager.shared

        networkManager.addListener(self)
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
            networkManager.fetch(networkId) { _ in
                DispatchQueue.main.async {
                    self.carPlayController.reload()
                }
            }
        } else {
            networkManager.fetchStorage(networkId) { _ in
                DispatchQueue.main.async {
                    self.carPlayController.reload()
                }
            }
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
        
        networkManager.removeListener(self)
        radioManager.removeListener(self)
        downloadsManager.removeListener(self)
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .carplay, action: .ui, banner: .carplayDisconnect)
        BHTracker.shared.trackEvent(with: request)
    }

    // MARK: - Private

    fileprivate func initProviders(_ interfaceController: CPInterfaceController) {

        let home = BHHomePlayableContentProvider.init(with: interfaceController)
        let browse = BHBrowsePlayableContentProvider.init(with: interfaceController)
        let radio = BHRadioPlayableContentProvider(with: interfaceController)
        let downloads = BHDownloadsPlayableContentProvider(with: interfaceController)

        providers = [home, browse, radio, downloads]
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
