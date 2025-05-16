
import Foundation
import UIKit

protocol BHNotificationHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHNotificationHeaderView, didChange enable: Bool)
}

class BHNotificationHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var notificationsView: UIStackView!
    @IBOutlet weak var enableNotificationsButton: UIButton!
    
    weak var delegate: BHNotificationHeaderViewDelegate?

    private let notificationsEnabledDefaultValue = UserDefaults.standard.isPushNotificationsEnabled

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        enableNotificationsButton.layer.cornerRadius = enableNotificationsButton.frame.size.height / 2
    }
    
    // MARK: - Public
    
    func updateControls() {
        
        contentView.backgroundColor = .primaryBackground()

        let enable = UserDefaults.standard.isPushNotificationsEnabled
        let title = enable ? "Disable Push Notifications" : "Enable Push Notifications"
        let color = enable ? UIColor.accent() : UIColor.primary()
        
        enableNotificationsButton.setTitle(title, for: .normal)
        enableNotificationsButton.backgroundColor = .fxPrimaryBackground()
        enableNotificationsButton.setTitleColor(color, for: .normal)
        enableNotificationsButton.titleLabel?.font = .fontWithName(.robotoBold, size: 17)
    }
    
    func calculateHeight(_ hasRadioStreams: Bool = true) -> CGFloat {
        return 50.0
    }
    
    // MARK: - Actions
    
    @IBAction func onEnableNotificationsButton(_ sender: UIButton) {
        updateNotifications(!UserDefaults.standard.isPushNotificationsEnabled)
    }
        
    // MARK: - Private
    
    private func updateNotifications(_ isEnable: Bool) {
        BHLog.p("\(#function) - isEnable: \(isEnable)")
        
        UserDefaults.standard.isPushNotificationsEnabled = isEnable

        if isEnable {
            BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
        } else {
            BHNotificationsManager.shared.forgetPushToken() { _ in }
        }
        
        updateControls()
        delegate?.headerView(self, didChange: isEnable)
    }
}
