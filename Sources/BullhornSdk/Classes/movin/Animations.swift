
import Foundation
import UIKit

struct AnimationDirection {
    
    let duration: TimeInterval
    let isFoward: Bool
    
    init(_  duration: TimeInterval, _ isFoward: Bool) {
        self.duration = duration
        self.isFoward = isFoward
    }
}

protocol AnimationCompatible: AnyObject {
    
    var delayFactor: CGFloat { get set }
    
    func beforeAnimation()
    func aninmate(_ animationDirection: AnimationDirection)
    
    // optional
    func finishAnimation(_ isFoward: Bool, _ didComplete: Bool)
    
    // optional
    func interactiveAnimate(_ fractionComplete: CGFloat)
    func finishInteractiveAnimation(_ interactiveTransitioning: InteractiveTransitioning)
}

extension AnimationCompatible {
    
    @discardableResult func delay(_ v: CGFloat) -> Self {
        self.delayFactor = v
        return self
    }
    
    func interactiveAnimate(_ fractionComplete: CGFloat) {}
    
    func finishInteractiveAnimation(_ interactiveTransitioning: InteractiveTransitioning) {}
}

protocol ValueAnimationCompatible: AnimationCompatible {
    
    associatedtype Value
    
    var fromValue: Value { get set }
    var toValue: Value { get set }
    var currentValue: Value { get set }
}

extension ValueAnimationCompatible {
    
    @discardableResult func from(_ v: Value) -> Self {
        self.fromValue = v
        return self
    }
    
    @discardableResult func to(_ v: Value) -> Self {
        self.toValue = v
        return self
    }
    
    func beforeAnimation() {
        self.currentValue = self.fromValue
    }
    
    func aninmate(_ animationDirection: AnimationDirection) {
        self.currentValue = self.toValue
    }
    
    func finishAnimation(_ isFoward: Bool, _ didComplete: Bool) {
        if isFoward {
            self.currentValue = didComplete ? self.toValue : self.fromValue
        } else {
            self.currentValue = didComplete ? self.fromValue : self.toValue
        }
    }
}

final class AlphaAnimation : ValueAnimationCompatible {
    
    typealias Value = CGFloat
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value = 0
    var currentValue: Value { didSet { self.view.alpha = self.currentValue } }
    
    deinit {
        Movin.dp("AlphaAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        self.fromValue = view.alpha
        self.currentValue = self.fromValue
    }
}

final class BackgroundColorAnimation : ValueAnimationCompatible {
    
    typealias Value = UIColor
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.backgroundColor = self.currentValue } }
    
    deinit {
        Movin.dp("BackgroundColorAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.backgroundColor ?? .white
        self.toValue = view.backgroundColor ?? .white
        self.currentValue = self.fromValue
    }
}

final class FrameAnimation : ValueAnimationCompatible {
    
    typealias Value = CGRect
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.frame = self.currentValue } }
    
    deinit {
        Movin.dp("FrameAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.frame
        self.toValue = view.frame
        self.currentValue = self.fromValue
    }
}

final class PointAnimation : ValueAnimationCompatible {
    
    typealias Value = CGPoint
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.frame.origin = self.currentValue } }
    
    deinit {
        Movin.dp("PointAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.frame.origin
        self.toValue = view.frame.origin
        self.currentValue = self.fromValue
    }
}

final class SizeAnimation : ValueAnimationCompatible {
    
    typealias Value = CGSize
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.frame.size = self.currentValue } }
    
    deinit {
        Movin.dp("SizeAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.frame.size
        self.toValue = view.frame.size
        self.currentValue = self.fromValue
    }
}

final class CornerRadiusAnimation : ValueAnimationCompatible {
    
    typealias Value = CGFloat
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.layer.cornerRadius = self.currentValue } }
    
    deinit {
        Movin.dp("CornerRadiusAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.layer.cornerRadius
        self.toValue = view.layer.cornerRadius
        self.currentValue = self.fromValue
        self.view.clipsToBounds = true
    }
    
    func aninmate(_ animationDirection: AnimationDirection) {
        self.currentValue = self.toValue
    }
    
    func interactiveAnimate(_ fractionComplete: CGFloat) {}
    
    func finishInteractiveAnimation(_ interactiveTransitioning: InteractiveTransitioning) {}
}

final class TransformAnimation : ValueAnimationCompatible {
    
    typealias Value = CGAffineTransform
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    var fromValue: Value
    var toValue: Value
    var currentValue: Value { didSet { self.view.transform = self.currentValue } }
    
    deinit {
        Movin.dp("TransformAnimation - deinit")
    }
    
    init(_ view: UIView) {
        self.view = view
        
        self.fromValue = view.transform
        self.toValue = view.transform
        self.currentValue = self.fromValue
    }
}

class CustomAnimation : AnimationCompatible {
    
    let view: UIView
    
    var delayFactor: CGFloat = 0
    
    var animation: (UIView) -> Swift.Void
    var before: ((UIView) -> Swift.Void)?
    var finish: ((Bool, Bool) -> Swift.Void)?
    
    deinit {
        Movin.dp("CustomAnimation - deinit")
    }
    
    init(_ view: UIView, _ animation: @escaping (UIView) -> Swift.Void) {
        self.view = view
        self.animation = animation
    }
    
    @discardableResult func configureBefore(_ before: ((UIView) -> Swift.Void)? = nil) -> CustomAnimation {
        self.before = before
        return self
    }
    
    @discardableResult func configureFinish(_ finish: ((Bool, Bool) -> Swift.Void)? = nil) -> CustomAnimation {
        self.finish = finish
        return self
    }
    
    func beforeAnimation() {
        self.before?(self.view)
    }
    
    func aninmate(_ animationDirection: AnimationDirection) {
        self.animation(self.view)
    }
    
    func finishAnimation(_ isFoward: Bool, _ didComplete: Bool) {
        self.finish?(isFoward, didComplete)
    }
}
