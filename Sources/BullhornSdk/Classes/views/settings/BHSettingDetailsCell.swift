
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

        titleLabel.text = model.title
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsPrimaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        detailsLabel.text = model.subtitle
        detailsLabel.textColor = .secondary()
        detailsLabel.font = .settingsSecondaryText()
        detailsLabel.adjustsFontForContentSizeCategory = true
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityTraits = .selected
        self.accessibilityLabel = model.title

        titleLabel.isAccessibilityElement = false
        detailsLabel.isAccessibilityElement = false
    }
}

