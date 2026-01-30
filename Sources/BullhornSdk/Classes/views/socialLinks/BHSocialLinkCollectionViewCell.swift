
import Foundation
import UIKit

class BHSocialLinkCollectionViewCell: UICollectionViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    var link: BHSocialLinkItem? {
        didSet {
            self.update()
        }
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = .primary()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryButton()
        label.textColor = .primary()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.layer.masksToBounds = true
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.layer.borderColor = UIColor.secondaryBackground().cgColor
        stackView.layer.borderWidth = 1
        stackView.layer.masksToBounds = true
        stackView.backgroundColor = .secondaryBackground()
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let itemHeight: CGFloat = 32.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.layer.cornerRadius = itemHeight / 2
    }
        
    // MARK: - UI Setup

    private func setupUI() {

        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(imageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)

        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Constants.paddingHorizontal / 3
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        contentMode = .center

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: itemHeight),
                
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: itemHeight),
        ])
        
        stackView.layer.cornerRadius = itemHeight / 2
    }
    
    private func update() {
        guard let validLink = link else { return }

        if let originalImage = UIImage.init(named: validLink.image, in: Bundle.module, with: nil) {
            let templateImage = originalImage.withRenderingMode(.alwaysTemplate)
            imageView.image = templateImage
        }
        titleLabel.text = validLink.title
        
        self.layoutSubviews()
    }
}

