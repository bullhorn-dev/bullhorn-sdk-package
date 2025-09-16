
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }
    
    // MARK: - Private
    
    func update() {
        textLbl.adjustsFontForContentSizeCategory = true
        textLbl.text = segment?.text.trimmingCharacters(in: .whitespacesAndNewlines)
        textLbl.font = .fontWithName(.robotoMedium, size: 23)
        textLbl.textColor = isSelected ? .playerOnDisplayBackground() : .secondary()
        textLbl.textAlignment = .left
        
        /// accessibility
        guard let validSegment = segment else { return }

        self.isAccessibilityElement = true
        self.accessibilityTraits = .selected
        self.accessibilityLabel = "Transcript segment \(validSegment.text)"
    }
        
    fileprivate func initialize() {}
}

