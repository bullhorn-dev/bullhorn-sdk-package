
import UIKit

class BHSettingRadioCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

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
    }
    
    public func configure(with model : SettingsRadioOption) {
        titleLabel.text = model.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        checkmarkIcon.isHidden = !model.selected
    }
}

