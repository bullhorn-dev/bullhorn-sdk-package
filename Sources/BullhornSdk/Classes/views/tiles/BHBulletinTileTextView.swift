import UIKit
import Foundation

class BHBulletinTileTextView: BHBulletinTileBaseView {
    
    var textLabel = RichLabel()
    
    override init(with tile: BHBulletinTile) {
        super.init(with: tile)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - Private
    
    fileprivate func setup() {
        
        textLabel.textColor = .playerOnDisplayBackground()
        textLabel.font = .fontWithName(.robotoMedium, size: 18)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.isEnabled = true
        textLabel.clipsToBounds = true
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.attributedText = tile.attributedDescription()

        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
