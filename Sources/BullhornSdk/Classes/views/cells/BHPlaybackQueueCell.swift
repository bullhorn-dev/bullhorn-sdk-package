
import UIKit
import Foundation

class BHPlaybackQueueCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var manuallyIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var playButton: BHPlayButton!

    var item: BHQueueItem? {
        didSet {
            update()
        }
    }
    
    var isActive: Bool = false
    
    var context: String = "Episode"
    
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
        
        backgroundColor = isActive ? .fxPrimaryBackground() : .cardBackground()
        playView.isHidden = !isActive
        
        titleLabel.textColor = .primary()
        titleLabel.font = .primaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        manuallyIcon.tintColor = .secondary()

        nameLabel.textColor = .secondary()
        nameLabel.font = .secondaryText()
        nameLabel.adjustsFontForContentSizeCategory = true
        
        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        userIcon.isAccessibilityElement = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        contentView.accessibilityLabel = nil
        playButton.accessibilityLabel = nil
    }

    // MARK: - Private
    
    fileprivate func update() {
        
        titleLabel.text = item?.post.title
        nameLabel.text = item?.post.user.fullName
        userIcon.sd_setImage(with: item?.post.user.coverUrl, placeholderImage: placeholderImage)
        playButton.post = item?.post
        manuallyIcon.isHidden = item?.reason != .manually

        setupAccessibility()
    }
    
    private func setupAccessibility() {
        guard let title = item?.post.title else { return }

        contentView.isAccessibilityElement = true
        contentView.accessibilityTraits = .selected
        contentView.accessibilityLabel = "\(context) \(title)"
        playButton.isAccessibilityElement = true
        playButton.context = "Play \(context) \(title)"

        self.accessibilityElements = [contentView, playButton!]
        self.isAccessibilityElement = false
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
}
