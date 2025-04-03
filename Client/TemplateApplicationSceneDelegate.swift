
import CarPlay
import UIKit
import BullhornSdk

/// `TemplateApplicationSceneDelegate` is the UIScenDelegate and CPTemplateApplicationSceneDelegate.
class TemplateApplicationSceneDelegate: NSObject {
    
    /// The coordinator handles the connection to CarPlay and manages the displayed templates.
    let carPlayCoordinator = BHCarPlayCoordinator()
    
    // MARK: UISceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if scene is CPTemplateApplicationScene, session.configuration.name == SceneConfiguration.carPlay {
            debugPrint("CarPlay application scene will connect.")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.carPlay {
            debugPrint("CarPlay application scene did disconnect.")
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.carPlay {
            debugPrint("CarPlay application scene did become active.")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.carPlay {
            debugPrint("CarPlay application scene will resign active.")
        }
    }
}

// MARK: CPTemplateApplicationSceneDelegate

extension TemplateApplicationSceneDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        debugPrint("CarPlay application scene did connect.")
        carPlayCoordinator.connect(interfaceController)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        carPlayCoordinator.disconnect()
        debugPrint("CarPlay application scene did disconnect.")
    }
}

