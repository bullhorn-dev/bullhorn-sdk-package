
import UIKit
import Foundation

class BHReportProblemViewController: UIViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: BHInputTextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: BHInputTextField!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var detailsTextField: UITextView!

    var reportName: String?
    var reportEmail: String?
    var reportDetails: String?

    private var reasons: [BHDropDownItem] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()
        
        contentView.backgroundColor = .fxPrimaryBackground()

        configureNavigationItems()

        nameLabel.text = "Name:"
        nameLabel.textColor = .primary()
        nameLabel.font = .primaryButton()
        nameLabel.adjustsFontForContentSizeCategory = true

        nameTextField.placeholder = "Enter your name"
        nameTextField.textColor = .primary()
        nameTextField.tintColor = .accent()
        nameTextField.autocapitalizationType = .sentences
        nameTextField.returnKeyType = .done
        nameTextField.keyboardType = .alphabet
        nameTextField.font = .secondaryButton()
        nameTextField.backgroundColor = .cardBackground()
        nameTextField.textInsets = .init(top: 12, left: 8, bottom: 12, right: 8)
        nameTextField.delegate = self
        nameTextField.adjustsFontForContentSizeCategory = true

        emailLabel.text = "Email:"
        emailLabel.textColor = .primary()
        emailLabel.font = .primaryButton()
        emailLabel.adjustsFontForContentSizeCategory = true

        emailTextField.placeholder = "Enter your email"
        emailTextField.textColor = .primary()
        emailTextField.tintColor = .accent()
        emailTextField.autocapitalizationType = .sentences
        emailTextField.returnKeyType = .done
        emailTextField.keyboardType = .emailAddress
        emailTextField.font = .secondaryButton()
        emailTextField.backgroundColor = .cardBackground()
        emailTextField.textInsets = .init(top: 12, left: 8, bottom: 12, right: 8)
        emailTextField.delegate = self
        emailTextField.adjustsFontForContentSizeCategory = true
        
        detailsLabel.text = "Describe your issue:"
        detailsLabel.textColor = .primary()
        detailsLabel.font = .primaryButton()
        detailsLabel.adjustsFontForContentSizeCategory = true
        
        detailsTextField.backgroundColor = .cardBackground()
        detailsTextField.tintColor = .accent()
        detailsTextField.font = .secondaryButton()
        detailsTextField.text = "Describe the bug or problem you're experiencing"
        detailsTextField.textColor = .lightGray
        detailsTextField.delegate = self
        detailsTextField.layer.borderColor = UIColor.divider().cgColor
        detailsTextField.layer.borderWidth = 1
        detailsTextField.layer.cornerRadius = 4
        detailsTextField.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        detailsTextField.adjustsFontForContentSizeCategory = true

        emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BHReportProblemViewController.dismissKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let validReportName = reportName {
            nameTextField.text = validReportName
        }
        
        if let validReportDetails = reportDetails {
            detailsTextField.text = validReportDetails
            detailsTextField.textColor = .primary()
        }
        
        validateSendButton()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openReportProblem)
        BHTracker.shared.trackEvent(with: request)
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {

        navigationItem.title = NSLocalizedString("Report a Problem", comment: "")
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(sendButtonAction(_:)))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Send Report"

        navigationItem.backButtonTitle = ""
        navigationItem.backBarButtonItem?.accessibilityLabel = "Back"

        validateSendButton()
    }

    fileprivate func validateSendButton() {
        var changed = false

        if let email = emailTextField.text, !email.isEmpty, email.isValidEmail(),
           let details = detailsTextField.text, !details.isEmpty, details != "Describe the bug or problem you're experiencing" {
            changed = true
        }

        if changed {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    
    // MARK: - Actions

    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc fileprivate func sendButtonAction(_ sender: Any) {
        
        defaultShowActivityIndicatorView()

        let params: [String : Any] =  [
            "name": reportName ?? "",
            "email": reportEmail ?? "",
            "description": reportDetails ?? ""
        ]
        
        BHSettingsManager.shared.reportProblem(params) { response in
            DispatchQueue.main.async {
                self.defaultHideActivityIndicatorView()

                switch response {
                case .success:
                    /// track event
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sendReport, context: self.reportDetails, variant: self.reportName)
                    BHTracker.shared.trackEvent(with: request)

                    self.showInfo("Report has been sent successfully")
                    self.navigationController?.popViewController(animated: true)
                case .failure(error: let error):
                    self.showError("Failed to send report. \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc fileprivate func textFieldDidChange(_ textField: UITextField) {
        validateSendButton()
    }
}

// MARK: - UITextFieldDelegate

extension BHReportProblemViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        if textField == nameTextField {
            reportName = text
        } else if textField == emailTextField {
            reportEmail = text
        }
        validateSendButton()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            nameTextField.resignFirstResponder()
            reportName = textField.text
        } else if textField == emailTextField {
            emailTextField.resignFirstResponder()
            reportEmail = textField.text
        }
        return true
    }
}

// MARK: - UITextViewDelegate

extension BHReportProblemViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .primary()
        }
        validateSendButton()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe the bug or problem you're experiencing"
            textView.textColor = .lightGray
        }
        reportDetails = textView.text
        validateSendButton()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        reportDetails = textView.text
        validateSendButton()
    }
}
