
import UIKit
import Foundation
import SafariServices

extension UIViewController {
    
    open override func awakeFromNib() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

extension UIViewController {

    open override func awakeAfter(using coder: NSCoder) -> Any? {
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
        return super.awakeAfter(using: coder)
    }
}

extension UIViewController {

    func presentShareDialog(with items: [Any], configureBlock: ((UIActivityViewController) -> Void)? = nil) {

        guard !items.isEmpty else { return }

        setActivityStateOn(true)

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view // iPad compatibility

        configureBlock?(activityViewController)

        present(activityViewController, animated: true)
        { [weak self] in
            self?.setActivityStateOn(false)
        }
    }

    func presentSafari(_ url: URL, needConfirmation: Bool = true, configureBlock: ((SFSafariViewController) -> Void)? = nil) {
        guard needConfirmation else {
            presentSafariViewController(for: url, configureBlock: configureBlock)
            return
        }

        let alert = UIAlertController(title: "External Link",
                                      message: "You are now leaving the app and going to another website.",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.presentSafariViewController(for: url, configureBlock: configureBlock)
        })

        present(alert, animated: true, completion: nil)
    }

    private func presentSafariViewController(for url: URL, configureBlock: ((SFSafariViewController) -> Void)?) {
        var webUrl = url

        if url.scheme != "http" && url.scheme != "https" {
            webUrl = URL(string: "https://\(url.absoluteString)") ?? url
        }

        let safariVC = SFSafariViewController(url: webUrl)
        safariVC.modalPresentationStyle = .overFullScreen
        safariVC.preferredControlTintColor = .playerOnDisplayBackground()
        safariVC.preferredBarTintColor = .defaultBlue()
        safariVC.modalPresentationCapturesStatusBarAppearance = true

        configureBlock?(safariVC)

        present(safariVC, animated: true) {
            // Announce to VoiceOver that a new page has opened after presentation
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: "Opening web page.")
            }
        }
    }
    
    func openExternalLink(_ url: URL) {

        if url.absoluteString.contains("youtube") {
            let replaced = url.absoluteString.replacingOccurrences(of: "https", with: "youtube")

            if let appURL = URL(string: replaced), UIApplication.shared.canOpenURL(appURL) {
                let alert = UIAlertController.init(title: "External Link", message: "You are now leaving the app and going to YouTube app.", preferredStyle: .alert)

                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction.init(title: "Continue", style: .default) { _ in
                    UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                })
                present(alert, animated: true, completion: nil)
            } else {
                presentSafari(url)
            }
        } else {
            presentSafari(url)
        }
    }
    
    func presentEmailDialog(withUrl url: URL) {
        UIApplication.shared.open(url)
    }

    @discardableResult func presentChangePasswordDialog(dismissActionCompletion: @escaping () -> Void) -> UIAlertController {
        return presentChangePasswordDialog(configureBlock: nil, dismissActionCompletion: dismissActionCompletion)
    }

    @discardableResult func presentChangePasswordDialog(configureBlock: ((UIAlertController) -> Void)?, dismissActionCompletion: @escaping () -> Void) -> UIAlertController {
        
        let alert = UIAlertController.init(title: nil, message: NSLocalizedString("The code you've entered is a password for your account. You can change it in account preferences.", comment: "") , preferredStyle: .alert)

        alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .destructive) { (action) in
            dismissActionCompletion()
        })

        configureBlock?(alert)

        present(alert, animated: true, completion: nil)
        return alert
    }

    @discardableResult func presentUpdateAppVersionAlert() -> UIAlertController {

        let alert = UIAlertController.init(title: NSLocalizedString("The app version is outdated", comment: ""), message: NSLocalizedString("Bullhorn won't work properly unless you update the application", comment: ""), preferredStyle: .alert)

        if let validURL = URL.init(string: BHAppConfiguration.shared.appStoreURLString), UIApplication.shared.canOpenURL(validURL) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Update", comment: ""), style: .default) { _ in
                UIApplication.shared.openURLWithoutCompletion(validURL)
            })
        }
        else {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: nil))
        }

        present(alert, animated: true, completion: nil)
        return alert
    }

    func dismissAlertController(animated: Bool, completion: (() -> Void)?) {

        if let presentedVC = presentedViewController, let alertVC = presentedVC as? UIAlertController {
            alertVC.dismiss(animated: animated, completion: completion)
        }
        else {
            completion?()
        }
    }

    func dismissActionSheetController(animated: Bool, completion: (() -> Void)?) {

        if let presentedVC = presentedViewController, let alertVC = presentedVC as? UIAlertController, alertVC.preferredStyle == .actionSheet {
            alertVC.dismiss(animated: animated, completion: completion)
        }
        else {
            completion?()
        }
    }
}

extension UIViewController {
  
    func isVisible() -> Bool {
        return self.isViewLoaded && self.view.window != nil
    }
}
