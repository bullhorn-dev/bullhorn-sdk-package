
import UIKit
import Foundation

extension UIImage {

    convenience init?(withColor color: UIColor, size: CGSize = CGSize.init(width: 1, height: 1), cornerRadius: CGFloat = 0) {

        guard let cgImage = UIImage.image(withColor: color, size: size, cornerRadius: cornerRadius)?.cgImage else { return nil }

        self.init(cgImage: cgImage)
    }

    static func image(withColor color: UIColor, size: CGSize = CGSize.init(width: 1, height: 1), cornerRadius: CGFloat = 0) -> UIImage? {

        guard !size.equalTo(CGSize.zero) else { return nil }

        let rect = CGRect.init(origin: CGPoint.zero, size: size)

        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        if cornerRadius > 0 {
            let path = CGPath.init(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            context.addPath(path)
            context.clip()
        }

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func coloredImage(withColor color: UIColor) -> UIImage {

        let imageRect = CGRect.init(origin: CGPoint.zero, size: self.size)

        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, 0.0)

        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else { return self }

        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -(imageRect.size.height))
        
        context.clip(to: imageRect, mask: cgImage)
        context.setFillColor(color.cgColor)
        context.fill(imageRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? self
    }
    
    func translucentImage(withAlpha alpha: CGFloat) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        
        draw(in: CGRect.init(origin: .zero, size: size), blendMode: .screen, alpha: alpha)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
