
import Foundation
import UIKit

protocol BHNotificationHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHNotificationHeaderView, didChange enable: Bool)
}

class BHNotificationHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var notificationsView: UIView!
    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
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
    }
    
    // MARK: - Public
    
    func setup() {
        
        contentView.backgroundColor = .primaryBackground()

        notificationsLabel.font = UIFont.fontWithName(.robotoMedium, size: 17)
        notificationsLabel.textColor = .primary()

        switchControl.onTintColor = .accent()
        switchControl.setOn(notificationsEnabledDefaultValue, animated: true)
        
        notificationsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BHNotificationHeaderView.changeSwitch)))
    }
    
    func calculateHeight(_ hasRadioStreams: Bool = true) -> CGFloat {
        return 60.0
    }
    
    // MARK: - Actions
    
    @IBAction func switchAction(_ sender: Any) {
        updateNotifications(switchControl.isOn)
    }
    
    @objc fileprivate func changeSwitch() {
        let newValue = !switchControl.isOn
        switchControl.setOn(newValue, animated: true)
        updateNotifications(newValue)
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
        
        delegate?.headerView(self, didChange: isEnable)
    }
}
