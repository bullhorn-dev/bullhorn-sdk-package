
import CarPlay
import Foundation

public class BHCarPlayCoordinator {
    
    var providers = [BHPlayableContentProvider]()

    let carPlayController = BHPlayableContentController.init()

    // MARK: - Initialization

    public init() {
        BHLog.p("CarPlay coordinator init")
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
