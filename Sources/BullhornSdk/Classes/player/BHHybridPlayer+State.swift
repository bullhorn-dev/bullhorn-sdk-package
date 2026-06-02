import Foundation
import UIKit

/// Maps BHMediaPlayerBase.State to PlayerState and notifies listeners.
extension BHHybridPlayer {

    internal func handlePlayerState(_ state: BHMediaPlayerBase.State) {

        let playerState: PlayerState
        var playerStateFlags: PlayerStateFlags = .initial
        var needUpdatePosition = false

        switch state {
        case .idle:
            playerState = .idle

        case .waiting:
            playerState = .initializing
            if prevPlayerState?.state == .initializing && post?.isRadioStream() != true {
                getPlaybackOffset()
            }

        case .ready:
            playerState = .initializing

        case .playing:
            if !shouldPlayAutomatically {
                performPause()
                playerState = .paused
                shouldPlayAutomatically = true
            } else {
                playerState = .playing
                startPlayback()
                startTrackTimer()
                startSleepTimerIfNeeded()
            }
            playerPositionChanged(true)

        case .paused:
            playerState = .paused
            stopTrackTimer()
            stopPlayback(send: false)
            setSleepTimer(0)
            playbackRecreateCounter = 0
            nowPlayingInfoUpdateCounter = 0
            playerPositionChanged(true)
            needUpdatePosition = self.state.isPlaying()

        case .ended:
            playerState = .ended
            playerStateFlags = .complete
            stopTrackTimer()
            setSleepTimer(0)
            stopPlayback(send: true)
            observersContainer.notifyObserversAsync { $0.hybridPlayerDidFinishPlaying(self) }

        case .failed(let error):
            BHLog.w("\(#function) - player error: \(String(describing: error))")
            playerState = .failed
            playerStateFlags = .error
            stopTrackTimer()
            stopPlayback(send: false)
            setSleepTimer(0)

            let request = BHTrackEventRequest.createRequest(
                category: .player, action: .error, banner: .playerFailed,
                context: error.debugDescription,
                podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName,
                episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
            BHTracker.shared.trackEvent(with: request)

            observersContainer.notifyObserversAsync { $0.hybridPlayerDidFailedToPlay(self, error: error) }
        }

        self.stateFlags = playerStateFlags
        self.state = playerState

        if needUpdatePosition && post?.isRadioStream() != true { postPlaybackOffset() }

        if isSeek { isSeek = false }
        if isSilent { return }

        onStateUpdated()
    }

    internal func onStateUpdated() {
        guard playerItem != nil else { return }

        let position = state == .failed ? lastSentDuration : lastSentPosition
        let playerState = BHPlayerState(state: state, stateFlags: stateFlags,
            position: position, duration: lastSentDuration, isVideoAvailable: isVideoAvailable)

        if let prev = prevPlayerState, prev == playerState { return }
        prevPlayerState = playerState
        playerState.debugDescription()

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, stateUpdated: self.state, stateFlags: self.stateFlags)
        }
    }

    internal func playerPositionChanged(_ force: Bool = false) {
        if UIApplication.shared.applicationState != .active && !force { return }
        guard let player = mediaPlayer else { return }

        let position = player.currentTime()
        playerItem?.position = position

        let duration = max(totalDuration(), position)
        lastSentPosition = position
        lastSentDuration = duration

        if isSliding || isSeek {
            isSeek = false
            return
        }

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, positionChanged: position, duration: duration)
        }
    }
}
