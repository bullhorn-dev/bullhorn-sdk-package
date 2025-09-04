
import UIKit
import Foundation

class BHRadioCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var radioTitleLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var streamIcon: UIImageView!
    @IBOutlet weak var streamTitleLabel: UILabel!
    @IBOutlet weak var playButton: BHPlayButton!

    var radio: BHRadio? {
        didSet {
            update()
        }
    }

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
        
        contentView.backgroundColor = .primaryBackground()

        let shadowColor = UIColor.shadow().withAlphaComponent(0.5)
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowColor = shadowColor.cgColor
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 4
        shadowView.backgroundColor = .cardBackground()

        streamIcon.layer.cornerRadius = 8
        streamIcon.layer.borderColor = UIColor.tertiary().cgColor
        streamIcon.layer.borderWidth = 1
        streamIcon.backgroundColor = .tertiary()
        streamIcon.contentMode = .scaleToFill
        streamIcon.clipsToBounds = true
        streamIcon.isAccessibilityElement = false

        radioTitleLabel.textColor = .accent()
        radioTitleLabel.font = .sectionTitle()
        radioTitleLabel.adjustsFontForContentSizeCategory = true
        radioTitleLabel.isAccessibilityElement = false

        streamTitleLabel.textColor = .primary()
        streamTitleLabel.font = .primaryText()
        streamTitleLabel.adjustsFontForContentSizeCategory = true
        streamTitleLabel.isAccessibilityElement = false

        playButton.title = "Listen"
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func update() {
        guard let validRadio = radio else { return }
        guard let validStream = radio?.streams.first else { return }
                
        radioTitleLabel.text = validRadio.title
        streamTitleLabel.text = validStream.title
        streamIcon.sd_setImage(with: validStream.coverUrl, placeholderImage: placeholderImage)
                
        playButton.post = validRadio.asPost()
        playButton.isEnabled = true
        
        /// accessability
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = validRadio.title
    }
}

