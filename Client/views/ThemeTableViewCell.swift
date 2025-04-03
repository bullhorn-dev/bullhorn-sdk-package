
import UIKit

class ThemeTableViewCell: UITableViewCell {

    static let identifier = "ThemeTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkmarkIcon: UIView!

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
    }
    
    public func configure(with model : ThemeOption) {
        titleLabel.text = model.title
        checkmarkIcon.isHidden = !model.selected
    }
}
