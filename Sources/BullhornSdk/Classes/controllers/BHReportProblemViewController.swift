
import UIKit
import Foundation

enum ReportReason: String, CaseIterable {
    case experiencingABug = "Experiencing a bug"
    case inappropriateContent = "Inappropriate content"
    case spam = "Spam"
    case scam = "Scam"
    case hateOrNegativeSpeech = "Hate or negative speech"
    case incitesViolence = "Incites violence"
    case other = "Other"
}

class BHReportProblemViewController: UIViewController, ActivityIndicatorSupport {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reasonLabel: UILabel!
    @IBOutlet weak var reasonTextField: BHDropDownTextField!
    @IBOutlet weak var reasonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: BHInputTextField!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var detailsTextField: UITextView!

    var reportReason: String?
    var reportName: String?
    var reportDetails: String?

    private var reasons: [BHDropDownItem] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()
        
        contentView.backgroundColor = .fxPrimaryBackground()

        configureNavigationItems()

        reasons = ReportReason.allCases.map({ BHDropDownItem(value: $0.rawValue, title: $0.rawValue, extra: false) })

        reasonTextField.delegate = self
        reasonTextField.textField.placeholder = "Select the reason of problem"
        reasonTextField.options = reasons
        reasonTextField.textField.textColor = .primary()

        reasonLabel.font = .primaryButton()
        reasonLabel.textColor = .primary()
        reasonLabel.text = "What is the problem?"
        reasonLabel.adjustsFontForContentSizeCategory = true
        
        nameLabel.font = .primaryButton()
        nameLabel.textColor = .primary()
        nameLabel.text = "Where is the problem?"
        nameLabel.adjustsFontForContentSizeCategory = true

        nameTextField.placeholder = "Enter page or name of show"
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

        detailsLabel.font = .primaryButton()
        detailsLabel.textColor = .primary()
        detailsLabel.text = "Add problem details"
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

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BHReportProblemViewController.dismissKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let validReportReason = reportReason {
            reasonTextField.textField.text = validReportReason
        }
        
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

        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton

        validateSendButton()
    }

    fileprivate func validateSendButton() {
        var changed = false

        if let reason = reasonTextField.text, !reason.isEmpty,
           let name = nameTextField.text, !name.isEmpty,
           let details = detailsTextField.text, !details.isEmpty, details != "Describe the bug or problem you're experiencing"
        {
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
        guard let user = BHAccountManager.shared.user else { return }
        
        defaultShowActivityIndicatorView()

        let systemInfo: [String : String] = [
            "who_reported": user.id,
            "app_version": BHAppConfiguration.shared.appVersion(),
            "device_info": BHDeviceUtils.shared.getDeviceName(),
        ]
        let report: [String : Any] =  [
            "reason": reportReason ?? "",
            "username": reportName ?? "",
            "details": reportDetails ?? "",
            "system_info": systemInfo
        ]
        let reportObj: [String : Any] = [
            "report": report
        ]
        
        BHSettingsManager.shared.reportProblem(reportObj) { response in
            DispatchQueue.main.async {
                self.defaultHideActivityIndicatorView()

                switch response {
                case .success:
                    /// track event
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sendReport, context: self.reportReason, variant: self.reportName)
                    BHTracker.shared.trackEvent(with: request)

                    self.showInfo("Report has been sent successfully")
                    self.navigationController?.popViewController(animated: true)
                case .failure(error: let error):
                    self.showError("Failed to send report. \(error.localizedDescription)")
                }
            }
        }
    }
}

//MARK: Drop down textfield delegate

extension BHReportProblemViewController: BHDropDownTextFieldDelegate {
    
    func textChanged(text: String?) {
        reportReason = text
        validateSendButton()
    }
    
    func optionSelected(option: String) {
        BHLog.p("Option selected: \(option)")
        reportReason = option
        validateSendButton()
    }
    
    func menuDidAnimate(up: Bool) {
        BHLog.p("menuDidAnimate: \(up)")
        
        if up {
            reasonHeightConstraint.constant = 44.0
        } else {
            reasonHeightConstraint.constant = 44.0 + CGFloat(reasons.count) * 40.0
        }
    }
}

// MARK: - UITextFieldDelegate

extension BHReportProblemViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        reportName = text
        validateSendButton()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        reportName = textField.text
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
