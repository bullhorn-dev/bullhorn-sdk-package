
import UIKit
import Foundation

// MARK: - BHActivityIndicatorAnimationDelegate

protocol BHActivityIndicatorAnimationDelegate {
    func setUpAnimation(in layer: CALayer, size: CGSize, color: UIColor)
}

// MARK: - BHActivityIndicatorType

enum BHActivityIndicatorType: CaseIterable {

    case ballPulse
    case circleStrokeSpin

    func animation() -> BHActivityIndicatorAnimationDelegate {
        switch self {
        case .ballPulse:
            return BHActivityIndicatorAnimationBallPulse()
        case .circleStrokeSpin:
            return BHActivityIndicatorAnimationCircleStrokeSpin()
        }
    }
}

// MARK: - BHActivityIndicatorView

final class BHActivityIndicatorView: UIView {

    static var defaultType: BHActivityIndicatorType = .circleStrokeSpin
    static var defaultColor: UIColor = .accent()
    static var defaultPadding: CGFloat = 0

    var type: BHActivityIndicatorType = BHActivityIndicatorView.defaultType

    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'type' instead.")
    @IBInspectable var typeName: String {
        get {
            return getTypeName()
        }
        set {
            _setTypeName(newValue)
        }
    }

    @IBInspectable var color: UIColor = BHActivityIndicatorView.defaultColor

    @IBInspectable var padding: CGFloat = BHActivityIndicatorView.defaultPadding

    var isAnimating: Bool = false

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear
        isHidden = true
    }

    init(frame: CGRect, type: BHActivityIndicatorType? = nil, color: UIColor? = nil, padding: CGFloat? = nil) {

        self.type = type ?? BHActivityIndicatorView.defaultType
        self.color = color ?? BHActivityIndicatorView.defaultColor
        self.padding = padding ?? BHActivityIndicatorView.defaultPadding

        super.init(frame: frame)
        isHidden = true
    }
    
    // MARK: - Lifecycle

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height)
    }

    override var bounds: CGRect {
        didSet {
            // setup the animation again for the new bounds
            if oldValue != bounds && isAnimating {
                setUpAnimation()
            }
        }
    }

    // MARK: - Public

    final func startAnimating() {
        guard !isAnimating else { return }

        isHidden = false
        isAnimating = true
        layer.speed = 1
        setUpAnimation()
    }

    final func stopAnimating() {
        guard isAnimating else { return }

        isHidden = true
        isAnimating = false
        layer.sublayers?.removeAll()
    }

    // MARK: Internal

    internal func _setTypeName(_ typeName: String) {
        for item in BHActivityIndicatorType.allCases {
            if String(describing: item).caseInsensitiveCompare(typeName) == ComparisonResult.orderedSame {
                type = item
                break
            }
        }
    }

    internal func getTypeName() -> String {
        return String(describing: type)
    }

    // MARK: Private

    private final func setUpAnimation() {
        let animation: BHActivityIndicatorAnimationDelegate = type.animation()
        var animationRect = frame.inset(by: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
        let minEdge = min(animationRect.width, animationRect.height)

        layer.sublayers = nil
        animationRect.size = CGSize(width: minEdge, height: minEdge)
        animation.setUpAnimation(in: layer, size: animationRect.size, color: color)
    }
}
