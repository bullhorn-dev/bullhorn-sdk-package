import Foundation
import UIKit

// MARK: - Main Protocol

/// The contract BHHybridPlayer uses to talk to any player implementation.
///
/// Concrete players can either:
///   A) Subclass BHMediaPlayerBase — gets audio session, NowPlaying,
///      system notifications and the state machine for free.
///   B) Implement BHPlaybackEngine directly and adopt the supporting
///      mixin protocols as needed.
protocol BHPlaybackEngine: AnyObject {

    // MARK: Delegate
    var delegate: BHMediaPlayerDelegate? { get set }

    // MARK: Rate
    var rate: Float { get set }

    // MARK: NowPlaying state (read by BHHybridPlayer to build cover image info)
    var nowPlayingItemInfo: BHNowPlayingItemInfo { get }

    // MARK: Playback control
    @discardableResult func play(at time: TimeInterval, forceResume: Bool) -> Bool
    @discardableResult func restore(at time: TimeInterval) -> Bool
    @discardableResult func resume() -> Bool
    @discardableResult func pause()  -> Bool
    @discardableResult func stop()   -> Bool
    @discardableResult func retryConnection() -> Bool

    // MARK: Seeking
    func seek(to time: TimeInterval)

    // MARK: Queries
    func currentTime() -> TimeInterval
    func duration()    -> TimeInterval
    func isPlaying()   -> Bool
    func isReady()     -> Bool
    func isEnded()     -> Bool

    // MARK: Video
    func hasVideo()      -> Bool
    func getVideoLayer() -> UIView?

    // MARK: NowPlaying updates
    func updateNowPlayingItemInfo(with itemInfo: BHNowPlayingItemInfo?)
    func updateNowPlayingInfo()
}

// MARK: - Default implementations

extension BHPlaybackEngine {

    /// Convenience — refresh NowPlaying without providing new item info.
    func updateNowPlayingItemInfo() {
        updateNowPlayingItemInfo(with: nil)
    }

    /// Convenience — play(at:) without the forceResume label.
    @discardableResult
    func play(at time: TimeInterval) -> Bool {
        return play(at: time, forceResume: false)
    }
}

// MARK: - Supporting mixin protocols

/// Manages AVAudioSession lifecycle.
protocol BHAudioSessionManaging: AnyObject {
    func startAudioSession()
    func stopAudioSession()
}

/// Writes to MPNowPlayingInfoCenter.
protocol BHNowPlayingManaging: AnyObject {
    func updateNowPlayingItemInfo(with itemInfo: BHNowPlayingItemInfo?)
    func updateNowPlayingItemState(isInterrupted: Bool?)
    func clearNowPlayingInfo()
}

/// Handles AVAudioSession interruptions, route changes and media-service events.
protocol BHSystemNotificationHandling: AnyObject {
    func configurePlayerNotifications()
    func removePlayerNotifications()
}

