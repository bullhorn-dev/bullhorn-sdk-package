
import Foundation

struct BHSessionState: Equatable {

    var clientState: Int
    var audioState: Int
    var muteState: Int
    var videoState: Int
    
    static func ==(lhs: BHSessionState, rhs: BHSessionState) -> Bool {
      return lhs.clientState == rhs.clientState  && lhs.audioState == rhs.audioState &&
        lhs.muteState == rhs.muteState && lhs.videoState == rhs.videoState
    }
    
    func debugDescription() {
        BHLog.p("SessionState client: \(clientState), audio: \(audioState), mute: \(muteState), video: \(videoState)")
    }
}

struct BHPlayerState: Equatable {

    var state: PlayerState
    var stateFlags: PlayerStateFlags
    var position: Double
    var duration: Double
    var isVideoAvailable: Bool
    
    static func ==(lhs: BHPlayerState, rhs: BHPlayerState) -> Bool {
      return lhs.state == rhs.state  && lhs.stateFlags == rhs.stateFlags &&
        lhs.position == rhs.position && lhs.duration == rhs.duration && lhs.isVideoAvailable == rhs.isVideoAvailable
    }
        
    func debugDescription() {
        BHLog.p("PlayerState state: \(state), stateFlags: \(stateFlags), position: \(position), duration: \(duration), isVideoAvailable: \(isVideoAvailable)")
    }
}

enum PlayerState: Int {

    case idle = 0
    case initializing
    case playing
    case paused
    case ended
    case failed
    
    func isInitializing() -> Bool { self == .initializing }
    func isPlaying() -> Bool { self == .playing }
    func isPaused() -> Bool { self == .paused }
    func isEnded() -> Bool { self == .ended }
    func isFailed() -> Bool { self == .failed }
    func isActive() -> Bool { self == .playing || self == .paused }
}

public struct PlayerStateFlags: OptionSet {
    public let rawValue: OptionBits

    public static let initial       = PlayerStateFlags(rawValue: .min)

    public static let buffering     = PlayerStateFlags(rawValue: 1 << 1)
    public static let seeking       = PlayerStateFlags(rawValue: 1 << 2)
    public static let complete      = PlayerStateFlags(rawValue: 1 << 3)
    public static let interrupted   = PlayerStateFlags(rawValue: 1 << 4)
    public static let error         = PlayerStateFlags(rawValue: 1 << 5)

    public init(rawValue: OptionBits) { self.rawValue = rawValue }
}
