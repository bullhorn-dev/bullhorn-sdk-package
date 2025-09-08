
import Foundation
import UIKit

class BHChannelCollectionViewCell: UICollectionViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    var channel: BHChannel? {
        didSet {
            self.update()
        }
    }
    
    lazy var titleLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.font = .settingsPrimaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .navigationText()
        label.layer.borderColor = UIColor.navigationBackground().cgColor
        label.layer.borderWidth = 1.5
        label.layer.masksToBounds = true
        label.backgroundColor = .navigationBackground()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        return label
    }()
    
    private let labelHeight: CGFloat = 32.0

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
        titleLabel.layer.cornerRadius = labelHeight / 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }
    
    // MARK: - UI Setup

    private func setupUI() {
        
        self.contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
                
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
        
        titleLabel.layer.cornerRadius = labelHeight / 2
    }
    
    private func update() {
        guard let validChannel = channel else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        if UserDefaults.standard.selectedChannelId == validChannel.id {
            let attributedString = NSAttributedString(string: validChannel.title, attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.fontWithName(.robotoMedium, size: 17)
            ])
            titleLabel.attributedText = attributedString
            titleLabel.textColor = .navigationText()
            titleLabel.backgroundColor = .navigationBackground()
            titleLabel.layer.borderColor = UIColor.navigationBackground().cgColor
        } else {
            let attributedString = NSAttributedString(string: validChannel.title, attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.fontWithName(.robotoRegular, size: 17)
            ])
            titleLabel.attributedText = attributedString
            titleLabel.textColor = .primary()
            titleLabel.backgroundColor = .cardBackground()
            titleLabel.layer.borderColor = UIColor.primary().cgColor
        }

        /// accessability
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = "\(validChannel.title) channel"
        titleLabel.isAccessibilityElement = false
        
        self.layoutSubviews()
    }
}
