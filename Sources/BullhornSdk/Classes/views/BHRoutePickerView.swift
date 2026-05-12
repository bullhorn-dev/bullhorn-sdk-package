
import Foundation
import AVKit
import UIKit

class BHRoutePickerView: AVRoutePickerView {
        
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateView()
    }
    
    func updateView() {
        
        self.tintColor = .playerOnDisplayBackground()
        self.activeTintColor = .playerOnDisplayBackground()

        self.contentMode = .scaleToFill
        self.prioritizesVideoDevices = false

        layoutSubviews()
    }
}
