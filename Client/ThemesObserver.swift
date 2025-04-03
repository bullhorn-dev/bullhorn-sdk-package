
import Foundation
import UIKit

protocol ThemesObserver: AnyObject {
    func startObserving(_ manager: inout ThemesManager)
    func themesManager(_ manager: ThemesManager, didChangeStyle style: UIUserInterfaceStyle)
}

extension UIViewController: ThemesObserver {
    
    func startObserving(_ manager: inout ThemesManager) {
        manager.addObserver(self)
        overrideUserInterfaceStyle = manager.currentStyle
    }
    
    func themesManager(_ manager: ThemesManager, didChangeStyle style: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension UIView: ThemesObserver {
    
    func startObserving(_ manager: inout ThemesManager) {
        manager.addObserver(self)
        overrideUserInterfaceStyle = manager.currentStyle
    }
    
    func themesManager(_ manager: ThemesManager, didChangeStyle style: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = style
    }
}

// MARK: - WeakThemesObserver

struct WeakThemesObserver {
    weak var observer: ThemesObserver?
}
