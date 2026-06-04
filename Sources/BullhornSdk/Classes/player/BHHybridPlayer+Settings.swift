import Foundation

/// Manages playback settings: speed, sleep timer, play-next toggle.
extension BHHybridPlayer {

    func updatePlaybackSpeed(_ playbackSpeed: BHPlayerPlaybackSpeed) {
        playerItem?.playbackSettings.playbackSpeed = playbackSpeed.rawValue
        settings.playbackSpeed = playbackSpeed.rawValue

        let request = BHTrackEventRequest.createRequest(
            category: .player, action: .ui, banner: .playerSpeed,
            context: "\(playbackSpeed.rawValue)",
            podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName,
            episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, playbackSettingsUpdated: self.settings)
        }
    }

    func updateNextPlaybackSpeed() {
        guard let item = playerItem, !item.isStream, state == .playing else { return }
        updatePlaybackSpeed(settings.nextPlaybackSpeed())
    }

    func updateSleepTimer(_ value: Double) {
        if isPaused() { resume() }
        setSleepTimer(value)

        let request = BHTrackEventRequest.createRequest(
            category: .player, action: .ui, banner: .playerSleepTimer,
            context: "\(value)",
            podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName,
            episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, sleepTimerUpdated: value)
        }
    }

    func updatePlayNextSetting(_ value: Bool) {
        UserDefaults.standard.playNextEnabled = value
        
        if value {
            if isActive() { preloadNextQueueItem() }
        } else {
            mediaPlayer?.clearNextItem()
        }

        observersContainer.notifyObserversAsync {
            $0.hybridPlayer(self, playbackSettingsUpdated: self.settings)
        }
    }
}
