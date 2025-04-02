
import Foundation
import AVKit
import UIKit

class BHRoutePickerView: AVRoutePickerView {
        
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentMode = .scaleToFill
        self.prioritizesVideoDevices = false
                
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView() {
        
        self.tintColor = .playerOnDisplayBackground()
        self.activeTintColor = .playerOnDisplayBackground()

        self.contentMode = .scaleToFill
        self.prioritizesVideoDevices = false

        layoutSubviews()
    }
}
