
import UIKit
import BullhornSdk

class DeveloperModeViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var dropDownTextField: DropDownTextField!
    @IBOutlet weak var pushNotificationsView: UIView!
    @IBOutlet weak var pushNotificationsLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    @IBOutlet weak var networkHeightConstraint: NSLayoutConstraint!
    
    private let networkIdDefaultValue = UserDefaults.standard.networkId
    private let pushNotificationsEnabledDefaultValue = UserDefaults.standard.pushNotificationsEnabled

    private var networks = [
        DropDownItem(value: AuthConfig.shared.networkId, title: "Fox"),
        DropDownItem(value: AuthConfig.shared.testNetworkId, title: "Test"),
        DropDownItem(value: AuthConfig.shared.nazarNetworkId, title: "Nazar")
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()

        dropDownTextField.delegate = self
        dropDownTextField.textField.placeholder = "Enter network ID"
        dropDownTextField.options = networks

        networkLabel.font = UIFont.fontWithName(.robotoMedium, size: 17)
        networkLabel.textColor = .label

        pushNotificationsLabel.font = UIFont.fontWithName(.robotoMedium, size: 17)
        pushNotificationsLabel.textColor = .label

        switchControl.setOn(pushNotificationsEnabledDefaultValue, animated: true)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DeveloperModeViewController.dismissKeyboard)))
        pushNotificationsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DeveloperModeViewController.changeSwitch)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        validateSaveButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideTopMessageView()
    }
    
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Developer mode", comment: "")
        navigationItem.largeTitleDisplayMode = .never

        let config = UIImage.SymbolConfiguration(weight: .light)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark")?.withConfiguration(config), style: .plain, target: self, action: #selector(save(_:)))
    }

    @objc func save(_ sender: Any) {
        
        if let uuid = dropDownTextField.text, !uuid.isEmpty, let _ = UUID(uuidString: uuid), uuid != networkIdDefaultValue {
            setNetwork(uuid)
        }
        
        if switchControl.isOn != pushNotificationsEnabledDefaultValue {
            updatePushNotifications(switchControl.isOn)
        }
        
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func switchAction(_ sender: Any) {
        validateSaveButton()
    }

    // MARK: - Private
    
    fileprivate func validateSaveButton() {
        var changed = false

        if let uuid = dropDownTextField.text, !uuid.isEmpty, let _ = UUID(uuidString: uuid) {
            changed = true
        } else if switchControl.isOn != pushNotificationsEnabledDefaultValue {
            changed = true
        }

        if changed {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    fileprivate func setNetwork(_ networkId: String) {
        BullhornSdk.shared.resetNetwork(with: networkId)
        UserDefaults.standard.networkId = networkId
    }
    
    fileprivate func updatePushNotifications(_ value: Bool) {
        BullhornSdk.shared.enablePushNotifications(value)
        UserDefaults.standard.pushNotificationsEnabled = value
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc fileprivate func changeSwitch() {
        switchControl.setOn(!switchControl.isOn, animated: true)
        validateSaveButton()
    }
}

//MARK: Drop down textfield delegate

extension DeveloperModeViewController: DropDownTextFieldDelegate {
    
    func textChanged(text: String?) {
        validateSaveButton()
    }
    
    func optionSelected(option: String) {
        debugPrint("Option selected: \(option)")
        validateSaveButton()
    }
    
    func menuDidAnimate(up: Bool) {
        debugPrint("menuDidAnimate: \(up)")
        
        if up {
            networkHeightConstraint.constant = 44.0
        } else {
            networkHeightConstraint.constant = 44.0 + CGFloat(networks.count) * 40.0
        }
    }
}


