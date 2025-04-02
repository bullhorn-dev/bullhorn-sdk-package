
import Foundation
import UIKit

class TimingCurve: NSObject, UITimingCurveProvider {
    
    let timingCurveType: UITimingCurveType
    
    let cubicTimingParameters: UICubicTimingParameters?
    
    let springTimingParameters: UISpringTimingParameters?
    
    override init() {
        self.timingCurveType = .cubic
        self.cubicTimingParameters = UICubicTimingParameters(animationCurve: .easeInOut)
        self.springTimingParameters = nil
        
        super.init()
    }
    
    init(cubic: UICubicTimingParameters, spring: UISpringTimingParameters? = nil) {
        if spring != nil {
            self.timingCurveType = .composed
        } else {
            self.timingCurveType = .cubic
        }
        self.cubicTimingParameters = cubic
        self.springTimingParameters = spring
        
        super.init()
    }
    
    init(curve: UIView.AnimationCurve, dampingRatio: CGFloat, initialVelocity: CGVector? = nil) {
        self.timingCurveType = .composed
        self.cubicTimingParameters = UICubicTimingParameters(animationCurve: curve)
        
        if let v = initialVelocity {
            self.springTimingParameters = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: v)
        } else {
            self.springTimingParameters = UISpringTimingParameters(dampingRatio: dampingRatio)
        }
        
        super.init()
    }
    
    init(curve: UIView.AnimationCurve, damping: CGFloat, initialVelocity: CGVector, mass: CGFloat, stiffness: CGFloat) {
        self.timingCurveType = .composed
        self.cubicTimingParameters = UICubicTimingParameters(animationCurve: curve)
        self.springTimingParameters = UISpringTimingParameters(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)
        
        super.init()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.timingCurveType.rawValue, forKey: "timingCurveType")
    }

    required init?(coder aDecoder: NSCoder) {
        self.timingCurveType = UITimingCurveType(rawValue: aDecoder.decodeObject(forKey: "timingCurveType") as? Int ?? 0) ?? .cubic
        self.cubicTimingParameters = UICubicTimingParameters(animationCurve: .easeInOut)
        self.springTimingParameters = nil
    }
}
