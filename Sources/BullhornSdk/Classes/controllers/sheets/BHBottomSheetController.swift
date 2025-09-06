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
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()

        NotificationCenter.default.addObserver(self, selector: #selector(onUserInterfaceStyleChangedNotification(notification:)), name: BullhornSdk.UserInterfaceStyleChangedNotification, object: nil)
    }
    
    open override func loadView() {

        view = UIView()
        view.backgroundColor = .cardBackground()

        let closeButton = UIButton(type: .roundedRect)
        closeButton.setTitle("", for: .normal)
        closeButton.backgroundColor = .tertiary()
        closeButton.layer.cornerRadius = 2
        closeButton.accessibilityLabel = "Drag to close"

        closeButton.addTarget(self, action: #selector(onCloseAction(_:)), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 5),
            closeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
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
