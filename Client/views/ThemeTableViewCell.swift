
import UIKit

class ThemeTableViewCell: UITableViewCell {

    static let identifier = "ThemeTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkmarkIcon: UIView!

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
        checkmarkIcon.isHidden = true
        self.accessibilityLabel = nil
    }
    
    public func configure(with model : ThemeOption) {
        
        titleLabel.text = model.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        checkmarkIcon.isHidden = !model.selected
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = "\(model.title)"
        self.accessibilityValue = model.selected ? "selected" : ""

        titleLabel.isAccessibilityElement = false
        checkmarkIcon.isAccessibilityElement = false
    }
}

