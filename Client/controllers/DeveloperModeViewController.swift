
import UIKit
import BullhornSdk

class DeveloperModeViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var networkLabel: UILabel!

    private var dropDownTextField: DropDownTextField!

    private var networks = [
        DropDownItem(value: AuthConfig.shared.networkId, title: "Fox"),
        DropDownItem(value: AuthConfig.shared.testNetworkId, title: "Test"),
        DropDownItem(value: AuthConfig.shared.nazarNetworkId, title: "Nazar")
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()

        addDropDown()
        configureNavigationItems()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DeveloperModeViewController.dismissKeyboard)))
    }
    
    private func addDropDown() {
        let lm = networkLabel.layoutMargins
        let height: CGFloat = 44.0
        let dropDownFrame = CGRect(x: 20, y: lm.bottom + 50, width: contentView.bounds.width - 2 * 20, height: height)
        dropDownTextField = DropDownTextField(frame: dropDownFrame, title: "Enter network ID", options: networks)
        dropDownTextField.delegate = self
        contentView.addSubview(dropDownTextField)
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
        guard let networkId = dropDownTextField.text else { return }
        
        setNetwork(networkId)
    }
    
    // MARK: - Private
    
    fileprivate func validateSaveButton() {
        if let uuid = dropDownTextField.text, let _ = UUID(uuidString: uuid) {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    fileprivate func setNetwork(_ networkId: String) {
        BullhornSdk.shared.resetNetwork(with: networkId)
        UserDefaults.standard.networkId = networkId
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
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
    
    func menuDidAnimate(up: Bool) {}
}

