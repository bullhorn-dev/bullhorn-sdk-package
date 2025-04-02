import UIKit
import Foundation

protocol BHBulletinTileViewDelegate: AnyObject {
    func tilePollView(_ view: BHBulletinTileBaseView, didChangeTile tile: BHBulletinTile)
}

class BHBulletinTileBaseView: UIView {
    
    weak var delegate: BHBulletinTileViewDelegate?

    var tile: BHBulletinTile
    
    init(with tile: BHBulletinTile) {
        self.tile = tile

        super.init(frame: .zero)
        
        self.contentMode = .center
        self.backgroundColor = .clear
        self.sizeToFit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    //
    
    func openUrl(_ url: URL) {
        BHLog.p("\(#function) - url: \(url.absoluteString)")

        UIApplication.topViewController()?.presentSafari(url)
    }
}
