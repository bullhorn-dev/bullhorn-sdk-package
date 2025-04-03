
import UIKit

class AccountTableViewCell: UITableViewCell {
    static let identifier = "AccountTableViewCell"
    
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

    override func prepareForReuse() {
        super.prepareForReuse()

        iconLabel.text = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        iconContainer.backgroundColor = nil
    }
    
    public func configure(with model : SettingsAccountOption) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle?.capitalized
        iconLabel.text = model.initials
        iconContainer.backgroundColor = model.iconBackgroundColor
    }

}
