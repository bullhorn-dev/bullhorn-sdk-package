
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

    func presentSafari(_ withUrl: URL, configureBlock: ((SFSafariViewController) -> Void)? = nil) {

        let safariVC = SFSafariViewController.init(url: withUrl)
        safariVC.modalPresentationStyle = .overFullScreen
        safariVC.preferredControlTintColor = .playerOnDisplayBackground()
        safariVC.preferredBarTintColor = .defaultBlue()

        configureBlock?(safariVC)

        present(safariVC, animated: true, completion: nil)
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
