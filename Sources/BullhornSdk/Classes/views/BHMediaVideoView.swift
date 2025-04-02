
import Foundation
import UIKit

class BHMediaVideoView: UIView {
    
    private var videoLayer: UIView?
    
    var emptySpaces = BHEmptySpaces.initial() {
        didSet {
            if oldValue.left != emptySpaces.left || oldValue.right != emptySpaces.right {
                layoutSubviews()
            }
        }
    }
        
    // MARK: - Initialization
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sizeToFit()
        self.contentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sizeToFit()
        self.contentMode = .center
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()

        let k: CGFloat = frame.size.width / frame.size.height
        let w: CGFloat = frame.size.width / (1 - emptySpaces.left - emptySpaces.right)
        let h: CGFloat = w / k

        let l: CGFloat = emptySpaces.left * w
        let r: CGFloat = emptySpaces.right * w
        let v: CGFloat = (l + r) / k
        
        self.videoLayer?.frame = CGRect(x: -l, y: -v/2, width: w, height: h)
//        self.videoLayer?.center = center
    }
    
    // MARK: Public
    
    func configureVideoLayer() {
        BHLog.p("\(#function)")

        videoLayer = BHHybridPlayer.shared.getVideoLayer()

        if let validVideoView = videoLayer {
            self.addSubview(validVideoView)
        }
    }
    
    func reset() {
        BHLog.p("\(#function)")

        emptySpaces = BHEmptySpaces.initial()

        videoLayer?.removeFromSuperview()
        videoLayer = nil
    }
}
