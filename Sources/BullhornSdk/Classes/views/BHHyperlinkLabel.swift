import UIKit
import Foundation

open class BHHyperlinkLabel: UILabel {
    
    // MARK: - Creating the Label
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        numberOfLines = 0
        isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTapped))
        addGestureRecognizer(tap)
    }
    
    open override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            super.attributedText = {
                guard let newValue = newValue else { return nil }
                guard let validFont = font else { return nil }

                let text = NSMutableAttributedString(attributedString: newValue)
                let terms = text.string.extractURLs()

                for term in terms {
                    text.addAttributes(hyperlinkAttributes, range: term.1)
                    text.addAttribute(.font, value: validFont, range: term.1)
                }
                return text
            }()
        }
    }
    
    // MARK: - Finding Hyperlink Under Touch
    
    var hyperlinkAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.primary(),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    
    var didTapOnURL: (URL) -> Void = { url in
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        } else {
            BHLog.p("Can't open the URL: \(url)")
        }
    }
    
    @objc func handleLabelTapped(gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)

        if let url = self.url(at: tapLocation) {
            if UIApplication.shared.canOpenURL(url) {
                if url.scheme == "http" || url.scheme == "https" {
                    didTapOnURL(url)
                } else {
                    UIApplication.shared.open(url, options: [:])
                }
            } else {
                BHLog.p("Can't open the URL: \(url)")
            }
        }
    }
    
    private func checkRange(_ range: NSRange, contain index: Int) -> Bool {
        return index > range.location && index < range.location + range.length
    }

    private func url(at location: CGPoint) -> URL? {
        
        guard attributedText?.string is NSString else { return nil }
        guard let textStorage = preparedTextStorage() else { return nil }

        let layoutManager = textStorage.layoutManagers[0]
        let textContainer = layoutManager.textContainers[0]
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard characterIndex >= 0, characterIndex != NSNotFound else { return nil }

        let terms: [(URL, NSRange)] = attributedText?.string.extractURLs() ?? []
        
        for term in terms {
            if checkRange(term.1, contain: characterIndex) == true {
                return term.0
            }
        }
        
        return nil
    }
    
    private func preparedTextStorage() -> NSTextStorage? {
        guard let attributedText = attributedText, attributedText.length > 0 else { return nil }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0
        let textStorage = NSTextStorage(string: "")
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineBreakMode = lineBreakMode
        textContainer.size = textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).size
        textStorage.setAttributedString(attributedText)
        
        return textStorage
    }
}

extension NSAttributedString.Key {
    static let hyperlink = NSAttributedString.Key("hyperlink")
}
