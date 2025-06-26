
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
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .secondaryText()
        label.textAlignment = .left
        label.textColor = .onAccent()
        label.backgroundColor = .accent()
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

        
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
        
        badgeLabel.layer.cornerRadius = badgeLabel.frame.size.height / 2
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
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: -2),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -2),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            badgeLabel.rightAnchor.constraint(equalTo: rightAnchor),
            badgeLabel.topAnchor.constraint(equalTo: topAnchor),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20.0),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20.0),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        badgeLabel.layer.cornerRadius = badgeLabel.frame.size.height / 2
    }

    private func update() {

        imageView.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
        nameLabel.text = user?.fullName
        categoryLabel.text = user?.categoryName

        if let newEpisodesCount = user?.unwatchedEpisodesCount, newEpisodesCount > 0, showBadge {
            badgeLabel.text = "  \(newEpisodesCount)  "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }

        if !showCategory || !shouldShowCategory() {
            nameLabel.numberOfLines = 0
            categoryLabel.isHidden = true
            nameLabel.sizeToFit()
        } else {
            nameLabel.numberOfLines = 1
            categoryLabel.isHidden = false
            nameLabel.sizeToFit()
        }
    }
    
    private func shouldShowCategory() -> Bool {
        let sizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraLarge,
             .extraExtraExtraLarge,
             .extraExtraLarge,
             .extraLarge:
            return false
        default:
            return true
        }
    }
}
