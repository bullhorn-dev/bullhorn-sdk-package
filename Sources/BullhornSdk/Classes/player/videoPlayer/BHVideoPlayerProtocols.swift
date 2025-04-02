
import UIKit
import Foundation

extension BHVideoPlayerControlView {

    enum ButtonType: Int {
        case play       = 101
        case pause      = 102
        case back       = 103
        case fullscreen = 105
        case replay     = 106
    }
}

extension BHVideoPlayer {

    static func formatSecondsToString(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        let min = Int(seconds / 60)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
}
