
import UIKit
import SDWebImage
import Foundation

class BHPostCarouselCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    class var reusableIndentifer: String { return String(describing: self) }

    var post: BHPost? {
        didSet {
            self.update()
        }
    }
    
    var playlist: [BHPost]? {
        didSet {
            self.playButton.playlist = playlist
        }
    }

    fileprivate var placeholderImage: UIImage?

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

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = .tertiary()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .primaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 3
        return label
    }()
    
    let playButton: BHPlayButton = {
        let button = BHPlayButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        return button
    }()
        
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shadowView.frame = CGRect(x: 0, y: Int(Constants.paddingVertical / 2), width: Int(frame.size.width), height: Int(frame.size.height - Constants.paddingVertical))
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var view = playButton.hitTest(playButton.convert(point, from: self), with: event)
        if view == nil {
            view = super.hitTest(point, with: event)
        }

        return view
    }
        
    // MARK: - Private Methods
    
    private func setupUI() {
        
        let iconSize: CGFloat = 80
        
        contentView.backgroundColor = .primaryBackground()
        
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        imageView.addSubview(playButton)
        
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
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
        playButton.translatesAutoresizingMaskIntoConstraints = false
        hStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStackView.centerYAnchor.constraint(equalTo: shadowView.centerYAnchor),
            hStackView.leftAnchor.constraint(equalTo: shadowView.leftAnchor, constant: Constants.paddingHorizontal),
            hStackView.rightAnchor.constraint(equalTo: shadowView.rightAnchor, constant: -Constants.paddingHorizontal),
            hStackView.heightAnchor.constraint(equalToConstant: iconSize),
            
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),

            playButton.widthAnchor.constraint(equalToConstant: max(48, iconSize / 2)),
            playButton.heightAnchor.constraint(equalToConstant: max(48, iconSize / 2)),
            playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
    }

    private func update() {
        playButton.post = post
        imageView.sd_setImage(with: post?.user.coverUrl, placeholderImage: placeholderImage)
        titleLabel.text = post?.title
        descriptionLabel.text = post?.description
    }
}
