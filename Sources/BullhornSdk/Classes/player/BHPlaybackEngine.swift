import Foundation
import UIKit

// MARK: - Main Protocol

protocol BHPlaybackEngine: AnyObject {

    var delegate: BHMediaPlayerDelegate? { get set }
    var rate: Float { get set }
    var nowPlayingItemInfo: BHNowPlayingItemInfo { get }

    // MARK: Playback control
    @discardableResult func play(at time: TimeInterval, forceResume: Bool) -> Bool
    @discardableResult func restore(at time: TimeInterval) -> Bool
    @discardableResult func resume() -> Bool
    @discardableResult func pause()  -> Bool
    @discardableResult func stop()   -> Bool

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

    // MARK: Picture in Picture
    func isPictureInPicturePossible() -> Bool
    func isPictureInPictureActive()   -> Bool
    func startPictureInPicture()
    func stopPictureInPicture()

    // MARK: NowPlaying updates
    func updateNowPlayingItemInfo(with itemInfo: BHNowPlayingItemInfo?)
    func updateNowPlayingInfo()

    // MARK: - Seamless queue preloading
    func preloadNextItem(url: URL?)
    func clearNextItem()
    @discardableResult func skipToNextItem() -> Bool
}

// MARK: - Default implementations

extension BHPlaybackEngine {

    func updateNowPlayingItemInfo() {
        updateNowPlayingItemInfo(with: nil)
    }

    @discardableResult
    func play(at time: TimeInterval) -> Bool {
        return play(at: time, forceResume: false)
    }
}

// MARK: - Supporting mixin protocols

protocol BHAudioSessionManaging: AnyObject {
    func startAudioSession()
    func stopAudioSession()
}

protocol BHNowPlayingManaging: AnyObject {
    func updateNowPlayingItemInfo(with itemInfo: BHNowPlayingItemInfo?)
    func updateNowPlayingItemState(isInterrupted: Bool?)
    func clearNowPlayingInfo()
}

protocol BHSystemNotificationHandling: AnyObject {
    func configurePlayerNotifications()
    func removePlayerNotifications()
}


