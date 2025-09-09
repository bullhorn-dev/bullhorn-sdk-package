
import UIKit

class BHSettingRadioCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkmarkIcon: UIView!
    @IBOutlet weak var textField: BHInputTextField!
//    @IBOutlet weak var saveButton: UIButton!

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
        textField.isHidden = true
    }
    
    public func configure(with model : SettingsRadioOption) {
        
        textField.textContentType = .username
        textField.keyboardType = .emailAddress
        textField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        textField.font = .fontWithName(.robotoRegular, size: 17)
        textField.adjustsFontForContentSizeCategory = true
        textField.isHidden = !model.hasText
//        textField.backgroundColor = .secondaryBackground()

        titleLabel.text = model.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        checkmarkIcon.isHidden = !model.selected
    }
}

