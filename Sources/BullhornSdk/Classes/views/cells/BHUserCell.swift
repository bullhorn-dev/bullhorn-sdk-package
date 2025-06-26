
import Foundation
import UIKit

class BHUserCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var userIcon: UIImageView!
    
    var user: BHUser? {
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

        let shadowColor = UIColor.shadow().withAlphaComponent(0.5)
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowColor = shadowColor.cgColor
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 4
        shadowView.backgroundColor = .cardBackground()
        
        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
            
        nameLabel.textColor = .primary()
        nameLabel.font = .primaryText()
        nameLabel.adjustsFontForContentSizeCategory = true

        bioLabel.textColor = .primary()
        bioLabel.font = .secondaryText()
        bioLabel.adjustsFontForContentSizeCategory = true
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func update() {
        nameLabel.text = user?.fullName
        bioLabel.text = user?.bio
        userIcon.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
    }
}
