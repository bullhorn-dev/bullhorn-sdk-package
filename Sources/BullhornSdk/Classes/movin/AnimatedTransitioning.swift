
import Foundation
import UIKit

final class AnimatedTransitioning : NSObject {
    
    fileprivate(set) weak var transition: Transition!
    let type: TransitionType
    
    deinit {
        Movin.dp("AnimatedTransitioning - deinit")
    }

    init( _ transition: Transition, _ type: TransitionType) {
        self.transition = transition
        self.type = type

        super.init()
    }
}

extension AnimatedTransitioning : UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Movin.dp("AnimatedTransitioning - transitionDuration")
        return self.transition.movin.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        Movin.dp("AnimatedTransitioning - animateTransition")
        self.transition.prepareTransition(self.type, transitionContext)
        let type = self.type
        self.transition.movin.animator.addCompletion { [weak self] position in
            switch position {
            case .current:
                break
            default:
                self?.transition.finishTransition(type, true, transitionContext.containerView)
                transitionContext.completeTransition(true)
            }
        }
        
        self.interruptibleAnimator(using: transitionContext).startAnimation()
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
          
        return self.transition.movin.animator
    }
}
