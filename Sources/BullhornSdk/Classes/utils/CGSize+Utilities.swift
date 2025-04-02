
import CoreGraphics
import Foundation

extension CGSize {

    static func square(_ dimention: Int) -> CGSize {
        return CGSize.init(width: dimention, height: dimention)
    }

    static func square(_ dimention: Double) -> CGSize {
        return CGSize.init(width: dimention, height: dimention)
    }

    static func square(_ dimention: CGFloat) -> CGSize {
        return CGSize.init(width: dimention, height: dimention)
    }
}
