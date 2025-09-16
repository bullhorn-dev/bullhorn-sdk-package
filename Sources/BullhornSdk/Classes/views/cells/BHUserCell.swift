
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
    
    var context: String = "Podcast"

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
        shadowView.isAccessibilityElement = false
        
        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        userIcon.isAccessibilityElement = false

        nameLabel.textColor = .primary()
        nameLabel.font = .primaryText()
        nameLabel.adjustsFontForContentSizeCategory = true

        bioLabel.textColor = .primary()
        bioLabel.font = .secondaryText()
        bioLabel.adjustsFontForContentSizeCategory = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func update() {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.lineBreakMode = .byWordWrapping

        if let name = user?.fullName {
            let attributedString = NSAttributedString(string: name, attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.primaryText()
            ])
            nameLabel.attributedText = attributedString
        }

        if let bio = user?.bio {
            let attributedString = NSAttributedString(string: bio, attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.secondaryText()
            ])
            bioLabel.attributedText = attributedString
        }

        userIcon.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
        
        /// accessability
        guard let fullName = user?.fullName else {
            self.isAccessibilityElement = false
            return
        }
        self.isAccessibilityElement = true
        self.accessibilityTraits = .selected
        self.accessibilityLabel = "\(context) \(fullName)"
    }
}
