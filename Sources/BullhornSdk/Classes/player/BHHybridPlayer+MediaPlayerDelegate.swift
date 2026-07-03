import Foundation

// MARK: - BHMediaPlayerDelegate

extension BHHybridPlayer: BHMediaPlayerDelegate {

    func mediaPlayer(_ player: any BHPlaybackEngine, stateUpdated state: BHMediaPlayerBase.State) {
        handlePlayerState(state)

        guard let validItem = playerItem else { return }

        if isPlaying() && !validItem.shouldPlay {
            performPause()
            playerItem?.shouldPlay = true
        }
    }

    func mediaPlayerDidPlayToEndTime(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")

        guard let validItem = playerItem else { stop(); return }

        if validItem.isStream {
            mediaPlayerDidStall(player, reason: .noConnection)
        } else {
            let currentPos = mediaPlayer?.currentTime() ?? lastSentPosition
            let duration = mediaPlayer?.duration() ?? lastSentDuration

            if duration - currentPos > 10 {
                BHLog.p("\(#function) - Failed to play. Stop.")
                mediaPlayerFailedToPlayToEndTime(player)
            } else {
                BHLog.p("\(#function) - Ended. Try to play next.")
                handlePlayerState(.ended)
                if hasNext() && UserDefaults.standard.playNextEnabled {
                    playNext()
                }
            }
        }
    }

    func mediaPlayerDidAdvanceToNextItem(_ player: any BHPlaybackEngine, completedItemPosition: TimeInterval) {
        BHLog.p("\(#function) completedItemPosition: \(completedItemPosition)")
        handleSeamlessAdvance(completedItemPosition: completedItemPosition)
    }

    func mediaPlayerDidStall(_ player: any BHPlaybackEngine, reason: BHPlaybackState.StalledReason) {
        BHLog.p("\(#function) reason: \(reason)")

        switch reason {
        case .buffering:
            break
        case .noConnection:
            stopTrackTimer()
            let error = NSError.error(with: NSError.LocalCodes.common,
                description: "Playback stalled because of bad network connection.")
            handlePlayerState(.failed(e: error))
        }
    }

    func mediaPlayerFailedToPlayToEndTime(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")

        let error = NSError.error(with: NSError.LocalCodes.common,
            description: "Failed to play because of bad network connection.")
        handlePlayerState(.failed(e: error))
    }

    func mediaPlayerServicesWereLost(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")

        playerItem?.isStream == true ? mediaPlayerDidStall(player, reason: .noConnection) : pause()
    }

    func mediaPlayerServicesWereReset(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")
    }

    func mediaPlayerDidRequestNowPlayingItemInfo(_ player: any BHPlaybackEngine) -> BHNowPlayingItemInfo {
        guard player === mediaPlayer else { return .invalid }

        let info = composeNowPlayingItemInfo()

        if info.itemImage == nil {
            updateNowPlayingItemInfoImage()
        }
        return info
    }

    // MARK: - Picture in Picture

    func mediaPlayerDidStartPictureInPicture(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")
        observersContainer.notifyObserversAsync { $0.hybridPlayerDidStartPictureInPicture(self) }
    }

    func mediaPlayerDidStopPictureInPicture(_ player: any BHPlaybackEngine) {
        BHLog.p("\(#function)")
        observersContainer.notifyObserversAsync { $0.hybridPlayerDidStopPictureInPicture(self) }
    }

    func mediaPlayer(_ player: any BHPlaybackEngine,
                     restorePictureInPictureUI completionHandler: @escaping (Bool) -> Void) {
        BHLog.p("\(#function)")
        DispatchQueue.main.async { [weak self] in
            if let handler = self?.pipRestoreUIHandler {
                handler(completionHandler)
            } else {
                completionHandler(true)
            }
        }
    }
}

