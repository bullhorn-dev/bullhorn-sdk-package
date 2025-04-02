
import Foundation
import UIKit

protocol MovinExtensionCompatible {
    associatedtype CompatibleType
    
    var mvn: CompatibleType { get }
}

struct MovinExtensionCompatibleWrapped<Base> {
    let base: Base
    
    init(_ base: Base) {
        self.base = base
    }
}

extension MovinExtensionCompatible {
    
    var mvn: MovinExtensionCompatibleWrapped<Self> {
        return MovinExtensionCompatibleWrapped(self)
    }
}

extension UIView: MovinExtensionCompatible {}

extension MovinExtensionCompatibleWrapped where Base : UIView {
    
    var alpha: AlphaAnimation { return AlphaAnimation(self.base) }
    
    var backgroundColor: BackgroundColorAnimation { return BackgroundColorAnimation(self.base) }
    
    var frame: FrameAnimation { return FrameAnimation(self.base) }
    
    var point: PointAnimation { return PointAnimation(self.base) }
    
    var size: SizeAnimation { return SizeAnimation(self.base) }
    
    var transform: TransformAnimation { return TransformAnimation(self.base) }
    
    var cornerRadius: CornerRadiusAnimation { return CornerRadiusAnimation(self.base) }
}

extension MovinExtensionCompatibleWrapped where Base : UIView {
    
    var halfSize: CGSize { return self.base.bounds.size.mvn.halfSize }
}

extension CGSize: MovinExtensionCompatible {}

extension MovinExtensionCompatibleWrapped where Base == CGSize {
    
    var halfSize: CGSize { return CGSize(width: self.base.width * 0.5, height: self.base.height * 0.5) }
}
