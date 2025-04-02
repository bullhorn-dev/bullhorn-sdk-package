import UIKit
import Foundation

class BHPlayerSettingsButton: UIButton {

    var borderColorSelected: UIColor = .clear
    var borderColorDeselected: UIColor = .tertiary()

    var textColorDeselected: UIColor = .primary()
    var textColorSelected: UIColor = .onAccent()

    var bgColorDeselected: UIColor = .clear
    var bgColorSelected: UIColor = .accent()

    var active: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.font = .fontWithName(.robotoRegular, size: 12)

        if active {
            select()
        } else {
            deselect()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.size.height / 2
        layer.borderWidth = 2
    }

    // MARK: - Public

    func select() {
        active = true
        backgroundColor = bgColorSelected
        layer.borderColor = borderColorSelected.cgColor
        setTitleColor(textColorSelected, for: .normal)
    }

    func deselect() {
        active = false
        backgroundColor = bgColorDeselected
        layer.borderColor = borderColorDeselected.cgColor
        setTitleColor(textColorDeselected, for: .normal)
    }
}
