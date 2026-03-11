import UIKit
import Foundation

// MARK: - Tag Type

public enum BHTagType {
    case url
    case timestamp
}

// MARK: - Tag

public struct BHTag {

    let term: String
    let range: NSRange
    let type: BHTagType
    
    func timestampValue() -> Int {
        if type == .timestamp {
            return term.secondFromString
        }
        return 0
    }
}

final class BHHyperlinkLabel: UILabel {
    
    var tags = [BHTag]()
    
    // MARK: - Creating the Label
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        numberOfLines = 0
        isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTapped))
        addGestureRecognizer(tap)
    }
    
    override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            if let validNewValue = newValue, let validFont = font {
                let text = NSMutableAttributedString(attributedString: validNewValue)
                
                self.tags = extractTags(text.string)

                for tag in tags {
                    if tag.type == .url {
                        text.addAttributes(hyperlinkAttributes, range: tag.range)
                    } else {
                        text.addAttributes(timestampAttributes, range: tag.range)
                    }
                    text.addAttribute(.font, value: validFont, range: tag.range)
                }
                
                super.attributedText = text
            }
        }
    }
    
    // MARK: - Finding Hyperlink Under Touch
    
    var hyperlinkAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.primary(),
        .underlineStyle: NSUnderlineStyle.single.rawValue
    ]
    
    var timestampAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.accent()
    ]
    
    // MARK: - Finding Hyperlink Under Touch

    var didTapOnURL: (URL) -> Void = { url in
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.topViewController()?.presentSafari(url)
        } else {
            BHLog.p("Can't open the URL: \(url)")
        }
    }
    
    var didTapOnTimestamp: (Int) -> Void = { timestamp in
        BHLog.p("Handle timestamp tag: \(timestamp)")
    }
    
    @objc func handleLabelTapped(gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)

        if let tag = self.getTag(at: tapLocation) {
            if tag.type == .url, let url = URL(string: tag.term) {
                if UIApplication.shared.canOpenURL(url) {
                    if url.scheme == "http" || url.scheme == "https" {
                        didTapOnURL(url)
                    } else {
                        UIApplication.topViewController()?.presentSafari(url)
                    }
                }
            } else if tag.type == .timestamp {
                didTapOnTimestamp(tag.timestampValue())
            } else {
                BHLog.p("Failed to handle tag touch")
            }
        }
    }
    
    // MARK: - Private

    private func checkRange(_ range: NSRange, contain index: Int) -> Bool {
        return index > range.location && index < range.location + range.length
    }

    private func getTag(at location: CGPoint) -> BHTag? {
        guard attributedText?.string is NSString else { return nil }
        guard let textStorage = preparedTextStorage() else { return nil }

        let layoutManager = textStorage.layoutManagers[0]
        let textContainer = layoutManager.textContainers[0]
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard characterIndex >= 0, characterIndex != NSNotFound else { return nil }
        
        for tag in tags {
            if checkRange(tag.range, contain: characterIndex) == true {
                return tag
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
    
    private func extractTags(_ string: String) -> [BHTag] {
        var terms : [BHTag] = []
        let range = NSMakeRange(0, string.count)

        // urls

        do {
            let types: NSTextCheckingResult.CheckingType = [.link]
            let detector = try NSDataDetector(types: types.rawValue)
            detector.enumerateMatches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range, using: { (result, _, _) in
                
                if let term = result?.url, let range = result?.range {
                    let tag = BHTag(term: term.absoluteString, range: range, type: .url)
                    terms.append(tag)
                }
            })
        } catch let error as NSError {
            print(error.localizedDescription)
        }

        let timestampPattern = #"\d{1,3}(:\d{2}){1,2}"#
        
        do {
            let timestampRegex = try NSRegularExpression(pattern: timestampPattern, options: [])
            timestampRegex.enumerateMatches(in: string, range: range, using: { (result, _, _) in
                if let range = result?.range, let r = Range(range) {
                    let term = string.substring(with: r)
                    let tag = BHTag(term: term, range: range, type: .timestamp)
                    terms.append(tag)
                }
            })
        } catch let error as NSError {
            print(error.localizedDescription)
        }

        return terms
    }
}

extension NSAttributedString.Key {
    static let hyperlink = NSAttributedString.Key("hyperlink")
    static let timestamp = NSAttributedString.Key("timestamp")
}

