import UIKit
import Foundation

class BHSettingVersionCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    private var tripleTapHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(onTripleTapped(_:)))
        tripleTap.numberOfTapsRequired = 3
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(tripleTap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        contentView.accessibilityLabel = nil
        tripleTapHandler = nil
    }

    func configure(with model: SettingsVersionOption) {

        backgroundColor = .primaryBackground()

        selectionStyle = .none
        accessoryType = .none

        titleLabel.text = model.title
        titleLabel.textColor = .primary()
        titleLabel.font = .settingsPrimaryText()
        titleLabel.adjustsFontForContentSizeCategory = true

        versionLabel.text = model.version
        versionLabel.textColor = .secondary()
        versionLabel.font = .fontWithName(.robotoRegular, size: 15)
        versionLabel.adjustsFontForContentSizeCategory = true

        tripleTapHandler = model.handler

        contentView.isAccessibilityElement = true
        contentView.accessibilityLabel = model.title
        contentView.accessibilityValue = "App version \(model.version)"

        self.accessibilityElements = [contentView]
        self.isAccessibilityElement = false
    }

    @objc private func onTripleTapped(_ sender: UITapGestureRecognizer) {
        tripleTapHandler?()
    }
}
