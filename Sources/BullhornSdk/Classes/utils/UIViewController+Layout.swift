
import UIKit
import Foundation

// MARK: - LayoutGuideWrapper

class LayoutGuideWrapper: UILayoutGuide {

    private let layoutGuide: UILayoutGuide

    // MARK: - Initialization

    init(with layoutGuide: UILayoutGuide) {

        self.layoutGuide = layoutGuide

        super.init()
    }

    init(with layoutSupport: UILayoutSupport?, view: UIView, edge: UIRectEdge) {

        layoutGuide = UILayoutGuide.init()
        view.addLayoutGuide(layoutGuide)

        super.init()

        addConstraints(with: layoutSupport, view: view, edge: edge)
    }

    init(withSafeAreaLayoutGuide safeAreaLayoutGuide: UILayoutGuide, view: UIView, edge: UIRectEdge) {

        layoutGuide = UILayoutGuide.init()
        view.addLayoutGuide(layoutGuide)

        super.init()

        addConstraints(with: safeAreaLayoutGuide, view: view, edge: edge)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override

    override var identifier: String {
        get { return layoutGuide.identifier }
        set { layoutGuide.identifier = newValue }
    }

    override var owningView: UIView? {
        get { return layoutGuide.owningView }
        set {
            if let validView = newValue {
                validView.addLayoutGuide(layoutGuide)
            }
            else if let validView = layoutGuide.owningView {
                validView.removeLayoutGuide(layoutGuide)
            }
        }
    }

    override var layoutFrame: CGRect { return layoutGuide.layoutFrame }
    override var hasAmbiguousLayout: Bool {
        return layoutGuide.hasAmbiguousLayout
    }

    override var leadingAnchor: NSLayoutXAxisAnchor { return layoutGuide.leadingAnchor }
    override var trailingAnchor: NSLayoutXAxisAnchor { return layoutGuide.trailingAnchor }
    override var leftAnchor: NSLayoutXAxisAnchor { return layoutGuide.leftAnchor }
    override var rightAnchor: NSLayoutXAxisAnchor { return layoutGuide.rightAnchor }
    override var topAnchor: NSLayoutYAxisAnchor { return layoutGuide.topAnchor }
    override var bottomAnchor: NSLayoutYAxisAnchor { return layoutGuide.bottomAnchor }
    override var widthAnchor: NSLayoutDimension { return layoutGuide.widthAnchor }
    override var heightAnchor: NSLayoutDimension { return layoutGuide.heightAnchor }
    override var centerXAnchor: NSLayoutXAxisAnchor { return layoutGuide.centerXAnchor }
    override var centerYAnchor: NSLayoutYAxisAnchor { return layoutGuide.centerYAnchor }

    override func constraintsAffectingLayout(for axis: NSLayoutConstraint.Axis) -> [NSLayoutConstraint] {
        return layoutGuide.constraintsAffectingLayout(for: axis)
    }

    // MARK: - Private

    private func addConstraints(with layoutSupport: UILayoutSupport?, view: UIView, edge: UIRectEdge) {

        let topAnchor: NSLayoutYAxisAnchor
        let bottomAnchor: NSLayoutYAxisAnchor

        switch edge {
        case .top:
            topAnchor = layoutSupport?.topAnchor ?? view.topAnchor
            bottomAnchor = layoutSupport?.bottomAnchor ?? view.topAnchor

        case .bottom:
            topAnchor = layoutSupport?.topAnchor ?? view.bottomAnchor
            bottomAnchor = layoutSupport?.bottomAnchor ?? view.bottomAnchor

        default:
            topAnchor = view.topAnchor
            bottomAnchor = view.bottomAnchor
        }

        layoutGuide.topAnchor.constraint(equalTo: topAnchor).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        layoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        layoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    private func addConstraints(with safeAreaLayoutGuide: UILayoutGuide, view: UIView, edge: UIRectEdge) {

        let topAnchor: NSLayoutYAxisAnchor
        let bottomAnchor: NSLayoutYAxisAnchor

        switch edge {
        case .top:
            topAnchor = view.topAnchor
            bottomAnchor = safeAreaLayoutGuide.topAnchor

        case .bottom:
            topAnchor = safeAreaLayoutGuide.bottomAnchor
            bottomAnchor = view.bottomAnchor

        case .left, .right:
            topAnchor = view.topAnchor
            bottomAnchor = view.bottomAnchor

        default:
            topAnchor = safeAreaLayoutGuide.topAnchor
            bottomAnchor = safeAreaLayoutGuide.bottomAnchor
        }

        layoutGuide.topAnchor.constraint(equalTo: topAnchor).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true


        let leftAnchor: NSLayoutXAxisAnchor
        let rightAnchor: NSLayoutXAxisAnchor

        switch edge {
        case .left:
            leftAnchor = view.leftAnchor
            rightAnchor = safeAreaLayoutGuide.leftAnchor

        case .right:
            leftAnchor = safeAreaLayoutGuide.rightAnchor
            rightAnchor = view.rightAnchor

        case .top, .bottom:
            leftAnchor = view.leftAnchor
            rightAnchor = view.rightAnchor

        default:
            leftAnchor = safeAreaLayoutGuide.leftAnchor
            rightAnchor = safeAreaLayoutGuide.rightAnchor
        }

        layoutGuide.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        layoutGuide.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

        layoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        layoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
    }
}

// MARK: - LayoutGuideWrappedViewController

protocol LayoutGuideWrappedSupported: AnyObject {

    var topLayoutGuideWrapper: LayoutGuideWrapper! { get set }
    var bottomLayoutGuideWrapper: LayoutGuideWrapper! { get set }
    var leftLayoutGuideWrapper: LayoutGuideWrapper! { get set }
    var rightLayoutGuideWrapper: LayoutGuideWrapper! { get set }

    func setupLayoutGuideWrappers()
}

extension LayoutGuideWrappedSupported where Self: UIViewController {

    func setupLayoutGuideWrappers() {

        topLayoutGuideWrapper = LayoutGuideWrapper.init(withSafeAreaLayoutGuide: view.safeAreaLayoutGuide, view: view, edge: .top)
        bottomLayoutGuideWrapper = LayoutGuideWrapper.init(withSafeAreaLayoutGuide: view.safeAreaLayoutGuide, view: view, edge: .bottom)
        leftLayoutGuideWrapper = LayoutGuideWrapper.init(withSafeAreaLayoutGuide: view.safeAreaLayoutGuide, view: view, edge: .left)
        rightLayoutGuideWrapper = LayoutGuideWrapper.init(withSafeAreaLayoutGuide: view.safeAreaLayoutGuide, view: view, edge: .right)
    }
}

class LayoutGuideWrappedViewController: UIViewController, LayoutGuideWrappedSupported {

    var topLayoutGuideWrapper: LayoutGuideWrapper!
    var bottomLayoutGuideWrapper: LayoutGuideWrapper!
    var leftLayoutGuideWrapper: LayoutGuideWrapper!
    var rightLayoutGuideWrapper: LayoutGuideWrapper!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayoutGuideWrappers()
    }
}

class LayoutGuideWrappedNavigationController: UINavigationController, LayoutGuideWrappedSupported {

    var topLayoutGuideWrapper: LayoutGuideWrapper!
    var bottomLayoutGuideWrapper: LayoutGuideWrapper!
    var leftLayoutGuideWrapper: LayoutGuideWrapper!
    var rightLayoutGuideWrapper: LayoutGuideWrapper!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayoutGuideWrappers()
    }
}
