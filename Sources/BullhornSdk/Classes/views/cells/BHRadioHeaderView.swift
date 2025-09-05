
import UIKit
import Foundation

class BHRadioHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var radioStreamsView: BHRadioStreamsView!

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
        self.radioStreamsView.playButton.accessibilityLabel = nil
    }
    
    // MARK: - Public
    
    func initialize() {
        radioStreamsView.showLaterStreams = true
    }

    func reloadData() {
        radioStreamsView.radio = BHRadioStreamsManager.shared.currentRadio
        radioStreamsView.playButton.accessibilityLabel = "Live Now"
    }

    func setup(_ hasRadioStreams: Bool = true) {
        radioStreamsView.isHidden = !hasRadioStreams
        reloadData()
    }
    
    func calculateHeight(_ hasRadioStreams: Bool = true) -> CGFloat {
        return hasRadioStreams ? radioStreamsView.calculateHeight() : 0
    }
}
