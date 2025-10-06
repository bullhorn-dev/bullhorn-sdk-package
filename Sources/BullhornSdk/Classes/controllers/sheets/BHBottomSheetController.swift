import UIKit
import Foundation

open class BHBottomSheetController: UIViewController {

    public enum PreferredSheetSizing: CGFloat {
        case fit = 0 // Fit, based on the view's constraints
        case small = 0.25
        case medium = 0.5
        case large = 0.75
        case fill = 1
    }

    private lazy var bottomSheetTransitioningDelegate = BHBottomSheetTransitioningDelegate(
        preferredSheetTopInset: preferredSheetTopInset,
        preferredSheetCornerRadius: preferredSheetCornerRadius,
        preferredSheetSizingFactor: preferredSheetSizing.rawValue,
        preferredSheetBackdropColor: preferredSheetBackdropColor
    )
    
    var stackView = UIStackView()

    var sheetTitle: String?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)
    }
    
    open override func loadView() {

        view = UIView()
        view.backgroundColor = .cardBackground()

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        let buttonView = UIView(frame: .zero)
        buttonView.backgroundColor = .clear
        buttonView.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .roundedRect)
        closeButton.setTitle("", for: .normal)
        closeButton.backgroundColor = .tertiary()
        closeButton.layer.cornerRadius = 2
        closeButton.accessibilityLabel = "Dismiss popup"

        closeButton.addTarget(self, action: #selector(onCloseAction(_:)), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        buttonView.addSubview(closeButton)
        stackView.addArrangedSubview(buttonView)

        if let validSheettitle = sheetTitle {

            let titleLabel = UILabel(frame: .zero)
            titleLabel.text = validSheettitle
            titleLabel.font = .settingsPrimaryText()
            titleLabel.textColor = .secondary()
            titleLabel.textAlignment = .center
            stackView.addArrangedSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                titleLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
                titleLabel.heightAnchor.constraint(equalToConstant: 28),
                titleLabel.topAnchor.constraint(equalTo: closeButton.safeAreaLayoutGuide.bottomAnchor, constant: 10),
            ])
        }
            
        NSLayoutConstraint.activate([
            buttonView.heightAnchor.constraint(equalToConstant: 10),

            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 5),
            closeButton.centerXAnchor.constraint(equalTo: buttonView.safeAreaLayoutGuide.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: buttonView.safeAreaLayoutGuide.centerYAnchor),

            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }

    open override var additionalSafeAreaInsets: UIEdgeInsets {
        get {
            .init(
                top: super.additionalSafeAreaInsets.top + preferredSheetCornerRadius,
                left: super.additionalSafeAreaInsets.left,
                bottom: super.additionalSafeAreaInsets.bottom,
                right: super.additionalSafeAreaInsets.right
            )
        }
        set {
            super.additionalSafeAreaInsets = newValue
        }
    }

    open override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            .custom
        }
        set { }
    }

    open override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            bottomSheetTransitioningDelegate
        }
        set { }
    }

    open var preferredSheetTopInset: CGFloat = 24 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetTopInset = preferredSheetTopInset
        }
    }

    open var preferredSheetCornerRadius: CGFloat = 8 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetCornerRadius = preferredSheetCornerRadius
        }
    }

    open var preferredSheetSizing: PreferredSheetSizing = .medium {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetSizingFactor = preferredSheetSizing.rawValue
        }
    }

    open var preferredSheetBackdropColor: UIColor = .shadow() {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetBackdropColor = preferredSheetBackdropColor
        }
    }

    open var tapToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.tapToDismissEnabled = tapToDismissEnabled
        }
    }

    open var panToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.panToDismissEnabled = panToDismissEnabled
        }
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onCloseAction(_ sender: Any) {
        dismiss(animated: true)
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
