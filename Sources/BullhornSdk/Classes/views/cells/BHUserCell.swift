import Foundation
import UIKit

class BHUserCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: RichLabel!
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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Only bounds-dependent work belongs here
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 8).cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        userIcon.sd_cancelCurrentImageLoad()
        userIcon.image = placeholderImage

        self.accessibilityLabel = nil
        contentView.accessibilityLabel = nil
        nameLabel.accessibilityLabel = nil
        bioLabel.accessibilityLabel = nil
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }

    fileprivate func setupAppearance() {

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
        nameLabel.numberOfLines = 2
        nameLabel.adjustsFontForContentSizeCategory = true

        // The name label keeps its intrinsic height (1-2 lines),
        // the bio stretches to fill the remaining vertical space
        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)
        bioLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        bioLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        bioLabel.backgroundColor = .clear
        bioLabel.textColor = .primary()
        bioLabel.font = .secondaryText()
        bioLabel.textAlignment = .left
        bioLabel.numberOfLines = 0
        bioLabel.isEnabled = true
        bioLabel.clipsToBounds = true
        bioLabel.adjustsFontForContentSizeCategory = true
    }
    
    fileprivate func update() {
        
        nameLabel.text = user?.fullName
        bioLabel.attributedText = user?.attributedBio(isActive: false, baseColor: .primary())
        userIcon.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)

        /// accessability
        guard let fullName = user?.fullName else {
            self.isAccessibilityElement = false
            return
        }

        contentView.isAccessibilityElement = true
        contentView.accessibilityTraits = .button
        contentView.accessibilityLabel = "\(context) \(fullName)"

        nameLabel.accessibilityLabel = user?.fullName
        bioLabel.accessibilityLabel = user?.bio
        
        self.accessibilityElements = [contentView, nameLabel!, bioLabel!]
        self.isAccessibilityElement = false
    }
}
