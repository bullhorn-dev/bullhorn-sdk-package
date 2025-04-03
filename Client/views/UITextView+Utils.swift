
import UIKit

extension UITextView {

    func addHyperLinksToText(originalText: String, style: NSMutableParagraphStyle, hyperLinks: [String: String]) {

        let attributedOriginalText = NSMutableAttributedString(string: originalText)
    
        for (hyperLink, urlString) in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.fontWithName(.robotoRegular, size: 14), range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.secondary(), range: fullRange)
        }

        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.primary(),
            NSAttributedString.Key.font: UIFont.fontWithName(.robotoMedium, size: 15),
//            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        self.textColor = UIColor.primary()
        self.attributedText = attributedOriginalText
    }
}
