
import UIKit

class SettingTableViewCell: UITableViewCell {

    static let identifier = "SettingTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    
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
    }
    
    public func configure(with model : SettingsOption) {
        accessoryType = model.disclosure ? .disclosureIndicator : .none
        titleLabel.text = model.title
    }
}
