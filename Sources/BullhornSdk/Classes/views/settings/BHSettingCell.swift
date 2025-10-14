
import UIKit
import Foundation

class BHSettingCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    
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
        self.accessibilityLabel = nil
        contentView.accessibilityLabel = nil
    }
    
    func configure(with model : SettingsOption) {

        backgroundColor = .primaryBackground()
        
        accessoryType = model.disclosure ? .disclosureIndicator : .none

        titleLabel.text = model.title
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsPrimaryText()
        titleLabel.adjustsFontForContentSizeCategory = true
        
        contentView.isAccessibilityElement = true
        contentView.accessibilityLabel = model.title
        contentView.accessibilityTraits = .button

        self.accessibilityElements = [contentView]
        self.isAccessibilityElement = false
    }
}

