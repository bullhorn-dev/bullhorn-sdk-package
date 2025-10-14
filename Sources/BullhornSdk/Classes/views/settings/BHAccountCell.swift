
import UIKit
import Foundation

class BHAccountCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var iconContainer: UIView!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconContainer.layer.cornerRadius = iconContainer.frame.size.height / 2
    }

    func configure(with model : SettingsAccountOption) {

        backgroundColor = .primaryBackground()

        titleLabel.text = model.title
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsSecondaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.text = model.subtitle?.capitalized
        subtitleLabel.textColor = .primary()
        subtitleLabel.font = .settingsPrimaryText()
        subtitleLabel.adjustsFontForContentSizeCategory = true

        iconLabel.text = model.initials ?? "A"
        iconLabel.textColor = .primary()
        iconLabel.font = .sectionTitle()
        iconLabel.textAlignment = .center
        iconLabel.adjustsFontForContentSizeCategory = true

        iconContainer.backgroundColor = model.iconBackgroundColor
        iconContainer.layer.borderWidth = 0.5
        iconContainer.layer.borderColor = UIColor.divider().cgColor
    }

}

