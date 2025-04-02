import Foundation
import UIKit
import SDWebImage
import SafariServices

class BHBulletinTileAdView: BHBulletinTileBaseView {
    
    var imageView  = UIImageView()
    var linkButton = UIButton(type: .system)

    var stackView: UIStackView!

    override init(with tile: BHBulletinTile) {
        super.init(with: tile)
        
        let bundle = Bundle(for: Self.self)
        let image = UIImage(named: "ic_tile_placeholder.png", in: bundle, with: nil)

        imageView.contentMode = .scaleAspectFit
        imageView.sd_setImage(with: tile.image, placeholderImage: image)

        linkButton.setTitle("Sponsored and shared by the host. Tap to learn more", for: .normal)
        linkButton.setTitleColor(.playerOnDisplayBackground(), for: .normal)
        linkButton.titleLabel?.font = .fontWithName(.robotoLight, size: 11)
        linkButton.addTarget(self, action: #selector(onLinkAction(_:)), for: .touchUpInside)

        stackView = UIStackView(arrangedSubviews: [imageView, linkButton])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8

        let tap = UITapGestureRecognizer(target: self, action: #selector(onLinkAction(_:)))
        stackView.addGestureRecognizer(tap)

        addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 220),
            linkButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            linkButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - Actions
    
    @objc fileprivate func onLinkAction(_ sender: UITapGestureRecognizer) {
        if let url = tile.url {
            openUrl(url)
        }
    }
}
