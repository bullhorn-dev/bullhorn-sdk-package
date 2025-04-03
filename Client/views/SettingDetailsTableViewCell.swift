
import UIKit

class SettingDetailsTableViewCell: UITableViewCell {

    static let identifier = "SettingDetailsTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

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
        detailsLabel.text = nil
    }
    
    public func configure(with model : SettingsDetailsOption) {
        accessoryType = model.disclosure ? .disclosureIndicator : .none
        titleLabel.text = model.title
        detailsLabel.text = model.subtitle
    }
}
