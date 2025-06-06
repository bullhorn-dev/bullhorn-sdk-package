import UIKit
import Foundation

final class BHConnectionLostBottomSheet: BHBottomSheetController {

    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var acceptButton: UIButton!
    private var cancelButton: UIButton!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        super.loadView()

        // image

        let bundle = Bundle.module
        let image = UIImage(named: "ic_connection_lost.png", in: bundle, with: nil)
        
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleToFill
        imageView.image = image

        // title

        titleLabel = UILabel()
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        titleLabel.textColor = .primary()
        titleLabel.textAlignment = .center
        titleLabel.text = "The Internet connection is lost"
        
        // description

        descriptionLabel = UILabel()
        descriptionLabel.font = .fontWithName(.robotoLight, size: 15)
        descriptionLabel.textColor = .primary()
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 3
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.text = "Looks like you're offline, but no worries, it's time to listen to your downloads!"

        // accept button
        
        acceptButton = UIButton(type: .system)
        acceptButton.setTitle("Let's do that", for: .normal)
        acceptButton.setTitleColor(.accent(), for: .normal)
        acceptButton.titleLabel?.font = .fontWithName(.robotoRegular, size: 18)
        acceptButton.tintColor = .accent()
        acceptButton.addTarget(self, action: #selector(onAcceptPress(_:)), for: .touchUpInside)

        // cancel button

        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("No, thanks", for: .normal)
        cancelButton.setTitleColor(.tertiary(), for: .normal)
        cancelButton.titleLabel?.font = .fontWithName(.robotoRegular, size: 18)
        cancelButton.tintColor = .tertiary()
        cancelButton.addTarget(self, action: #selector(onCancelPress(_:)), for: .touchUpInside)

        let verticalStackView = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            descriptionLabel,
            acceptButton,
            cancelButton
        ])
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .center
        verticalStackView.distribution = .fill
        verticalStackView.spacing = Constants.paddingVertical / 2

        view.addSubview(verticalStackView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 184),
            imageView.heightAnchor.constraint(equalToConstant: 150),

            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            verticalStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: Constants.paddingHorizontal),
            verticalStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -Constants.paddingHorizontal),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func onAcceptPress(_ sender: Any) {
        dismiss(animated: true)

        let bundle = Bundle.module
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: BHDownloadsViewController.storyboardIndentifer)

        UIApplication.topNavigationController()?.pushViewController(viewController, animated: true)
    }
    
    @objc private func onCancelPress(_ sender: Any) {
        dismiss(animated: true)
    }
}

