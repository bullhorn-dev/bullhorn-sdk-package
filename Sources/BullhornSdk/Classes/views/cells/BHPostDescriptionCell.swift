
import Foundation
import UIKit

class BHPostDescriptionCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var textView: RichTextView!
    
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
    
    func stringWithAttributes() -> NSAttributedString {
        guard let validText = post?.description else { return NSAttributedString() }
        
        let font = UIFont.fontWithName(.robotoRegular, size: 14)
        let base = Attrs().font(font).foregroundColor(.primary())
        let links = Attrs().font(font).foregroundColor(.accent())
        let timestamps = Attrs().font(font).foregroundColor(.accent())
        let a = Attrs().font(font).foregroundColor(.primary())
        let u = Attrs().underlineStyle(.single)
        let i = TagTuner { info in
            var set = Set<String>()
            set.insert(info.tag.name)
            info.outerTags.forEach { set.insert($0.name) }

            let attrs = Attrs()
            if set.contains("b") && set.contains("i") {
                attrs.font(UIFont(name: "HelveticaNeue-BoldItalic", size: 14)!)
            } else if set.contains("i") {
                attrs.font(UIFont(name: "HelveticaNeue-Italic", size: 14)!)
            } else if set.contains("b") {
                attrs.font(UIFont(name: "HelveticaNeue-Bold", size: 14)!)
            }
            return attrs
        }

        let attributedText = validText
            .style(tags: ["a": a, "u": u, "i": i])
            .styleBase(base)
            .styleLinks(links)
            .styleTimestamps(timestamps)
            .attributedString

        return attributedText
    }

    fileprivate func setup() {
        textView.backgroundColor = .clear
        textView.textAlignment = .left
        textView.isEnabled = true
        textView.highlightedLinkAttributes = Attrs().foregroundColor(.secondary()).attributes
        textView.highlightedTimestampAttributes = Attrs().foregroundColor(.secondary()).attributes
        textView.onLinkTouchUpInside = { _, val in
            if let linkStr = val as? String, let url = URL(string: linkStr) {
                BHLog.p("Open link: \(url.absoluteString)")

                UIApplication.topViewController()?.presentSafari(url)
            }
        }
        textView.onTimestampTouchUpInside = { _, val in
            if let timestamp = val as? String {
                let seconds = timestamp.secondFromString

                BHLog.p("Open timestamp: \(timestamp)")

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
        }
        textView.attributedText = stringWithAttributes()
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityLabel = post?.description
    }
}
