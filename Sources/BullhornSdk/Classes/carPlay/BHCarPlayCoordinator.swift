
import CarPlay
import Foundation

public class BHCarPlayCoordinator {
    
    var providers = [BHPlayableContentProvider]()

    let downloadsManager: BHDownloadsManager

    let carPlayController = BHPlayableContentController.shared

    // MARK: - Initialization

    public init() {
        BHLog.p("CarPlay coordinator init")
        
        downloadsManager = BHDownloadsManager.shared
        downloadsManager.addListener(self)
    }
        
    // MARK: CPTemplateApplicationSceneDelegate
    
    /// Connects the root template to the CPInterfaceController.
    public func connect(_ interfaceController: CPInterfaceController) {
        BHLog.p("Connected to CarPlay window.")

        initProviders(interfaceController)
        
        carPlayController.connect(to: interfaceController, with: providers)
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .carplay, action: .ui, banner: .carplayConnect)
        BHTracker.shared.trackEvent(with: request)
    }
    
    /// Called when CarPlay disconnects.
    public func disconnect() {
        BHLog.p("Disconnected from CarPlay window.")
        
        carPlayController.disconnect()
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
