
import UIKit
import Foundation

final class BHRichTextView: UITextView {
    
    // MARK: - Style
    
    var textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.secondaryText(),
        .foregroundColor: UIColor.primary()
    ]

    var linkAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.primary(),
        .underlineStyle: NSUnderlineStyle.single.rawValue
    ]
    
    var timestampAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.accent()
    ]

    // MARK: - Callbacks
    
    var onLinkTap: ((URL) -> Void)?
    var onTimestampTap: ((Int) -> Void)?
        
    // MARK: - Init
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isEditable = false
        isScrollEnabled = false
        isSelectable = true
        backgroundColor = .clear
        
        delegate = self
        
        dataDetectorTypes = [] // disable automatic detection if you want full control
        
        linkTextAttributes = linkAttributes
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public API
    
    func setText(_ text: String) {
        let attributed = NSMutableAttributedString(string: text, attributes: textAttributes)

        addLinks(in: text, attributed: attributed)
        addTimestamps(in: text, attributed: attributed)
            
        self.attributedText = attributed
    }
    
    // MARK: - Link Detection
    
    private func addLinks(in text: String, attributed: NSMutableAttributedString) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        for match in matches {
            if let url = match.url {
                attributed.addAttribute(.link, value: url, range: match.range)
            }
        }
    }
    
    // MARK: - Timestamp Detection
    
    private func addTimestamps(in text: String, attributed: NSMutableAttributedString) {
        let pattern = "\\b(?:\\d{1,2}:)?\\d{1,2}:\\d{2}\\b"
        let regex = try! NSRegularExpression(pattern: pattern)

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            let range = match.range
            let timeString = (text as NSString).substring(with: range)

            let parts = timeString.split(separator: ":")

            var totalSeconds = 0

            if parts.count == 2 {
                // mm:ss
                guard let minutes = Int(parts[0]),
                      let seconds = Int(parts[1]) else { continue }

                totalSeconds = minutes * 60 + seconds

            } else if parts.count == 3 {
                // hh:mm:ss
                guard let hours = Int(parts[0]),
                      let minutes = Int(parts[1]),
                      let seconds = Int(parts[2]) else { continue }

                totalSeconds = hours * 3600 + minutes * 60 + seconds
            }

            attributed.addAttribute(.timestamp, value: totalSeconds, range: range)

            // styling
            attributed.addAttributes(timestampAttributes, range: range)
        }
    }
    
    // MARK: - Tap Handling
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        guard let position = closestPosition(to: location),
              let range = tokenizer.rangeEnclosingPosition(position, with: .character, inDirection: UITextDirection.layout(.left)) else {
            return
        }
        
        let index = offset(from: beginningOfDocument, to: range.start)
        
        guard index < attributedText.length else { return }
        
        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        
        if let seconds = attributes[.timestamp] as? Int {
            onTimestampTap?(seconds)
        }
    }
}
    
// MARK: - UITextViewDelegate

extension BHRichTextView: UITextViewDelegate {

    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {

        onLinkTap?(url)
        return false
    }
}
