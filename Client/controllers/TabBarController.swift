
import UIKit
import BullhornSdk

class TabBarController: UITabBarController {
    
    fileprivate static let LoginSegueIdentifier = "LoginSegueIdentifier"
    fileprivate static let SignupSegueIdentifier = "SignupSegueIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        startObserving(&ThemesManager.shared)
        
        setupAppearance()

        NotificationCenter.default.addObserver(self, selector: #selector(onLoginRequiredNotification(_:)), name: BullhornSdk.OpenLoginNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSignUpRequiredNotification(_:)), name: BullhornSdk.OpenSignUpNotification, object: nil)
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
    
    // MARK: - Notifications
    
    @objc fileprivate func onLoginRequiredNotification(_ notification: Notification) {
        self.performSegue(withIdentifier: TabBarController.LoginSegueIdentifier, sender: self)
    }

    @objc fileprivate func onSignUpRequiredNotification(_ notification: Notification) {
        self.performSegue(withIdentifier: TabBarController.SignupSegueIdentifier, sender: self)
    }
}
