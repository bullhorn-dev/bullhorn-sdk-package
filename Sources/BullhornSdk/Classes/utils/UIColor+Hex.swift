import UIKit
import Foundation

extension UIColor {

    convenience init(hex hexString: String) {

        let rgba = UIColor.rgbaComponents(hexString)
        self.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    }

    convenience init(hex hexString: String, alpha: CGFloat) {

        let rgba = UIColor.rgbaComponents(hexString)
        self.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: alpha)
    }

    static func fromHex(_ hexString: String) -> UIColor {

        let rgba = UIColor.rgbaComponents(hexString)
        return UIColor.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    }

    static func fromHex(_ hexString: String, alpha: CGFloat) -> UIColor {

        let rgba = UIColor.rgbaComponents(hexString)
        return UIColor.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: alpha)
    }

    static func rgbComponents(_ hexString: String) -> (r: CGFloat, g: CGFloat, b: CGFloat) {

        let rgba = UIColor.rgbaComponents(hexString)
        return (rgba.r, rgba.g, rgba.b)
    }

    static func rgbaComponents(_ hexString: String) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {

        var hexValues = hexString

        if hexValues.hasPrefix("#") {
            hexValues.remove(at: hexValues.startIndex)
        }

        var r = 0.0, g = 0.0, b = 0.0
        var a = 1.0

        let scanner = Scanner.init(string: hexValues)
        var scannedValue: UInt32 = 0
        scanner.scanHexInt32(&scannedValue)
        let charsCount = hexValues.count

        var mask: UInt32 = 0
        var posShift: UInt32 = 0
        var isShortCode = false

        switch charsCount {
        case 3...4:
            mask = 0xF
            posShift = 1
            isShortCode = true

        case 6...8:
            mask = 0xFF
            posShift = 2
            isShortCode = false

        default:
            break
        }

        let bitShift: UInt32 = 4
        let fullValue: UInt32 = 0xFF
        var pos: UInt32 = 0
        var offset: UInt32 = 0
        var tempVal: UInt32 = 0

        pos = (UInt32(charsCount) / posShift) - 1; offset = bitShift * pos * posShift
        tempVal = (scannedValue & (UInt32(mask) << offset))
        if isShortCode {
            tempVal |= (tempVal << mask)
        }
        r = Double(tempVal >> offset) / Double(fullValue)

        pos -= 1; offset = bitShift * pos * posShift
        tempVal = (scannedValue & (UInt32(mask) << offset))
        if isShortCode {
            tempVal |= (tempVal << mask)
        }
        g = Double(tempVal >> offset) / Double(fullValue)

        pos -= 1; offset = bitShift * pos * posShift
        tempVal = (scannedValue & (UInt32(mask) << offset))
        if isShortCode {
            tempVal |= (tempVal << mask)
        }
        b = Double(tempVal >> offset) / Double(fullValue)

        if pos > 0 {
            pos -= 1; offset = bitShift * pos * posShift
            tempVal = (scannedValue & (UInt32(mask) << offset))
            if isShortCode {
                tempVal |= (tempVal << mask)
            }
            a = Double(tempVal >> offset) / Double(fullValue)
        }

        return (CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a))
    }
    
    // MARK: - Default Colors

    static func defaultBlue() -> UIColor {
        return UIColor.init(hex: "#003366")
    }
    
    static func defaultDarkBlue() -> UIColor {
        return UIColor.init(hex: "#00172e")
    }
    
    static func defaultPlayerBackground() -> UIColor {
        return UIColor.init(hex: "#001d3a")
    }
    
    static func defaultAccent() -> UIColor {
        return UIColor.init(hex: "#BB2030")
    }
    
    static func defaultMediumGray() -> UIColor {
        return UIColor.init(hex: "#AFBFCC")
    }
    
    static func defaultLightGray() ->  UIColor {
        return UIColor.init(hex: "#EAEDF0")
    }
    
    static func defaultYellow() -> UIColor {
        return UIColor.init(hex: "#FFD03E")
    }


    // MARK: - App provided colors

    static func navigationBackground() -> UIColor {
        return UIColor.init(named: "bhColorAppBarBg") ?? .defaultBlue()
    }

    static func navigationText() -> UIColor {
        return UIColor.init(named: "bhColorAppBarTitle") ?? .white
    }

    static func primaryBackground() -> UIColor {
        return UIColor.init(named: "bhColorPrimaryBg") ?? .white
    }

    static func cardBackground() -> UIColor {
        return UIColor.init(named: "bhColorCardBg") ?? .white
    }

    static func secondaryBackground() -> UIColor {
        return UIColor.init(named: "bhColorSecondaryBg") ?? .defaultLightGray()
    }

    static func playerDisplayBackground() -> UIColor {
        return UIColor.init(named: "bhColorPlayerDisplayBg") ?? defaultPlayerBackground()
    }

    static func playerOnDisplayBackground() -> UIColor {
        return UIColor.init(named: "bhColorPlayerOnDisplayBg") ?? .white
    }

    static func tertiary() -> UIColor {
        return UIColor.init(named: "bhColorTertiary") ?? .defaultMediumGray()
    }

    static func primary() -> UIColor {
        return UIColor.init(named: "bhColorPrimary") ?? defaultBlue()
    }
    
    static func secondary() -> UIColor {
        return UIColor.init(named: "bhColorSecondary") ?? defaultMediumGray()
    }
    
    static func accent() -> UIColor {
        return UIColor.init(named: "bhColorAccent") ?? defaultAccent()
    }

    static func onAccent() -> UIColor {
        return UIColor.init(named: "bhColorOnAccent") ?? .white
    }

    static func divider() -> UIColor {
        return UIColor.init(named: "bhColorDivider") ?? defaultLightGray()
    }

    static func shadow() -> UIColor {
        return UIColor.init(named: "bhColorShadow") ?? .black
    }
    
    static func toastBackground() -> UIColor {
        return UIColor.init(named: "bhToastBg") ?? .defaultBlue()
    }
    
    static func fxPrimaryBackground() -> UIColor {
        return UIColor.init(named: "fxColorPrimaryBg") ?? .white
    }
}
