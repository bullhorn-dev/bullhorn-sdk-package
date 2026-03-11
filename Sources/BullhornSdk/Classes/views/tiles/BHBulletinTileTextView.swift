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
