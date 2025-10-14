
import Foundation
import UIKit

class BHChannelCollectionViewCell: UICollectionViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    var channel: BHChannel? {
        didSet {
            self.update()
        }
    }
    
    lazy var titleLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.font = .settingsPrimaryText()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .navigationText()
        label.layer.borderColor = UIColor.navigationBackground().cgColor
        label.layer.borderWidth = 1.5
        label.layer.masksToBounds = true
        label.backgroundColor = .navigationBackground()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        return label
    }()
    
    private let labelHeight: CGFloat = 32.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.layer.cornerRadius = labelHeight / 2
    }
        
    // MARK: - UI Setup

    private func setupUI() {
        
        self.contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
                
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
        
        titleLabel.layer.cornerRadius = labelHeight / 2
    }
    
    private func update() {
        guard let validChannel = channel else { return }

        let isSelected = UserDefaults.standard.selectedChannelId == validChannel.id

        titleLabel.text = validChannel.title

        if isSelected {
            titleLabel.textColor = .navigationText()
            titleLabel.font = .fontWithName(.robotoMedium, size: 17)
            titleLabel.backgroundColor = .navigationBackground()
            titleLabel.layer.borderColor = UIColor.navigationBackground().cgColor
        } else {
            titleLabel.textColor = .primary()
            titleLabel.font = .fontWithName(.robotoRegular, size: 17)
            titleLabel.backgroundColor = .cardBackground()
            titleLabel.layer.borderColor = UIColor.primary().cgColor
        }
        
        self.layoutSubviews()
    }
}
