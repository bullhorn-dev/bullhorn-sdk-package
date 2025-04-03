
import UIKit
import FoxKitProfile
import BullhornSdk

class SignupViewController: AuthViewController {
    
    static let storyboardIdentifier = "SignupViewController"
    
    override var rightButtonName: String {
        return "Cancel"
    }

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var emailField: InputTextField!
    @IBOutlet weak var passwordField: InputTextField!
    @IBOutlet weak var displayNameField: InputTextField!
    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var agreementTextView: UITextView!
    @IBOutlet weak var privacyChoicesTextView: UITextView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var progressOverlay: UIView!

    @IBOutlet weak var emailErrorView: UITextView!
    @IBOutlet weak var passwordErrorView: UITextView!
    @IBOutlet weak var nameErrorView: UITextView!
    @IBOutlet weak var agreementErrorView: UITextView!
    
    fileprivate var isEmailValid: Bool = true {
        didSet {
            emailErrorView.isHidden = isEmailValid
        }
    }

    fileprivate var isPasswordValid: Bool = true {
        didSet {
            passwordErrorView.isHidden = isPasswordValid
        }
    }

    fileprivate var isDisplayNameValid: Bool = true {
        didSet {
            nameErrorView.isHidden = isDisplayNameValid
        }
    }

    fileprivate var isAgreementValid: Bool = true {
        didSet {
            agreementErrorView.isHidden = isAgreementValid
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        displayNameField.delegate = self
        
        switchControl.setOn(false, animated: false)
        
        let agreementStyle = NSMutableParagraphStyle()
        agreementStyle.alignment = .left
        agreementTextView.delegate = self
        agreementTextView.addHyperLinksToText(originalText: "I have read and agree to the Fox News Terms of Use & Privacy Policy", style: agreementStyle, hyperLinks: ["Terms of Use" : AuthConfig.shared.termsOfUse, "Privacy Policy" : AuthConfig.shared.privacyPolicy])

        let privacyStyle = NSMutableParagraphStyle()
        privacyStyle.alignment = .center
        privacyChoicesTextView.delegate = self
        privacyChoicesTextView.addHyperLinksToText(originalText: "Your Privacy Choices", style: privacyStyle, hyperLinks: ["Your Privacy Choices" : AuthConfig.shared.privacyChoices])

        let font = UIFont.fontWithName(.robotoBold, size: 19)
        let title = NSLocalizedString("Create Account", comment: "")
        let attrTitle = NSAttributedString(string: title, attributes: [
            NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor : UIColor.white])
        signupButton.setAttributedTitle(attrTitle, for: UIControl.State.normal)
        signupButton.isEnabled = true
        signupButton.backgroundColor = .controlEnabled()
        signupButton.layer.cornerRadius = 4.0

        emailField.textContentType = .username
        emailField.keyboardType = .emailAddress
        emailField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)

        displayNameField.textContentType = .username
        displayNameField.keyboardType = .default
        displayNameField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        emailErrorView.text = NSLocalizedString("Please enter a valid email address.", comment: "")
        emailErrorView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        emailErrorView.layer.cornerRadius = 4
        emailErrorView.layer.borderWidth = 1
        emailErrorView.layer.borderColor = UIColor.accent().cgColor
        emailErrorView.backgroundColor = .accent().withAlphaComponent(0.1)

        passwordErrorView.text = NSLocalizedString("Password must be at least 8 characters, one number, one lowercase, and one uppercase.", comment: "")
        passwordErrorView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        passwordErrorView.layer.cornerRadius = 4
        passwordErrorView.layer.borderWidth = 1
        passwordErrorView.layer.borderColor = UIColor.accent().cgColor
        passwordErrorView.backgroundColor = .accent().withAlphaComponent(0.1)

        nameErrorView.text = NSLocalizedString("Display Name is required.", comment: "")
        nameErrorView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        nameErrorView.layer.cornerRadius = 4
        nameErrorView.layer.borderWidth = 1
        nameErrorView.layer.borderColor = UIColor.accent().cgColor
        nameErrorView.backgroundColor = .accent().withAlphaComponent(0.1)

        agreementErrorView.text = NSLocalizedString("Please read and agree to our terms and conditions.", comment: "")
        agreementErrorView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        agreementErrorView.layer.cornerRadius = 4
        agreementErrorView.layer.borderWidth = 1
        agreementErrorView.layer.borderColor = UIColor.accent().cgColor
        agreementErrorView.backgroundColor = .accent().withAlphaComponent(0.1)
        
        isEmailValid = true
        isPasswordValid = true
        isDisplayNameValid = true
        isAgreementValid = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        progressOverlay.isHidden = true
        contentView.isHidden = false
    }
            
    // MARK: - Actions
    
    @IBAction func performSignup(_ sender: Any) {
        var inputValid = true

        if isEmailValid(text: emailField.text) {
            isEmailValid = true
        } else {
            isEmailValid = false
            inputValid = false
        }

        if isPasswordValid(text: passwordField.text) {
            isPasswordValid = true
        } else {
            isPasswordValid = false
            inputValid = false
        }

        if isDisplayNameValid(text: displayNameField.text) {
            isDisplayNameValid = true
        } else {
            isDisplayNameValid = false
            inputValid = false
        }
        
        if switchControl.isOn {
            isAgreementValid = true
        } else {
            isAgreementValid = false
            inputValid = false
        }
        
        if !inputValid {
            return
        }

        progressOverlay.isHidden = false
        
        AuthService.shared.signupWith(email: emailField.text!, password: passwordField.text!, displayName: displayNameField.text) { [weak self] success in
            guard let self = self else { return }
                
            progressOverlay.isHidden = true

            if success {
                AuthService.shared.store(foxAuth: AuthService.shared.encodedProfile)
                loginBullhornSdk()
                navigationController?.popToRootViewController(animated: true)
            } else {
                let message = AuthService.shared.serviceErrorMessage ?? "Please enter a valid email, password, and display name"
                    showError(message)

                debugPrint("Sign Up error: \(AuthService.shared.serviceErrorDescription)")
            }
        }
    }
    
    @IBAction func emailTextFieldChanged(_ sender: UITextField) {
    }

    @IBAction func passwordTextFieldChanged(_ sender: UITextField) {
    }
    
    @IBAction func displayNameTextFieldChanged(_ sender: UITextField) {
    }
    
    @IBAction func switchAction(_ sender: Any) {
//        isAgreementValid = switchControl.isOn
    }
    
    // MARK: - Private methods
    
    private func loginBullhornSdk() {
        guard let profileInfo = AuthService.shared.profileInfo else { return }
        
        progressOverlay.isHidden = false

        var name = "Anonymous"
        if let displayName = profileInfo.displayName, displayName.count > 1 {
            name = displayName
        } else if let parts = profileInfo.email?.components(separatedBy: "@"), let shortName = parts.first {
            name = shortName
        }
        let bhUser = BHSdkUser(id: profileInfo.profileId, fullName: name, profilePictureUri: nil, level: .fox)

        BullhornSdk.shared.login(sdkUser: bhUser) { result in
            switch result {
            case .success(user: _):
                debugPrint("Login successfully")
                self.navigationController?.dismiss(animated: true)

            case .failure(error: let error):
                self.showError("Failed login to BullhornSdk")
                debugPrint(error)

            @unknown default:
                break
            }
        }
    }
}
