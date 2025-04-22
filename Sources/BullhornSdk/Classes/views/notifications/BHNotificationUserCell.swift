
import Foundation
import UIKit

class BHNotificationUserCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    var switchChangeClosure: ((Bool)->())?

    var user: BHUserShort? {
        didSet {
            update()
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
        nameLabel.text = user?.fullName
        userIcon.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
        switchControl.setOn(true, animated: false)
        switchControl.isEnabled = UserDefaults.standard.isPushNotificationsEnabled
    }
}

