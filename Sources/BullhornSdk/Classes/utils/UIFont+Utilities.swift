import UIKit
import Foundation

extension UIFont {

    enum Name: String {
        case robotoThin = "Roboto-Thin"
        case robotoLight = "Roboto-Light"
        case robotoRegular = "Roboto-Regular"
        case robotoMedium = "Roboto-Medium"
        case robotoBold = "Roboto-Bold"
        case robotoBlack = "Roboto-Black"
    }

    class func fontWithName(_ name: Name, size: CGFloat) -> UIFont {

        let font = UIFont.init(name: name.rawValue, size: size)
        var fontWeight: UIFont.Weight = .regular

        if font == nil {

            switch name {
            case .robotoThin: fontWeight = .thin
            case .robotoLight: fontWeight = .light
            case .robotoRegular: fontWeight = .regular
            case .robotoMedium: fontWeight = .medium
            case .robotoBold: fontWeight = .bold
            case .robotoBlack: fontWeight = .black
            }
        }

        return font ?? UIFont.systemFont(ofSize: size, weight: fontWeight)
    }
}
