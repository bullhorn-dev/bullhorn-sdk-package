
import UIKit
import Foundation
import AVFoundation

let BHVideoPlayerConf = BHVideoPlayerManager.shared

enum BHVideoPlayerTopBarShowCase: Int {
    case always         = 0
    case horizantalOnly = 1
    case none           = 2
}

class BHVideoPlayerManager {

    static let shared = BHVideoPlayerManager()
    
    var tintColor = UIColor.playerOnDisplayBackground()

    var loaderType  = BHActivityIndicatorType.circleStrokeSpin

    var shouldAutoPlay = true
    
    var topBarShowInCase = BHVideoPlayerTopBarShowCase.always
    
    var animateDelayTimeInterval = TimeInterval(5)
    
    var allowLog = false
    
    var enableBrightnessGestures = true
    var enableVolumeGestures = true
    var enablePlaytimeGestures = true
    var enablePlayControlGestures = true
    
    var enableChooseDefinition = true
    
    internal static func asset(for resouce: BHVideoPlayerResourceDefinition) -> AVURLAsset {
        return AVURLAsset(url: resouce.url, options: resouce.options)
    }
    
    func log(_ info: String) {
        if allowLog {
            BHLog.p(info)
        }
    }
}
