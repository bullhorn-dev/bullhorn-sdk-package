
import UIKit
import Foundation
internal import SwiftMessages

extension UIViewController {
    
    public func showInfo(_ message: String, autoHide: Double = 5.0) {
        showTopMessageView(with: message, theme: .info, autoHide: autoHide)
    }
    
    public func showWarning(_ message: String, autoHide: Double = 5.0) {
        showTopMessageView(with: message, theme: .warning, autoHide: autoHide)
    }
    
    public func showError(_ message: String, autoHide: Double = 5.0) {
        showTopMessageView(with: message, theme: .error, autoHide: autoHide)
    }
    
    public func showConnectionError(_ autoHide: Double = 5.0) {
        showTopMessageView(with: "The Internet connection is lost.", theme: .error, autoHide: autoHide)
    }
    
    func showTopMessageView(with message: String, theme: Theme, autoHide: Double = 0) {

        let toastView = MessageView.viewFromNib(layout: .cardView)
    
        toastView.configureTheme(theme)
        toastView.configureDropShadow()

        toastView.backgroundView.backgroundColor = .toastBackground()
        toastView.titleLabel?.textColor = .primary()
        toastView.titleLabel?.font = UIFont.fontWithName(.robotoMedium, size: 16)
        toastView.bodyLabel?.textColor = .primary()
        toastView.bodyLabel?.font = UIFont.fontWithName(.robotoRegular, size: 15)
        
        var title: String = "Unknown"
        var image: UIImage?
        var imageColor: UIColor = .primary()
        let imgConfig = UIImage.SymbolConfiguration(weight: .bold)

        switch theme {
        case .error:
            title = "Error"
            image = UIImage(systemName: "exclamationmark.circle")?.withConfiguration(imgConfig)
            imageColor = .accent()
        case .warning:
            title = "Warning"
            image = UIImage(systemName: "exclamationmark.circle")?.withConfiguration(imgConfig)
            imageColor = .accent()
        case .info:
            title = "Info"
            image = UIImage(systemName: "info.circle")?.withConfiguration(imgConfig)
            imageColor = .blue
        case .success:
            title = "Success"
            image = UIImage(systemName: "checkmark.circle")?.withConfiguration(imgConfig)
            imageColor = .green
        @unknown default:
            break
        }

        if let validImage = image {
            toastView.configureContent(title: title, body: message, iconImage: validImage)
            toastView.iconImageView?.tintColor = imageColor
        } else {
            toastView.configureContent(title: title, body: message)
        }

        toastView.button?.isHidden = true
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
        config.dimMode = .gray(interactive: true)
        config.duration = .seconds(seconds: 5)
        config.overrideUserInterfaceStyle = UserDefaults.standard.userInterfaceStyle

        (toastView.backgroundView as? CornerRoundingView)?.cornerRadius = 8
        
        SwiftMessages.show(config: config, view: toastView)
    }
    
    public func hideTopMessageView() {
        SwiftMessages.hideAll()
    }
}

