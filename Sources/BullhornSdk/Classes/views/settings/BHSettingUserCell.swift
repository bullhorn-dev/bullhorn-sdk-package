
import Foundation
import UIKit

class BHSettingUserCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    enum ItemType {
        case notifications
        case downloads
    }
    
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    var switchChangeClosure: ((Bool)->())?
    
    var user: BHUser? {
        didSet {
            update()
        }
    }
    
    var type: ItemType = .notifications {
        didSet {
            updateValue()
        }
    }
    
    fileprivate var placeholderImage: UIImage?
    
    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.backgroundColor = .primaryBackground()
        
        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        
        nameLabel.textColor = .primary()
        nameLabel.font = .primaryText()
        nameLabel.adjustsFontForContentSizeCategory = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        switchControl.accessibilityLabel = nil
    }
    
    // MARK: - Actions
    
    @IBAction func switchAction(_ sender: Any) {
        switchChangeClosure?(switchControl.isOn)
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func update() {
        guard let validUser = user else { return }
        
        nameLabel.text = validUser.fullName
        userIcon.sd_setImage(with: validUser.coverUrl, placeholderImage: placeholderImage)
    }

    fileprivate func updateValue() {
        guard let validUser = user else { return }

        switch type {
        case .notifications:
            switchControl.setOn(validUser.receiveNotifications, animated: false)
        case .downloads:
            switchControl.setOn(validUser.autoDownload, animated: false)
        }

        switchControl.isEnabled = UserDefaults.standard.isPushNotificationsEnabled
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = "Change settings for podcast \(validUser.fullName ?? "")"

        nameLabel.isAccessibilityElement = false

        switchControl.isAccessibilityElement = true
        switchControl.accessibilityLabel = "Toggle Settings for podcast \(validUser.fullName ?? "")"
    }
}

