
import UIKit
import Foundation
import SafariServices

extension UIApplication {

    func openURLWithoutCompletion(_ url: URL) {
        open(url, options: [:], completionHandler: nil)
    }
    
    class func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
        
        var rootVC: UIViewController?

        if viewController != nil {
            rootVC = viewController
        } else {
            let firstScene = UIApplication.shared.connectedScenes.first(where: { $0.isMember(of: UIWindowScene.self) }) as? UIWindowScene
            let firstWindow = firstScene?.windows.first
            rootVC = firstWindow?.rootViewController
        }

        if let navVC = rootVC as? UINavigationController {
            return topViewController(navVC.visibleViewController)
        }
        if let tabVC = rootVC as? UITabBarController {
            if let selectedVC = tabVC.selectedViewController {
                return topViewController(selectedVC)
            }
        }
        if let presentedVC = rootVC?.presentedViewController {
            return topViewController(presentedVC)
        }

        return rootVC
    }
        
    class func topNavigationController(_ viewController: UIViewController? = nil) -> UINavigationController? {
        
        var rootVC: UIViewController?

        if viewController != nil {
            rootVC = viewController
        } else {
            let firstScene = UIApplication.shared.connectedScenes.first(where: { $0.isMember(of: UIWindowScene.self) }) as? UIWindowScene
            let firstWindow = firstScene?.windows.first
            rootVC = firstWindow?.rootViewController
        }

        if let navVC = rootVC as? UINavigationController {
            return navVC
        }
            
        if let tabVC = rootVC as? UITabBarController {
            return tabVC.selectedViewController as? UINavigationController
        }

        return rootVC?.navigationController
    }
}
