
import UIKit
import FoxKitProfile
import BullhornSdk

class LoginViewController: AuthViewController {
    
    static let storyboardIdentifier = "LoginViewController"

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var privacyView: UIView!
    @IBOutlet weak var emailField: InputTextField!
    @IBOutlet weak var passwordField: InputTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var agreementTextView: UITextView!
    @IBOutlet weak var progressOverlay: UIView!
    @IBOutlet weak var inputErrorView: UITextView!

    @IBOutlet weak var contentCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var contantBottomConstraint: NSLayoutConstraint!

    fileprivate var isInputValid: Bool = true {
        didSet {
            inputErrorView.isHidden = isInputValid
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self

        let agreementStyle = NSMutableParagraphStyle()
        agreementStyle.alignment = .center
        agreementTextView.delegate = self
        agreementTextView.addHyperLinksToText(originalText: "Terms of Use | Privacy Policy | Your Privacy Choices", style: agreementStyle, hyperLinks: ["Terms of Use" : AuthConfig.shared.termsOfUse, "Privacy Policy" : AuthConfig.shared.privacyPolicy, "Your Privacy Choices" :  AuthConfig.shared.privacyChoices])

        let font = UIFont.fontWithName(.robotoBold, size: 19)
        let loginTitle = NSLocalizedString("Log In", comment: "")
        let attrLoginTitle = NSAttributedString(string: loginTitle, attributes: [
            NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor : UIColor.white])
        loginButton.setAttributedTitle(attrLoginTitle, for: UIControl.State.normal)

        let signupTitle = NSLocalizedString("Create Account", comment: "")
        let attrSignupTitle = NSAttributedString(string: signupTitle, attributes: [
            NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor : UIColor.white])
        signupButton.setAttributedTitle(attrSignupTitle, for: UIControl.State.normal)

        emailField.textContentType = .username
        emailField.keyboardType = .emailAddress
        emailField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        
        inputErrorView.text = NSLocalizedString("Please enter a valid email and password.", comment: "")
        inputErrorView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        inputErrorView.layer.cornerRadius = 4
        inputErrorView.layer.borderWidth = 1
        inputErrorView.layer.borderColor = UIColor.accent().cgColor
        inputErrorView.backgroundColor = .accent().withAlphaComponent(0.1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        isInputValid = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        progressOverlay.isHidden = true
        contentView.isHidden = false
        privacyView.isHidden = false
        
        validateLoginButton()
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @IBAction func performLogin(_ sender: Any) {
        var inputValid = true

        if isEmailValid(text: emailField.text) && isPasswordNotEmpty() {
            isInputValid = true
        } else {
            isInputValid = false
            inputValid = false
        }

        if !inputValid {
            return
        }

        progressOverlay.isHidden = false
        
        AuthService.shared.loginWith(email: emailField.text!, password: passwordField.text!
            ) { [weak self] success in
                guard let self = self else { return }
                
                progressOverlay.isHidden = true
                if success {
                    AuthService.shared.store(foxAuth: AuthService.shared.encodedProfile)
                    loginBullhornSdk()
                } else {
                    if let message = AuthService.shared.serviceErrorMessage {
                        showError(message)
                    } else {
                        isInputValid = false
                    }

                    debugPrint("Login error: \(AuthService.shared.serviceErrorDescription)")
                }
            }
    }
    
    @IBAction func emailTextFieldChanged(_ sender: UITextField) {
        validateLoginButton()
    }

    @IBAction func passwordTextFieldChanged(_ sender: UITextField) {
        validateLoginButton()
    }

    @IBAction func forgotPassword(_ sender: Any) {
        if let url = URL(string: AuthConfig.shared.forgotPassword) {
            showSafari(url)
        }
    }
    
    // MARK: - Private methods
    
    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

        if (endFrame?.origin.y ?? 0) >= UIScreen.main.bounds.size.height {
            contentCenterYConstraint.priority = .required
            contantBottomConstraint.priority = .defaultLow
            contantBottomConstraint.constant = 0
        } else {
            contentCenterYConstraint.priority = .defaultLow
            contantBottomConstraint.priority = .required
            contantBottomConstraint.constant = 2 * (endFrame?.size.height ?? 0) / 3
        }

        UIView.animate(
            withDuration: (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0,
            delay: TimeInterval(0),
            options: UIView.AnimationOptions.curveEaseInOut,
            animations: { self.view.layoutIfNeeded() },
            completion: nil
        )
    }

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

    private func isEmailNotEmpty() -> Bool {
        return emailField.text?.isEmpty == false
    }

    private func isPasswordNotEmpty() -> Bool {
        return passwordField.text?.isEmpty == false
    }

    private func validateLoginButton() {
        if isEmailNotEmpty() && isPasswordNotEmpty() {
            loginButton.isEnabled = true
            loginButton.backgroundColor = .controlEnabled()
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = .controlDisabled()
        }
        loginButton.layer.cornerRadius = 4.0
    }
}
