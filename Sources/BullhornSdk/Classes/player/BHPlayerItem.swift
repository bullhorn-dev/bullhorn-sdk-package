
import Foundation

public enum BHPlayerPlaybackSpeed: Float, CaseIterable {
    case zeroTwoFive  = 0.75
    case zeroFiveZero = 1.0
    case normal       = 1.25
    case oneTwoFive   = 1.5
    case oneFiveZero  = 1.75
    case twoZero      = 2

    func getTitle() -> String {
        switch self {
        case .zeroTwoFive:  return ".75x"
        case .zeroFiveZero: return "1x"
        case .normal:       return "1.25x"
        case .oneTwoFive:   return "1.5x"
        case .oneFiveZero:  return "1.75x"
        case .twoZero:      return "2x"
        }
    }
    
    func getNext() -> Float {
        switch self {
        case .zeroTwoFive:
            return BHPlayerPlaybackSpeed.zeroFiveZero.rawValue
        case .zeroFiveZero:
            return BHPlayerPlaybackSpeed.normal.rawValue
        case .normal:
            return BHPlayerPlaybackSpeed.oneTwoFive.rawValue
        case .oneTwoFive:
            return BHPlayerPlaybackSpeed.oneFiveZero.rawValue
        case .oneFiveZero:
            return BHPlayerPlaybackSpeed.twoZero.rawValue
        case .twoZero:
            return BHPlayerPlaybackSpeed.zeroTwoFive.rawValue
        }
    }

    func isActive() -> Bool { return self != .normal }
}

public enum BHPlayerSleepTime: Double {
    case off        = 0
    case fiveMin    = 300
    case fifteenMin = 900
    case thirtyMin  = 1800
    case oneHour    = 3600
    case twoHours   = 7200

    func getTitle() -> String {
        switch self {
        case .off:        return "Off"
        case .fiveMin:    return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin:  return "30m"
        case .oneHour:    return "1h"
        case .twoHours:   return "2h"
        }
    }
    
    func getLongTitle() -> String {
        switch self {
        case .off:        return "Off"
        case .fiveMin:    return "5 minutes"
        case .fifteenMin: return "15 minutes"
        case .thirtyMin:  return "30 minutes"
        case .oneHour:    return "1 hour"
        case .twoHours:   return "2 hours"
        }
    }
}

public struct BHPlayerItem: Codable {

    var post: Post
    var playbackSettings: PlaybackSettings
    var position: Double
    var duration: Double
    var shouldPlay: Bool
    let isStream: Bool
    
    func debugDescription() {
        BHLog.p("PlayerItem post: \(post.debugDescription()), position: \(position), duration: \(duration), shouldPlay: \(shouldPlay), isStream: \(isStream)")
    }
    
    struct Post: Codable {

        let postId: String
        let title: String?
        let userId: String?
        let userName: String?
        let userImageUrl: URL?
        let url: URL?
        var file: URL?
        
        func debugDescription() {
            BHLog.p("Post postId: \(postId), title: \(title ?? ""), userId: \(userId ?? ""), userName: \(userName ?? ""), userImageUrl: \(userImageUrl?.absoluteString ?? ""), url: \(url?.absoluteString ?? ""), file: \(file?.absoluteString ?? "")")
        }
    }
    
    struct PlaybackSettings: Equatable, Codable {
        
        enum StreamMode: Int, Codable {
            case none = 0
            case live
            case past
            case ended
        }
        
        enum VideoQuality: Int, Codable {
            case auto = 0
            case low
            case high
        }
        
        var playbackSpeed: Float
        var forwardLength: Double
        var backwardLength: Double
        var streamMode: StreamMode
        var videoQuality: VideoQuality

        static let initial = PlaybackSettings.init(playbackSpeed: Constants.defaultPlaybackSpeed, forwardLength: Constants.defaultSeekInterval, backwardLength: Constants.defaultSeekInterval, streamMode: .none, videoQuality: .auto)
        
        func debugDescription() {
            BHLog.p("PlaybackSettings playbackSpeed: \(playbackSpeed), forwardLength: \(forwardLength), backwardLength: \(backwardLength), streamMode: \(streamMode.rawValue), videoQuality: \(videoQuality.rawValue)")
        }
        
        func playbackSpeedString() -> String {
            guard let val = BHPlayerPlaybackSpeed(rawValue: playbackSpeed) else { return "1x" }
            return val.getTitle()
        }
        
        func supportedPlaybackRates() -> [Float] {
            return BHPlayerPlaybackSpeed.allCases.map({ $0.rawValue })

        }
        
        func nextPlaybackSpeed() -> Float {
            return BHPlayerPlaybackSpeed(rawValue: playbackSpeed)?.getNext() ?? Constants.defaultPlaybackRate
        }
    }
}

public enum BHPlayerContext: String {
    case app = "app"
    case carplay = "carplay"
}

