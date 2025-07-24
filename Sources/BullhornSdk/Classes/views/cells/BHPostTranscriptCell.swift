
import UIKit
import Foundation

class BHPostTranscriptCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var timeLbl: UILabel!
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
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.backgroundColor = .primaryBackground()
        
        timeLbl.layer.masksToBounds = true
        timeLbl.layer.cornerRadius = 6
    }
    
    // MARK: - Private
    
    fileprivate func update() {
        
        timeLbl.adjustsFontForContentSizeCategory = true
        timeLbl.text = segment?.start.stringFormatted()
        timeLbl.textColor = .accent()
        timeLbl.backgroundColor = .fxPrimaryBackground()

        textLbl.adjustsFontForContentSizeCategory = true
        textLbl.text = segment?.text
        textLbl.textColor = .primary()
        
        if isSelected {
            self.contentView.backgroundColor = .fxPrimaryBackground()
            self.textLbl.font = .fontWithName(.robotoMedium, size: 14)
            self.timeLbl.font = .fontWithName(.robotoMedium, size: 14)
        } else {
            self.contentView.backgroundColor = .primaryBackground()
            self.textLbl.font = .fontWithName(.robotoRegular, size: 14)
            self.timeLbl.font = .fontWithName(.robotoRegular, size: 14)
        }
    }
}

