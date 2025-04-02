import UIKit
import Foundation

class BHBulletinTileTextView: BHBulletinTileBaseView {
    
    var textLabel = BHHyperlinkLabel()
    
    override init(with tile: BHBulletinTile) {
        super.init(with: tile)
        
        setup(with: didTap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - Private
    
    fileprivate func setup(with tapHandler: @escaping (URL) -> Void) {
        
        let attributedString = NSMutableAttributedString(string: tile.description ?? "")
        let terms: [(URL, NSRange)] = tile.description?.extractURLs() ?? []
        var termsDictionary: [String : (URL, NSRange)] = [:]
        
        for term in terms {
            termsDictionary[term.0.absoluteString] = (url: term.0, range: term.1)
        }

        termsDictionary.enumerated().forEach { index, value in
            let linkAttribute: NSAttributedString.Key = .hyperlink
            let attributes: [NSAttributedString.Key: Any] = [
                linkAttribute: value.1
            ]
            let urlAttributedString = NSAttributedString(string: value.0, attributes: attributes)
            let range = value.1.1
            if (range.location + range.length) < attributedString.length {
                attributedString.replaceCharacters(in: range, with: urlAttributedString)
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        textLabel.hyperlinkAttributes = [
            .foregroundColor: UIColor.playerOnDisplayBackground(),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textLabel.textColor = .playerOnDisplayBackground()
        textLabel.font = .fontWithName(.robotoMedium, size: 18)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.attributedText = attributedString
        textLabel.didTapOnURL = tapHandler

        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
    
    // MARK: - Actions

    private func didTap(_ url: URL) {
        openUrl(url)
    }
}
