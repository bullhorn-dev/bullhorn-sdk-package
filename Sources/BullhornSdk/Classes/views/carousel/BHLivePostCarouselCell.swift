
import UIKit
import SDWebImage
import FLAnimatedImage
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
    fileprivate var gifUrl: URL?

    // MARK: - Private Properties

    private let shadowView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.shadow().withAlphaComponent(0.5).cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 4
        view.backgroundColor = .cardBackground()
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        return view
    }()

    private let imageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .tertiary()
        imageView.layer.cornerRadius = 8
        imageView.layer.borderWidth = 1
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        return imageView
    }()
        
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .primaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 2
        return label
    }()

    let playButton: BHPlayButton = {
        let button = BHPlayButton(frame: CGRect(x: 0, y: 0, width: 140, height: 36))
        button.title = "Watch Now!"
        return button
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
        
        shadowView.frame = CGRect(x: 0, y: Int(Constants.paddingVertical / 2), width: Int(frame.size.width), height: Int(frame.size.height - Constants.paddingVertical))
    }
        
    // MARK: - Private
    
    private func setupUI() {
        
        let iconSize: CGFloat = 94.0

        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_radio_placeholder.png", in: bundle, with: nil)
        gifUrl = bundle.url(forResource: "ic_the_will_cain_live", withExtension: "gif")

        let vStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, playButton])
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        vStackView.distribution = .fill
        vStackView.spacing = 4
        
        let hStackView = UIStackView(arrangedSubviews: [imageView, vStackView])
        hStackView.axis = .horizontal
        hStackView.alignment = .fill
        hStackView.distribution = .fill
        hStackView.spacing = 16
        
        shadowView.addSubview(hStackView)
        contentView.addSubview(shadowView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hStackView.centerYAnchor.constraint(equalTo: shadowView.centerYAnchor),
            hStackView.leftAnchor.constraint(equalTo: shadowView.leftAnchor, constant: Constants.paddingHorizontal),
            hStackView.rightAnchor.constraint(equalTo: shadowView.rightAnchor, constant: -Constants.paddingHorizontal),
            hStackView.heightAnchor.constraint(equalToConstant: iconSize),
            imageView.widthAnchor.constraint(equalToConstant: iconSize / 0.75),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),
            titleLabel.heightAnchor.constraint(equalToConstant: 22.0),
            playButton.heightAnchor.constraint(equalToConstant: 36.0),
        ])
    }

    private func update() {
        playButton.post = post
        imageView.sd_setImage(with: gifUrl, placeholderImage: placeholderImage)
        titleLabel.text = post?.title
        titleLabel.sizeToFit()
        descriptionLabel.text = post?.description
    }
}
