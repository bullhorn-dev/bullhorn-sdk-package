
import AVFoundation
import Foundation

extension CMTime {
    
    public func toTimeInterval() -> TimeInterval {
        return TimeInterval(self.seconds)
    }
}
