
import UIKit
import BullhornSdk

class MainWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene, session.configuration.name == SceneConfiguration.main else { return }
        
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        
        let bundle = Bundle(for: Self.self)
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
        let initialViewController = storyboard.instantiateInitialViewController()
        
        window?.rootViewController = initialViewController
        window?.windowScene = windowScene
        window?.makeKeyAndVisible()
                
        debugPrint("Main window scene will connect.")
        
        if let url = connectionOptions.userActivities.first?.webpageURL {
            handleDeepLink(url)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.main {
            debugPrint("Main window scene did disconnect.")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.main {
            debugPrint("Main window scene did become active.")
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.main {
            debugPrint("Main window scene will resign active.")
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.main {
            debugPrint("Main window scene will enter foreground.")
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if scene.session.configuration.name == SceneConfiguration.main {
            debugPrint("Main window scene did enter background.")
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeepLink(url)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else { return }
        guard let url = userActivity.webpageURL else { return }
        
        handleDeepLink(url)
    }
    
    // MARK: - Private
    
    private func handleDeepLink(_ url: URL) {
        debugPrint("Handle deep link: \(url.absoluteString)")

        if BullhornSdk.shared.shouldContinueUserActivity(url) {
            debugPrint("Main window scene: handle deep link \(url)")
        } else {
            debugPrint("Main window scene: failed to handle deep link \(url)")
        }
    }
}

