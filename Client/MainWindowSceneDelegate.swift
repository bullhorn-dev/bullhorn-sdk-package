
import UIKit

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
}

