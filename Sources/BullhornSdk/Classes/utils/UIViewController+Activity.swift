
import UIKit
import Foundation

protocol ActivityIndicatorSupport {
    var activityIndicator: BHActivityIndicatorView! { get }
}

protocol ActivityIndicatorSupportWithShowing : ActivityIndicatorSupport {

    func showActivityIndicatorView()
    func hideActivityIndicatorView()
}

protocol ActivityControlsSupport {
    func setControlsEnabled(_ enabled: Bool)
}

protocol ActivityControlsSupportWithNavigation : ActivityControlsSupport {
    func setNavigationEnabled(_ enabled: Bool)
}


extension UIViewController {

    func setActivityStateOn(_ isOn: Bool) {

        let controlsEnabled = !isOn

        if let activityControlsVC = self as? ActivityControlsSupport {
            activityControlsVC.setControlsEnabled(controlsEnabled)
        }

        if let activityControlswithNavigationVC = self as? ActivityControlsSupportWithNavigation {
            activityControlswithNavigationVC.setNavigationEnabled(controlsEnabled)
        }
        else {
            defaultSetNavigationEnabled(controlsEnabled)
        }

        if let activityIndicatorVC = self as? ActivityIndicatorSupportWithShowing {
            if isOn {
                activityIndicatorVC.showActivityIndicatorView()
            }
            else {
                activityIndicatorVC.hideActivityIndicatorView()
            }
        }
        else {
            if isOn {
                defaultShowActivityIndicatorView()
            }
            else {
                defaultHideActivityIndicatorView()
            }
        }
    }

    func defaultSetNavigationEnabled(_ enabled: Bool) {

        guard let validNavigationController = navigationController else { return }

        validNavigationController.interactivePopGestureRecognizer?.isEnabled = enabled
        validNavigationController.navigationBar.isUserInteractionEnabled = enabled

        let appearance = type(of: validNavigationController.navigationBar).appearance()
        validNavigationController.navigationBar.tintColor = enabled ? appearance.tintColor : .lightGray
    }

    func defaultShowActivityIndicatorView() {
        if let activityIndicatorSupportedVC = self as? ActivityIndicatorSupport, let validActivityIndicator = activityIndicatorSupportedVC.activityIndicator {
            view.bringSubviewToFront(validActivityIndicator)
            validActivityIndicator.isHidden = false
            validActivityIndicator.startAnimating()
        }
    }

    func defaultHideActivityIndicatorView() {
        if let activityIndicatorSupportedVC = self as? ActivityIndicatorSupport {
            activityIndicatorSupportedVC.activityIndicator?.isHidden = true
            activityIndicatorSupportedVC.activityIndicator?.stopAnimating()
        }
    }

    func defaultResetUIActivityIndicatorView() {
//        if let activityIndicatorSupportedVC = self as? ActivityIndicatorSupport {
//            activityIndicatorSupportedVC.activityIndicator?.isHidden = true
//            activityIndicatorSupportedVC.activityIndicator?.stopAnimating()
//        }
    }
}
