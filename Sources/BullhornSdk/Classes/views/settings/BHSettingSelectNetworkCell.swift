
import UIKit

class BHSettingSelectNetworkCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkmarkIcon: UIView!
    @IBOutlet weak var textField: BHInputTextField!
    @IBOutlet weak var saveButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        saveButton.layer.cornerRadius = saveButton.frame.size.height / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        checkmarkIcon.isHidden = true
        textField.isHidden = true
        saveButton.isHidden = true
    }
    
    // MARK: - Public
    
    public func configure(with model : SettingsRadioOption) {
        
        textField.textContentType = .username
        textField.keyboardType = .emailAddress
        textField.textInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        textField.font = .fontWithName(.robotoRegular, size: 17)
        textField.adjustsFontForContentSizeCategory = true
        textField.isHidden = !model.hasText
        textField.backgroundColor = .fxPrimaryBackground()
        textField.delegate = self
        
        titleLabel.text = model.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        titleLabel.textColor = .primary()
        checkmarkIcon.isHidden = !model.selected
        
        saveButton.isHidden = !model.hasText
        let font = UIFont.fontWithName(.robotoBold, size: 17)
        let saveTitle = NSLocalizedString("Save custom network", comment: "")
        let attrSaveTitle = NSAttributedString(string: saveTitle, attributes: [
            NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor : UIColor.white])
        saveButton.setAttributedTitle(attrSaveTitle, for: UIControl.State.normal)
        validateSaveButton()
    }
    
    // MARK: - Private
    
    fileprivate func validateSaveButton() {
        if textField.text?.isEmpty == true {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onSave(_ sender: Any) {
        
    }
}

// MARK: - UITextFieldDelegate

extension BHSettingSelectNetworkCell: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        validateSaveButton()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}


