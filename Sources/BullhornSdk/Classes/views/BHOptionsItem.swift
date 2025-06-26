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
        label.textColor = .tertiary()
        label.textAlignment = .right
        return label
    }()

    let valueImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = .tertiary()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let contentView = UIView()
    
    var selectedValue: Float = 1
    var type: ItemType = .normal
    var valueType: ItemValueType = .text
    
    // MARK: - Lifecycle
    
    init(withType type: ItemType, valueType: ItemValueType, title: String, icon: String) {
        super.init(frame: .zero)
                
        self.type = type
        self.valueType = valueType
        
        backgroundColor = .clear

        var arrangedSubviews: [UIView] = []
        let config = UIImage.SymbolConfiguration(weight: .light)
        let color: UIColor = type == .destructive ? .accent() : .primary()

        leftImageView.image = UIImage(systemName: icon)?.withConfiguration(config)
        leftImageView.tintColor = color
        arrangedSubviews.append(leftImageView)

        titleLabel.text = title
        titleLabel.textColor = color
        arrangedSubviews.append(titleLabel)

        switch valueType {
        case .image:
            arrangedSubviews.append(valueImageView)
        case .text:
            arrangedSubviews.append(valueLabel)
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
        leftImageView.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 20),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            leftImageView.heightAnchor.constraint(equalToConstant: 20),
            leftImageView.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        switch valueType {
        case .image:
            NSLayoutConstraint.activate([
                valueImageView.heightAnchor.constraint(equalToConstant: 20),
                valueImageView.widthAnchor.constraint(equalToConstant: 20)
            ])
        case .text:
            NSLayoutConstraint.activate([
                valueLabel.heightAnchor.constraint(equalToConstant: 20),
                valueLabel.widthAnchor.constraint(equalToConstant: 100),
                valueLabel.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
                valueLabel.rightAnchor.constraint(equalTo: stackView.rightAnchor)
            ])
        }
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
}
