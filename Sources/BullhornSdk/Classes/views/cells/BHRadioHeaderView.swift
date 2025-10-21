
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
        radioStreamsView.accessibilityLabel = nil
    }
    
    // MARK: - Public
    
    func initialize() {
        radioStreamsView.showLaterStreams = true
    }

    func reloadData() {
        radioStreamsView.radio = BHRadioStreamsManager.shared.currentRadio
    }

    func setup(_ hasRadioStreams: Bool = true) {
        radioStreamsView.isHidden = !hasRadioStreams
        reloadData()
        
        guard let liveStream = BHRadioStreamsManager.shared.currentRadio?.streams.first else { return }

        radioStreamsView.isAccessibilityElement = true
        radioStreamsView.accessibilityLabel = "Radio \(liveStream.title)"
        radioStreamsView.accessibilityTraits = .selected

        self.accessibilityElements = [radioStreamsView!, radioStreamsView!.subviews]
        self.isAccessibilityElement = false
    }
    
    func calculateHeight(_ hasRadioStreams: Bool = true) -> CGFloat {
        return hasRadioStreams ? radioStreamsView.calculateHeight() : 0
    }
}
