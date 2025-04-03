import Foundation
import UIKit
import SDWebImage

class BHBulletinTileImageView: BHBulletinTileBaseView {
    
    var imageView = UIImageView()
        
    override init(with tile: BHBulletinTile) {
        super.init(with: tile)

        let bundle = Bundle.module
        let image = UIImage(named: "ic_tile_placeholder.png", in: bundle, with: nil)

        imageView.contentMode = .scaleAspectFit
        imageView.sd_setImage(with: tile.image, placeholderImage: image)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
}
