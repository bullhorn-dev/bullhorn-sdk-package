
import UIKit
import Foundation

class BHSettingToggleCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
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
        
        self.accessibilityLabel = nil
        switchControl.accessibilityLabel = nil
    }
    
    func configure(with model : SettingsToggleOption) {
        
        backgroundColor = .primaryBackground()
        
        accessoryType = .none
        
        titleLabel.text = model.title
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsPrimaryText()
        titleLabel.adjustsFontForContentSizeCategory = true
        
        switchControl.isUserInteractionEnabled = false
        switchControl.setOn(model.isActive, animated: false)
        
        setupAccessibility(with: model)
    }
    
    fileprivate func setupAccessibility(with model : SettingsToggleOption) {

        contentView.isAccessibilityElement = true
        contentView.accessibilityTraits = .selected
        contentView.accessibilityLabel = model.title

        titleLabel.isAccessibilityElement = false

        switchControl.isAccessibilityElement = true
        switchControl.accessibilityLabel = "Toggle Settings \(model.title)"
        
        self.accessibilityElements = [contentView, switchControl!]
        self.isAccessibilityElement = false
    }
}


