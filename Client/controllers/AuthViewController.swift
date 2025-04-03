
import UIKit
import FoxKitProfile
import BullhornSdk
import SafariServices

class AuthViewController: UIViewController {
        
    var rightButtonName: String {
        return "Close"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightButtonName, style: .plain, target: self, action: #selector(onClose(_:)))

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AuthViewController.dismissKeyboard)))

        overrideUserInterfaceStyle = ThemesManager.shared.currentStyle
        setNeedsStatusBarAppearanceUpdate()

        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideTopMessageView()
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func onClose(_ sender: Any) {
        self.navigationController?.dismiss(animated: true)
    }

    // MARK: - Internal
    
    func showSafari(_ url: URL) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let safariVC = SFSafariViewController.init(url: url, configuration: config)
        safariVC.modalPresentationStyle = .automatic
        safariVC.preferredControlTintColor = UIColor.white
        safariVC.preferredBarTintColor = UIColor.controlEnabled()

        present(safariVC, animated: true, completion: nil)
    }
    
    func isEmailValid(text: String?) -> Bool {
        guard let validEmail = text else { return false }

        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        let regex = try! NSRegularExpression(pattern: emailRegEx)
        let nsRange = NSRange(location: 0, length: validEmail.count)
        let results = regex.matches(in: validEmail, range: nsRange)
        if results.count == 0 {
            return false
        }
        return true
    }
    
    func isPasswordValid(text: String?) -> Bool {
        guard let validPassword = text else { return false }

        let passwordreg = "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}"
        let passwordtesting = NSPredicate(format: "SELF MATCHES %@", passwordreg)
        return passwordtesting.evaluate(with: validPassword)
    }
    
    func isDisplayNameValid(text: String?) -> Bool {
        guard let validName = text else { return false }

        if validName.count < 2 {
            return false
        }
        return true
    }
    
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func onUserInterfaceStyleChangedNotification(notification: Notification) {
        guard let dict = notification.userInfo as? NSDictionary else { return }
        guard let value = dict["style"] as? Int else { return }
        
        let style = UIUserInterfaceStyle(rawValue: value) ?? .light

        overrideUserInterfaceStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - UITextFieldDelegate

extension AuthViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return true
    }
}

// MARK: - UITextViewDelegate

extension AuthViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        showSafari(url)
        return false
    }
}
