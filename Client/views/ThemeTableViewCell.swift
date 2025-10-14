
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
    
    public func configure(with model : ThemeOption) {
        
        titleLabel.text = model.title
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        checkmarkIcon.isHidden = !model.selected
    }
}

