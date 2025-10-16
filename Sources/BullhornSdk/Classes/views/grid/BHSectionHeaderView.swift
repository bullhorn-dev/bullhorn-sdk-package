
import UIKit
import Foundation

class BHSectionHeaderView: UICollectionReusableView {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        accessibilityLabel = nil
        titleLabel.text = nil
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return CGSize(width: frame.size.width, height: 44.0)
    }

    // MARK: - Private

    fileprivate func setup() {
        titleLabel.textColor = .primary()
        titleLabel.font = .sectionTitle()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.isAccessibilityElement = false
        isAccessibilityElement = true
    }
}
