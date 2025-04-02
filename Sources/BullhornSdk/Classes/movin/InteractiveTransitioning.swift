
import Foundation
import UIKit

final class InteractiveTransitioning : UIPercentDrivenInteractiveTransition {
    
    weak fileprivate(set) var transition: Transition!
    let type: TransitionType
    
    private(set) var isCompleted: Bool = false
    private var containerView: UIView?
    
    deinit {
        Movin.dp("InteractiveTransitioning - deinit")
    }
    
    init(_ transition: Transition, _ type: TransitionType) {
        self.type = type
        self.transition = transition
        
        super.init()
        
        self.timingCurve = transition.movin.timingParameters
    }
    
    override var duration: CGFloat { return self.transition.movin.duration.toCGFloat }
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        Movin.dp("InteractiveTransitioning - startInteractiveTransition")
        self.containerView = transitionContext.containerView
        let type = self.type
        self.transition.prepareTransition(type, transitionContext)
        self.transition.movin.animator.addCompletion { [weak self] position in
            let isCompleted = self?.isCompleted ?? false
            self?.transition.finishTransition(type, isCompleted, transitionContext.containerView)
            transitionContext.completeTransition(isCompleted)
        }
        
        self.transition.movin.animator.startAnimation()
        self.transition.movin.animator.pauseAnimation()
    }
    
    override func update(_ percentComplete: CGFloat) {
        super.update(percentComplete)
        
        self.transition.movin.animator.fractionComplete = percentComplete
    }
    
    override func finish() {
        Movin.dp("InteractiveTransitioning - finish")
        super.finish()
        
        self.isCompleted = true
        self.transition.movin.end(self.type.isPresenting)
        self.transition.movin.finishInteractiveAnimation(self)
    }
    
    override func cancel() {
        Movin.dp("InteractiveTransitioning - cancel")
        super.cancel()
        
        self.isCompleted = false
        self.transition.movin.cancel(self.type.isPresenting)
        self.transition.movin.finishInteractiveAnimation(self)
    }
}
