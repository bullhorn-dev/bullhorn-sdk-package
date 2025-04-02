
import UIKit
import Foundation

@objc
enum BHPagerViewTransformerType: Int {
    case overlap
    case linear
}

class BHPagerViewTransformer: NSObject {
    
    weak var pagerView: BHPagerView?
    var type: BHPagerViewTransformerType
    
    var minimumScale: CGFloat = 0.65
    var minimumAlpha: CGFloat = 0.6
    
    @objc
    init(type: BHPagerViewTransformerType) {
        self.type = type
    }
    
    func applyTransform(to attributes: BHPagerViewLayoutAttributes) {
        guard let pagerView = self.pagerView else { return }

        let position = attributes.position
        let scrollDirection = pagerView.scrollDirection

        switch self.type {
        case .overlap,.linear:
            guard scrollDirection == .horizontal else { return }

            let scale = max(1 - (1-self.minimumScale) * abs(position), self.minimumScale)
            let transform = CGAffineTransform(scaleX: scale, y: scale)

            attributes.transform = transform
            let alpha = (self.minimumAlpha + (1-abs(position))*(1-self.minimumAlpha))
            attributes.alpha = alpha
            let zIndex = (1-abs(position)) * 10
            attributes.zIndex = Int(zIndex)
        }
    }
    
    func proposedInteritemSpacing() -> CGFloat {
        guard let pagerView = self.pagerView else { return 0 }

        let scrollDirection = pagerView.scrollDirection

        switch self.type {
        case .overlap:
            guard scrollDirection == .horizontal else {
                return 0
            }
            return pagerView.itemSize.width * -self.minimumScale * 0.6
        case .linear:
            guard scrollDirection == .horizontal else {
                return 0
            }
            return pagerView.itemSize.width * -self.minimumScale * 0.2
        default:
            break
        }

        return pagerView.interitemSpacing
    }
    
}


