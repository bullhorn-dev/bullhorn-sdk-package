
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

    // MARK: - Private

    fileprivate func setup() {
        titleLabel.textColor = .primary()
        titleLabel.font = UIFont.fontWithName(.robotoBold , size: 18)
    }
}
