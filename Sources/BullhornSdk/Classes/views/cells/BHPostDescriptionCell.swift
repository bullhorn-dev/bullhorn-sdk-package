
import Foundation
import UIKit

class BHPostDescriptionCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var textView: BHRichTextView!
    
    var post: BHPost? {
        didSet {
            setup()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }

    // MARK: - Private

    fileprivate func setup() {
        guard let validText = post?.description else { return }

        textView.textColor = .primary()
        textView.font = .fontWithName(.robotoRegular, size: 14)
        textView.textAlignment = .left

        textView.setText(validText)

        textView.onLinkTap = { url in
            BHLog.p("Open link tag: \(url.absoluteString)")

            UIApplication.topViewController()?.presentSafari(url)
        }

        textView.onTimestampTap = { seconds in
            BHLog.p("Open timestamp tag seconds: \(seconds)")
            
            guard let validPost = self.post else { return }
            
            if validPost.isLiveNow() {
                BHLivePlayer.shared.playRequest(with: validPost)
            } else {
                if BHHybridPlayer.shared.isPostActive(validPost.id) {
                    BHHybridPlayer.shared.seek(to: Double(seconds), resume: true)
                } else {
                    BHHybridPlayer.shared.playRequest(with: validPost, playlist: [], autoplayContext: .podcast, position: Double(seconds))
                }
            }
        }
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityLabel = post?.description
    }
}
