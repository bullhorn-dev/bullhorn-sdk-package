
import UIKit

extension UIColor {
    
    static func primary() -> UIColor {
        return UIColor.init(named: "bhColorPrimary") ?? .darkText
    }
    
    static func secondary() -> UIColor {
        return UIColor.init(named: "bhColorSecondary") ?? .lightText
    }
    
    static func tertiary() -> UIColor {
        return UIColor.init(named: "bhColorTertiary") ?? .gray
    }

    static func accent() -> UIColor {
        return UIColor.init(named: "bhColorAccent") ?? .red
    }
    
    static func primaryBackground() -> UIColor {
        return UIColor.init(named: "bhColorPrimaryBg") ?? .white
    }

    static func cardBackground() -> UIColor {
        return UIColor.init(named: "bhColorCardBg") ?? .white
    }

    static func secondaryBackground() -> UIColor {
        return UIColor.init(named: "bhColorSecondaryBg") ?? .gray
    }
    
    static func navigationBackground() -> UIColor {
        return UIColor.init(named: "bhColorAppBarBg") ?? .systemBlue
    }

    static func navigationText() -> UIColor {
        return UIColor.init(named: "bhColorAppBarTitle") ?? .white
    }
    
    static func toastBackground() -> UIColor {
        return UIColor.init(named: "bhColorAppBarBg") ?? .black
    }

    static func toastText() -> UIColor {
        return UIColor.init(named: "bhColorPlayerOnDisplayBg") ?? .white
    }
    
    static func controlEnabled() -> UIColor {
        return UIColor.init(named: "fxColorControlEnabledBg") ?? .blue
    }

    static func controlDisabled() -> UIColor {
        return UIColor.init(named: "fxColorControlDisabledBg") ?? .gray
    }
    
    static func divider() -> UIColor {
        return UIColor.init(named: "bhColorDivider") ?? .lightGray
    }

    static func shadow() -> UIColor {
        return UIColor.init(named: "bhColorShadow") ?? .black
    }
}

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
