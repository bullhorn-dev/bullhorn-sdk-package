
import UIKit
import SDWebImage
import Foundation

class BHLivePostCarouselCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    class var reusableIndentifer: String { return String(describing: self) }

    var post : BHPost? {
        didSet {
            self.update()
        }
    }

    fileprivate var placeholderImage: UIImage?

    // MARK: - Private Properties

    private let cntView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        view.clipsToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .tertiary()
        return imageView
    }()
    
    private let tagLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.font = .fontWithName(.robotoMedium, size: 8)
        label.sizeToFit()
        label.clipsToBounds = true
        return label
    }()
    
    private let episodeLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoMedium, size: 8)
        label.textColor = .primary()
        label.text = "EPISODE"
        label.addCharacterSpacing()
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoRegular, size: 12)
        label.textColor = .secondary()
        label.numberOfLines = 2
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
        
    // MARK: - Private
    
    private func setupUI() {
        
        let bundle = Bundle(for: Self.self)
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        cntView.addSubview(imageView)
        cntView.addSubview(tagLabel)
        
        let stackView = UIStackView(arrangedSubviews: [cntView, episodeLabel, titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 3

        contentView.addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        cntView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cntView.widthAnchor.constraint(equalToConstant: Constants.userProfileIconSize),
            cntView.heightAnchor.constraint(equalToConstant: Constants.userProfileIconSize),
            imageView.widthAnchor.constraint(equalToConstant: Constants.userProfileIconSize - 4),
            imageView.heightAnchor.constraint(equalToConstant: Constants.userProfileIconSize - 4),
            imageView.topAnchor.constraint(equalTo: cntView.topAnchor, constant: 2),
            imageView.centerXAnchor.constraint(equalTo: cntView.centerXAnchor),
            tagLabel.centerXAnchor.constraint(equalTo: cntView.centerXAnchor),
            tagLabel.bottomAnchor.constraint(equalTo: cntView.bottomAnchor),
            tagLabel.heightAnchor.constraint(equalToConstant: 16),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func update() {
        imageView.sd_setImage(with: post?.user.coverUrl, placeholderImage: placeholderImage)
        titleLabel.text = post?.title
        updateTagLabel()
    }
    
    private func updateTagLabel() {
        guard let validPost = post else { return }
        
        var text: String = "UPCOMING"
        var color: UIColor = .clear

        if validPost.isLiveNow() {
            if validPost.liveStatus.isScheduled() {
                text = "UPCOMING"
                color = .defaultBlue()
            } else {
                text = "LIVE"
                color = .accent()
            }
        }

        tagLabel.isHidden = text.isEmpty
        tagLabel.text = text
        tagLabel.textColor = .onAccent()
        tagLabel.backgroundColor = color
        tagLabel.layer.cornerRadius = 4
        tagLabel.addCharacterSpacing()
        
        tagLabel.paddingLeft = 6
        tagLabel.paddingRight = 6
        tagLabel.paddingTop = 3
        tagLabel.paddingBottom = 3
        
        cntView.layer.borderColor = color.cgColor
    }
}
