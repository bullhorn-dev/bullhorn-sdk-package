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

        let font = UIFont(name: name.rawValue, size: size)
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

        return font != nil ? UIFontMetrics(forTextStyle: .headline).scaledFont(for: font!) : UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: size, weight: fontWeight))
    }
    
    class func sectionTitle() -> UIFont {
        return UIFont.fontWithName(.robotoBold, size: 18)
    }
    
    class func primaryButton() -> UIFont {
        return UIFont.fontWithName(.robotoMedium, size: 17)
    }

    class func secondaryButton() -> UIFont {
        return UIFont.fontWithName(.robotoRegular, size: 15)
    }

    class func primaryText() -> UIFont {
        return UIFont.fontWithName(.robotoMedium, size: 14)
    }

    class func secondaryText() -> UIFont {
        return UIFont.fontWithName(.robotoRegular, size: 13)
    }

    class func settingsPrimaryText() -> UIFont {
        return UIFont.fontWithName(.robotoRegular, size: 17)
    }

    class func settingsSecondaryText() -> UIFont {
        return UIFont.fontWithName(.robotoRegular, size: 14)
    }
}
