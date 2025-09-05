
import Foundation
import UIKit

class BHPostDescriptionCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var label: BHHyperlinkLabel!
    
    var text: String? {
        didSet {
            setup(with: didTap)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }

    // MARK: - Private

    fileprivate func setup(with tapHandler: @escaping (URL) -> Void) {
        
        contentView.backgroundColor = .primaryBackground()

        let attributedString = NSMutableAttributedString(string: text ?? "")
        let terms: [(URL, NSRange)] = text?.extractURLs() ?? []
        var termsDictionary: [String : (URL, NSRange)] = [:]
        
        debugPrint("extractURLs: \(terms)")
        
        for term in terms {
            termsDictionary[term.0.absoluteString] = (url: term.0, range: term.1)
        }

        termsDictionary.enumerated().forEach { index, value in
            let linkAttribute: NSAttributedString.Key = .hyperlink
            let attributes: [NSAttributedString.Key: Any] = [
                linkAttribute: value.1.0
            ]
            
            let rng = Range(uncheckedBounds: (value.1.1.lowerBound, value.1.1.upperBound))

            if let attrString = text?.substring(with: rng) {
                let urlAttributedString = NSAttributedString(string: attrString, attributes: attributes)
                let range = value.1.1
                if (range.location + range.length) < attributedString.length {
                    attributedString.replaceCharacters(in: range, with: urlAttributedString)
                }
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        label.attributedText = attributedString
        label.didTapOnURL = tapHandler
        label.textAlignment = .left
        label.textColor = .primary()
        label.font = .secondaryText()
        label.adjustsFontForContentSizeCategory = true
        
        /// accessibility
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.accessibilityLabel = "Episode description item"
    }
    
    // MARK: - Actions

    private func didTap(_ url: URL) {
        BHLog.p("\(#function) url: \(url.absoluteString)")

        UIApplication.topViewController()?.presentSafari(url)
    }
}
