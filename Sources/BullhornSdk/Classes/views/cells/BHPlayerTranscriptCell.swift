
import UIKit
import Foundation

class BHPlayerTranscriptCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var textLbl: UILabel!

    var postId: String?

    var segment: BHSegment? {
        didSet {
            update()
        }
    }
    
    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.backgroundColor = .clear
    }
    
    // MARK: - Private
    
    func update() {
        textLbl.adjustsFontForContentSizeCategory = true
        textLbl.text = segment?.text
        textLbl.font = .fontWithName(.robotoMedium, size: 23)
        textLbl.textColor = isSelected ? .playerOnDisplayBackground() : .secondary()
    }
        
    fileprivate func initialize() {}
}

