
import UIKit
import Foundation

class BHAuthBottomSheet: BHBottomSheetController {
    
    private var titleLabel: UILabel!
    private var acceptButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openAuthDialog)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func loadView() {
        super.loadView()

        titleLabel = UILabel()
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        titleLabel.textColor = .primary()
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.text = "Sign in or create your free account to follow podcasts, like episodes and join in on the fun."

        acceptButton = UIButton(type: .system)
        acceptButton.setTitle("Sign In or Sign Up", for: .normal)
        acceptButton.setTitleColor(.navigationText(), for: .normal)
        acceptButton.titleLabel?.font = .fontWithName(.robotoMedium, size: 18)
        acceptButton.tintColor = .navigationText()
        acceptButton.backgroundColor = .navigationBackground()
        acceptButton.addTarget(self, action: #selector(onAcceptPress(_:)), for: .touchUpInside)
        
        let verticalStackView = UIStackView(arrangedSubviews: [
            titleLabel,
            acceptButton,
        ])
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .center
        verticalStackView.distribution = .fill
        verticalStackView.spacing = Constants.paddingVertical
        stackView.addArrangedSubview(verticalStackView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            acceptButton.widthAnchor.constraint(equalToConstant: 240),
            acceptButton.heightAnchor.constraint(equalToConstant: 54),
            
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            verticalStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: Constants.paddingHorizontal),
            verticalStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -Constants.paddingHorizontal),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        acceptButton.layer.cornerRadius = acceptButton.frame.size.height / 2
    }
        
    // MARK: - Action handlers
    
    @objc fileprivate func onAcceptPress(_ sender: Any) {
        NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
        dismiss(animated: true)
    }
}
