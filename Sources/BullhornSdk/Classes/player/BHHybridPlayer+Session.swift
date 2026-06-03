import Foundation

/// Manages the track timer, sleep timer, and CDR (playback session) tracking.
extension BHHybridPlayer {

    // MARK: - Constants

    internal var trackTimerInterval: Double     { 0.9 }
    internal var playbackRecreateInterval: Double { 10.0 }
    internal var nowPlayingInfoUpdateInterval: Double { 5.0 }

    // MARK: - Stored properties (via associated objects workaround is not ideal;
    // these stay in BHHybridPlayer main body as fileprivate vars)
    // Track timer, sleep timer, counters and currentPlayback are declared
    // in BHHybridPlayer main body and accessed here.

    // MARK: - Track Timer

    internal func startTrackTimer() {
        if let t = trackTimer, t.isValid { return }
        let timer = Timer(timeInterval: trackTimerInterval, target: self,
            selector: #selector(trackTimerHandler(_:)), userInfo: nil, repeats: true)
        timer.tolerance = trackTimerInterval
        RunLoop.main.add(timer, forMode: .default)
        trackTimer = timer
    }

    internal func stopTrackTimer() {
        trackTimer?.invalidate()
        trackTimer = nil
    }

    @objc internal func trackTimerHandler(_ timer: Timer) {
        guard timer.isValid else { return }

        playerPositionChanged()

        playbackRecreateCounter += trackTimerInterval
        nowPlayingInfoUpdateCounter += trackTimerInterval

        if playbackRecreateCounter >= playbackRecreateInterval {
            stopPlayback(send: false)
            startPlayback()
        }

        if nowPlayingInfoUpdateCounter >= nowPlayingInfoUpdateInterval {
            nowPlayingInfoUpdateCounter = 0
            mediaPlayer?.updateNowPlayingItemInfo(with: nil)
        }
    }

    // MARK: - Sleep Timer

    internal func startSleepTimerIfNeeded() {
        guard !sleepTimerInterval.isZero else { return }
        if let t = sleepTimer, t.isValid { stopSleepTimer() }
        let timer = Timer(timeInterval: sleepTimerInterval, target: self,
            selector: #selector(sleepTimerHandler(_:)), userInfo: nil, repeats: false)
        timer.tolerance = sleepTimerInterval * 0.1
        RunLoop.main.add(timer, forMode: .default)
        sleepTimer = timer
    }

    internal func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
    }

    internal func setSleepTimer(_ value: Double) {
        BHLog.p("\(#function) - value: \(value)")
        sleepTimerInterval = TimeInterval(value)
        sleepTimerInterval.isZero ? stopSleepTimer() : startSleepTimerIfNeeded()
    }

    func getSleepTimerInterval() -> Double {
        guard let timer = sleepTimer, timer.isValid else { return 0 }
        return timer.fireDate.timeIntervalSinceNow
    }

    @objc internal func sleepTimerHandler(_ timer: Timer) {
        pause()
        sleepTimerInterval = 0
    }

    // MARK: - CDR Tracking

    internal func startPlayback() {
        guard currentPlayback == nil else { return }
        guard let validPost = post, let item = playerItem else { return }

        let uuid = UUID()
        let now = Date().timeIntervalSince1970
        let type = validPost.isLiveStream() ? "live-stream" : validPost.isRadioStream() ? "radio" : "pre-recorded"

        currentPlayback = BHPostPlayback(
            identifier: uuid.uuidString,
            episodeId: item.post.postId, episodeTitle: item.post.title ?? "",
            episodeType: type,
            podcastId: item.post.userId ?? "", podcastTitle: item.post.userName ?? "",
            startTime: now, endTime: now, context: context.rawValue)

        playbackRecreateCounter = 0
    }

    internal func stopPlayback(send: Bool, position overridePosition: TimeInterval? = nil) {
        let position = overridePosition ?? (mediaPlayer?.currentTime() ?? 0)

        guard position > 0 else { return }

        if let playback = currentPlayback {
            playback.finishedAt = Date().timeIntervalSince1970
            BHPlaybacksManager.shared.add(playback: playback, shouldSend: send)
            currentPlayback = nil
        } else if send {
            BHPlaybacksManager.shared.send()
        }
    }
}
