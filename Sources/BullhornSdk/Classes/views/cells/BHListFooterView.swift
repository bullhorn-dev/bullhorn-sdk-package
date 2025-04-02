
import Foundation
import UIKit

class BHListFooterView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!

    // MARK: - Lifecycle
    
    func setup() {
        
        contentView.backgroundColor = .clear

        activityIndicator.type = .ballPulse
        activityIndicator.color = .accent()
        activityIndicator.startAnimating()
    }
}
