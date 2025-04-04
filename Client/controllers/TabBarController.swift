
import UIKit
import BullhornSdk

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startObserving(&ThemesManager.shared)
        
        setupAppearance()
    }
    
    // MARK: - Private
    
    fileprivate func setupAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        let tabBarItemAppearance = UITabBarItemAppearance()

        tabBarItemAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.fontWithName(.robotoMedium, size: 11),
            NSAttributedString.Key.foregroundColor: UIColor.primary()]
        tabBarItemAppearance.normal.iconColor = UIColor.primary()

        tabBarItemAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.fontWithName(.robotoMedium, size: 11),
            NSAttributedString.Key.foregroundColor: UIColor.accent()]
        tabBarItemAppearance.selected.iconColor = UIColor.accent()

        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.backgroundColor = .primaryBackground()

        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
    }
}
