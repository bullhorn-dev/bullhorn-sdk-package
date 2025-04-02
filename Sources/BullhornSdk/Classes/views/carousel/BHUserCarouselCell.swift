
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
        label.font = .fontWithName(.robotoMedium, size: 13)
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.textColor = .primary()
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoRegular, size: 12)
        label.textColor = .secondary()
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
        
    // MARK: - Private Methods
    
    private func setupUI() {
        
        let bundle = Bundle(for: Self.self)
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        let stackView = UIStackView(arrangedSubviews: [imageView, nameLabel, categoryLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 3

        contentView.addSubview(stackView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            imageView.heightAnchor.constraint(equalTo: widthAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func update() {

        imageView.sd_setImage(with: user?.coverUrl, placeholderImage: placeholderImage)
        nameLabel.text = user?.fullName
        categoryLabel.text = user?.categoryName

        if !showCategory {
            nameLabel.numberOfLines = 0
            categoryLabel.isHidden = true
            nameLabel.sizeToFit()
        }
    }
}
