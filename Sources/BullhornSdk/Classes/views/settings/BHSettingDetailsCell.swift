
import UIKit
import Foundation

class BHSettingDetailsCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        detailsLabel.text = nil
        
        self.accessibilityLabel = nil
    }
    
    func configure(with model : SettingsDetailsOption) {

        backgroundColor = .primaryBackground()
        
        accessoryType = model.disclosure ? .disclosureIndicator : .none

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.lineBreakMode = .byWordWrapping

        let titleString = NSAttributedString(string: model.title, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.settingsPrimaryText()
        ])
        titleLabel.attributedText = titleString
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsPrimaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        detailsLabel.text = model.subtitle
        detailsLabel.textColor = .secondary()
        detailsLabel.font = .settingsSecondaryText()
        detailsLabel.adjustsFontForContentSizeCategory = true
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = model.title

        titleLabel.isAccessibilityElement = false
        detailsLabel.isAccessibilityElement = false
    }
}

