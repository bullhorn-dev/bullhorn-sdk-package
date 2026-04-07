
import Foundation
import UIKit

class BHPostDescriptionCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var label: BHHyperlinkLabel!
    
    var post: BHPost? {
        didSet {
            setup(with: didTapOnUrl, timestampHandler: didTapOnTimestamp)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }

    // MARK: - Private

    fileprivate func setup(with urlHandler: @escaping (URL) -> Void, timestampHandler: @escaping (Int) -> Void) {
        
        let attributedString = NSMutableAttributedString(string: post?.trimmedDescription ?? "")
                
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        label.textColor = .primary()
        label.font = .fontWithName(.robotoRegular, size: 14)
        label.attributedText = attributedString
        label.didTapOnURL = urlHandler
        label.didTapOnTimestamp = timestampHandler
        label.textAlignment = .left
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityLabel = post?.trimmedDescription
    }
    
    // MARK: - Actions

    private func didTapOnUrl(_ url: URL) {
        BHLog.p("\(#function) url: \(url.absoluteString)")

        UIApplication.topViewController()?.presentSafari(url)
    }
    
    private func didTapOnTimestamp(_ timestamp: Int) {
        BHLog.p("\(#function) seconds: \(timestamp)")
        
        guard let validPost = post else { return }
        
        if validPost.isLiveNow() {
            BHLivePlayer.shared.playRequest(with: validPost)
        } else {
            if BHHybridPlayer.shared.isPostActive(validPost.id) {
                BHHybridPlayer.shared.seek(to: Double(timestamp), resume: true)
            } else {
                BHHybridPlayer.shared.playRequest(with: validPost, playlist: [], autoplayContext: BHAutoplayContext.actual.rawValue, position: Double(timestamp))
            }
        }
    }
}
