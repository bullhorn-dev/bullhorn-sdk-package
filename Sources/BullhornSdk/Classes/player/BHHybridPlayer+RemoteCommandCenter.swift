import Foundation

// MARK: - BHRemoteCommandCenterDelegate

extension BHHybridPlayer: BHRemoteCommandCenterDelegate {

    func configureRemoteCommandCenter(_ configureBlock: (BHRemoteCommandCenterManager.Mode) -> Void) {
        if let validItem = playerItem, validItem.isStream {
            configureBlock(.liveRadioStream)
        } else if playbackQueue.count > 1 {
            configureBlock(.trackList(
                backwardTimeIntervals: [settings.backwardLength],
                forwardTimeIntervals: [settings.forwardLength],
                supportedPlaybackRates: settings.supportedPlaybackRates()))
        } else {
            configureBlock(.singleTrack(
                backwardTimeIntervals: [settings.backwardLength],
                forwardTimeIntervals: [settings.forwardLength],
                supportedPlaybackRates: settings.supportedPlaybackRates()))
        }
    }

    func onRemoteCommandPlay() -> Bool {
        guard mediaPlayer != nil else { return true }
        return resume()
    }

    func onRemoteCommandPause() -> Bool {
        return performPause()
    }

    func onRemoteCommandTogglePlayPause() -> Bool {
        return isPlaying() ? performPause() : resume()
    }

    func onRemoteCommandSkipBackward() -> Bool {
        return performBackward()
    }

    func onRemoteCommandSkipForward() -> Bool {
        return performForward()
    }

    func onRemoteCommandChangePlaybackPosition(_ position: TimeInterval) -> Bool {
        return performSeek(to: position)
    }

    func onRemoteCommandPreviousTrack() -> Bool {
        return performPrevious()
    }

    func onRemoteCommandNextTrack() -> Bool {
        return performNext()
    }

    func onChangePlaybackRateCommand(_ playbackRate: Float) -> Bool {
        let speed = BHPlayerPlaybackSpeed(rawValue: playbackRate) ?? .normal
        updatePlaybackSpeed(speed)
        return true
    }
}
