
import UIKit
import SDWebImage
import Foundation

class BHStreamCarouselCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    class var reusableIndentifer: String { return String(describing: self) }

    var stream: BHStream? {
        didSet {
            self.update()
        }
    }

    var titleText: String = "Later"
    
    fileprivate var placeholderImage: UIImage?
        
    fileprivate static let textHeight: CGFloat = 13.0
    fileprivate static let spacing: CGFloat = Constants.paddingVertical / 4

    static let cellWidth: CGFloat = (UIScreen.main.bounds.width - 6 * Constants.paddingHorizontal) / 3
    static let cellHeight: CGFloat = Constants.radioAspectRatio * BHStreamCarouselCell.cellWidth + BHStreamCarouselCell.textHeight + BHStreamCarouselCell.spacing

    // MARK: - Private Properties

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoMedium, size: BHStreamCarouselCell.textHeight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.numberOfLines = 1
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
        
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_radio_placeholder.png", in: bundle, with: nil)

        let stackView = UIStackView(arrangedSubviews: [nameLabel, imageView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = BHStreamCarouselCell.spacing

        contentView.addSubview(stackView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: BHStreamCarouselCell.cellWidth * Constants.radioAspectRatio),
            imageView.widthAnchor.constraint(equalToConstant: BHStreamCarouselCell.cellWidth)
        ])
        
        imageView.sd_setImage(with: nil, placeholderImage: placeholderImage)
    }

    private func update() {
        guard let validStream = stream else { return }
        imageView.sd_setImage(with: validStream.coverUrl, placeholderImage: placeholderImage)
        nameLabel.text = "\(titleText) \(validStream.localStartTime())"
    }
}

