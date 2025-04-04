
import UIKit
import BullhornSdk

class SettingsViewController: UIViewController {
    
    fileprivate static let AppearanceSegueIdentifier = "Settings.AppearanceSegueIdentifier"
    fileprivate static let DeveloperModeSegueIdentifier = "Settings.DeveloperModeSegueIdentifier"
        
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(onApearanceRequiredNotification(_:)), name: BullhornSdk.OpenAppearanceNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDevModeRequiredNotification(_:)), name: BullhornSdk.OpenDevModeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        configureNavigationItems()
    }
    
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Profile", comment: "")
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onApearanceRequiredNotification(_ notification: Notification) {
        self.performSegue(withIdentifier: SettingsViewController.AppearanceSegueIdentifier, sender: self)
    }

    @objc fileprivate func onDevModeRequiredNotification(_ notification: Notification) {
        self.performSegue(withIdentifier: SettingsViewController.DeveloperModeSegueIdentifier, sender: self)
    }
}
