
import UIKit
import Foundation

extension UIImage {

    static let JPEGDefaultCompressionQuality = CGFloat(0.9)

    static let FullHDMaxDimention1920 = CGFloat.init(1920)
    static let FullHDMaxDimention1080 = CGFloat.init(1080)

    static let FullHDSizeHorizontal = CGSize.init(width: UIImage.FullHDMaxDimention1920, height: UIImage.FullHDMaxDimention1080)
    static let FullHDSizeVertical = CGSize.init(width: UIImage.FullHDMaxDimention1080, height: UIImage.FullHDMaxDimention1920)

    static let FullHDRectHorizontal = CGRect.init(origin: .zero, size: UIImage.FullHDSizeHorizontal)
    static let FullHDRectVertical = CGRect.init(origin: .zero, size: UIImage.FullHDSizeVertical)

    var isPortrait: Bool { return size.height > size.width }
    var isLandscape: Bool { return !isPortrait }
    var fitsFullHD: Bool {

        let selfRect = CGRect.init(origin: .zero, size: self.size)
        let fullHDRect = isPortrait ? UIImage.FullHDRectVertical : UIImage.FullHDRectHorizontal

        return fullHDRect.contains(selfRect)
    }

    func roundedImage() -> UIImage? {

        let imageRect = CGRect.init(origin: .zero, size: self.size)

        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)

        let circlePath = UIBezierPath.init(ovalIn: imageRect)
        circlePath.addClip()
        self.draw(in: imageRect)

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    func roundedImage(cornerRadius: CGFloat) -> UIImage? {

        let imageRect = CGRect.init(origin: .zero, size: self.size)

        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)

        let circlePath = UIBezierPath.init(roundedRect: imageRect, cornerRadius: cornerRadius)
        circlePath.addClip()
        self.draw(in: imageRect)

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    func capInsetsForResizableArea(_ areaSize: CGSize) -> UIEdgeInsets {

        let resizableAreaSize = CGSize.init(width: areaSize.width.rounded(.down), height: areaSize.height.rounded(.down))

        var insets = UIEdgeInsets.zero

        let remainigWidth = self.size.width - resizableAreaSize.width
        if resizableAreaSize.width.isLess(than: self.size.width / 2) {
            insets.left = (remainigWidth / 2).rounded(.up)
            insets.right = (remainigWidth / 2).rounded(.down)
        }

        let remainigHeight = self.size.height - resizableAreaSize.height
        if resizableAreaSize.height.isLess(than: self.size.height / 2) {
            insets.top = (remainigHeight / 2).rounded(.up)
            insets.bottom = (remainigHeight / 2).rounded(.down)
        }

        return insets
    }

    func scale(toSize newSize: CGSize) -> UIImage? {

        let newRect = CGRect.init(origin: .zero, size: CGSize.init(width: newSize.width.rounded(.down), height: newSize.height.rounded(.down)))

        UIGraphicsBeginImageContext(newRect.size)

        self.draw(in: newRect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return newImage
    }

    func scale(toWidth newWidth: CGFloat) -> UIImage? {

        let newScale = newWidth / (self.size.width * self.scale)
        let newSize = self.size.applying(CGAffineTransform.init(scaleX: newScale, y: newScale))

        return self.scale(toSize: newSize)
    }
    
    func scale(toHeight newHeight: CGFloat) -> UIImage? {

        let newScale = newHeight / (self.size.height * self.scale)
        let newSize = self.size.applying(CGAffineTransform.init(scaleX: newScale, y: newScale))

        return self.scale(toSize: newSize)
    }

    func scale(toMaxDimention dimention: CGFloat) -> UIImage? {

        let result: UIImage?

        if isPortrait {
            result = scale(toHeight: dimention)
        }
        else {
            result = scale(toWidth: dimention)
        }

        return result
    }

    func scaleToFullHD() -> UIImage? {

        guard !fitsFullHD else { return self }

        let newScale: CGFloat

        if isPortrait {
            newScale = min(UIImage.FullHDMaxDimention1920 / (self.size.height * self.scale), UIImage.FullHDMaxDimention1080 / (self.size.width * self.scale))
        }
        else {
            newScale = min(UIImage.FullHDMaxDimention1920 / (self.size.width * self.scale), UIImage.FullHDMaxDimention1080 / (self.size.height * self.scale))
        }

        let newSize = self.size.applying(CGAffineTransform.init(scaleX: newScale, y: newScale))

        return self.scale(toSize: newSize)
    }

    func JPEGData() -> Data? {
        return self.jpegData(compressionQuality: UIImage.JPEGDefaultCompressionQuality)
    }

    func JPEGDataInMainThread() -> Data? {

        var data: Data?

        if Thread.isMainThread {
            data = JPEGData()
        }
        else {
            DispatchQueue.main.sync { data = self.JPEGData() }
        }

        return data
    }
}
