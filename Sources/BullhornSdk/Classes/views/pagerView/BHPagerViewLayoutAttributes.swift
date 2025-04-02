import UIKit
import Foundation

class BHPagerViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var position: CGFloat = 0
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? BHPagerViewLayoutAttributes else {
            return false
        }
        var isEqual = super.isEqual(object)
        isEqual = isEqual && (self.position == object.position)
        return isEqual
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! BHPagerViewLayoutAttributes
        copy.position = self.position
        return copy
    }
    
}

