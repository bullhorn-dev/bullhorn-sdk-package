
import UIKit
import SDWebImage
import Foundation

class BHUserCarouselCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    class var reusableIndentifer: String { return String(describing: self) }

    var user : BHUser? {
        didSet {
            self.update()
        }
    }
    
    var context: String = "Podcast"
    
    var showCategory: Bool = true
    var showBadge: Bool = false

    fileprivate var placeholderImage: UIImage?

    // MARK: - Private Properties

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .primaryText()
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.textColor = .primary()
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .secondaryText()
        label.textColor = .secondary()
        return label
    }()
    
    private let badgeLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .secondaryText()
        label.textAlignment = .center
        label.textColor = .onAccent()
        label.backgroundColor = .accent()
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        label.textEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        return label
    }()
    
    private let badgeSize: Double = 24.0
        
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        badgeLabel.layer.cornerRadius = badgeSize / 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return self.contentView.frame.size
    }
        
    // MARK: - Private Methods
    
    private func setupUI() {
        
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        let stackView = UIStackView(arrangedSubviews: [imageView, nameLabel, categoryLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 3

        contentView.addSubview(stackView)
        contentView.addSubview(badgeLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: -3),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -3),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            badgeLabel.rightAnchor.constraint(equalTo: rightAnchor),
            badgeLabel.topAnchor.constraint(equalTo: topAnchor),
            badgeLabel.heightAnchor.constraint(equalToConstant: badgeSize),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: badgeSize),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
                
        layoutSubviews()
    }

    private func update() {

        imageView.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
        nameLabel.text = user?.fullName
        categoryLabel.text = user?.categoryName

        if let newEpisodesCount = user?.unwatchedEpisodesCount, newEpisodesCount > 0, showBadge {
            badgeLabel.text = "\(newEpisodesCount)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }

        if !showCategory || isTextScaled() {
            categoryLabel.isHidden = true
            nameLabel.sizeToFit()
        } else {
            categoryLabel.isHidden = false
            nameLabel.sizeToFit()
        }
        
        if isTextScaled() {
            nameLabel.numberOfLines = 1
            nameLabel.lineBreakMode = .byTruncatingTail
        } else {
            nameLabel.numberOfLines = showCategory ? 1 : 0
        }
        
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        guard let fullName = user?.fullName else {
            self.isAccessibilityElement = false
            return
        }
        self.isAccessibilityElement = true
        self.accessibilityTraits = .selected
        self.accessibilityLabel = "\(context) \(fullName)"
        
        categoryLabel.isAccessibilityElement = false
        nameLabel.isAccessibilityElement = false
    }
    
    private func isTextScaled() -> Bool {
        let sizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraLarge,
             .extraExtraExtraLarge,
             .extraExtraLarge,
             .extraLarge:
            return true
        default:
            return false
        }
    }
}
