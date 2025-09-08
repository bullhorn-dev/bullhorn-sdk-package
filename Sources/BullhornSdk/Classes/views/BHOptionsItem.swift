import UIKit
import Foundation

@IBDesignable class BHOptionsItem: UIView {
    
    enum ItemType {
        case normal
        case destructive
    }

    enum ItemValueType {
        case text
        case image
        case toggle
    }

    let leftImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = .tertiary()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoLight, size: 18)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .tertiary()
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoRegular, size: 17)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondary()
        label.textAlignment = .right
        return label
    }()

    let valueImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = .secondary()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let valueSwitch: UISwitch = {
        let toggleView = UISwitch()
        toggleView.tintColor = .navigationText()
        toggleView.onTintColor = .accent()
        toggleView.isUserInteractionEnabled = false
        return toggleView
    }()

    private let contentView = UIView()
    
    var selectedValue: Float = 1
    var type: ItemType = .normal
    var valueType: ItemValueType = .text
    
    // MARK: - Lifecycle
    
    init(withType type: ItemType, valueType: ItemValueType, title: String, icon: String?) {
        super.init(frame: .zero)
                
        self.type = type
        self.valueType = valueType
        
        backgroundColor = .clear

        var arrangedSubviews: [UIView] = []

        let font = UIFont.fontWithName(.robotoRegular, size: 18)
        let config = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .thin, scale: .medium)
        let color: UIColor = type == .destructive ? .accent() : .primary()

        if let validIcon = icon {
            leftImageView.image = UIImage(systemName: validIcon)?.withConfiguration(config)
            leftImageView.tintColor = color

            arrangedSubviews.append(leftImageView)
            leftImageView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                leftImageView.heightAnchor.constraint(equalToConstant: 28),
                leftImageView.widthAnchor.constraint(equalToConstant: 28)
            ])
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributedString = NSAttributedString(string: title, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.fontWithName(.robotoLight, size: 18)
        ])
        titleLabel.attributedText = attributedString
        titleLabel.textColor = color
        arrangedSubviews.append(titleLabel)

        switch valueType {
        case .image:
            arrangedSubviews.append(valueImageView)
            valueImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueImageView.heightAnchor.constraint(equalToConstant: 28),
                valueImageView.widthAnchor.constraint(equalToConstant: 28)
            ])
        case .text:
            arrangedSubviews.append(valueLabel)
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueLabel.heightAnchor.constraint(equalToConstant: 28),
                valueLabel.widthAnchor.constraint(equalToConstant: 100),
            ])
        case .toggle:
            arrangedSubviews.append(valueSwitch)
        }

        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16

        contentView.addSubview(stackView)
        contentView.contentMode = .center
        contentView.backgroundColor = .clear

        addSubview(contentView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        contentView.frame = self.bounds
    }
    
    // MARK: - Public
    
    func setValueImage(_ name: String?) {
        if let validName = name, !validName.isEmpty {
            let config = UIImage.SymbolConfiguration(weight: .light)
            valueImageView.image = UIImage(systemName: validName)?.withConfiguration(config)
        } else {
            valueImageView.image = nil
        }
    }
    
    func setToggleValue(_ value: Bool) {
        valueSwitch.setOn(value, animated: true)
    }
    
    func setValue(_ text: String?) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0
        paragraphStyle.alignment = .right
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        if let validText = text {
            let attributedString = NSAttributedString(string: validText, attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.fontWithName(.robotoRegular, size: 17)
            ])
            valueLabel.attributedText = attributedString
        } else {
            valueLabel.attributedText = NSAttributedString(string: "")
        }
    }
}
