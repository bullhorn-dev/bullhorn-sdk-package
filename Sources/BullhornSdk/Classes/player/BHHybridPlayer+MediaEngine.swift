import Foundation

/// Manages the lifecycle of the underlying BHPlaybackEngine and all
/// lower-level perform* playback operations.
extension BHHybridPlayer {

    // MARK: - Engine lifecycle

    internal func start(with item: BHPlayerItem?, post: BHPost?, playlist: [BHPost]?) {
        stop()

        guard let validItem = item, let validPost = post else {
            BHLog.w("\(#function) - empty player item or post")
            return
        }

        UserDefaults.standard.playerPostId = validPost.id
        UserDefaults.standard.playerAutoplayContext = validItem.autoplayContext?.rawValue

        addToPlaybackQueue(validPost, reason: .auto, moveToTop: true)
        addPostsToQueue(playlist ?? [])

        lastSentPosition = validItem.position
        lastSentDuration = validItem.duration

        settings = validItem.playbackSettings
        playerItem = validItem
        self.post = post

        if !hasNext() && !validItem.isStream { fetchPlaylist() }

        observersContainer.notifyObserversAsync { $0.hybridPlayer(self, initializedWith: validItem) }

        BHRemoteCommandCenterManager.shared.delegate = self
        BHRemoteCommandCenterManager.shared.enablePlaybackControls()

        play(at: validItem.position)
    }

    internal func composeMediaPlayer(with position: Double = 0) {
        BHLog.p("\(#function) - \(position)")

        guard let validItem = playerItem else { return }
        guard var urlToPlay = validItem.post.url else { return }
        guard let validPost = post else { return }
        
        let expectedPostId = validItem.post.postId

        // Prefer cached local file if available
        if let cachedUrl = validItem.post.file {
            let fileName = cachedUrl.lastPathComponent
            if let fileURL = FileManager.default.documentsDirectory()?.appendingPathComponent(fileName),
               FileManager.default.fileExists(atPath: fileURL.path) {
                urlToPlay = fileURL
            }
        }

        BHID3Parser.isGoodForStream(validItem.post.url!) { [weak self] _, _, isVideo in
            guard let self else { return }

            // check that episode wasn't changed while url parsed
            guard self.playerItem?.post.postId == expectedPostId else {
                BHLog.p("\(#function) skipping stale callback for \(expectedPostId)")
                return
            }

            self.isVideoAvailable = isVideo || validPost.hasVideo()

            let player = BHSystemMediaPlayer(
                withUrl: urlToPlay,
                coverUrl: self.playerItem?.post.coverUrl,
                isVideo: self.isVideoAvailable)

            player.delegate = self
            player.rate = self.settings.playbackSpeed
            self.mediaPlayer = player

            if self.shouldPlayAutomatically {
                _ = self.mediaPlayer?.play(at: position)
            } else {
                _ = self.mediaPlayer?.restore(at: position)
                self.shouldPlayAutomatically = true
            }
        }
    }

    internal func destroyMediaPlayer() {
        guard let player = mediaPlayer else { return }
        if player.isPlaying() || player.isReady() { _ = player.stop() }
        lastSentPosition = 0
        lastSentDuration = 0
        mediaPlayer = nil
    }

    // MARK: - Perform methods

    @discardableResult internal func performPlay() -> Bool {
        guard let player = mediaPlayer, let validItem = playerItem else { return false }
        return player.play(at: validItem.position)
    }

    @discardableResult internal func performStop() -> Bool {
        destroyMediaPlayer()
        return true
    }

    @discardableResult internal func performResume() -> Bool {
        guard let player = mediaPlayer else { return false }
        return player.resume()
    }

    @discardableResult internal func performPause() -> Bool {
        guard let player = mediaPlayer else { return false }
        return player.pause()
    }

    @discardableResult internal func performForward() -> Bool {
        guard let player = mediaPlayer else { return false }
        let position = player.currentTime()
        let duration = max(totalDuration(), position)
        return performSeek(to: min(duration, position + settings.forwardLength))
    }

    @discardableResult internal func performBackward() -> Bool {
        guard let player = mediaPlayer else { return false }
        return performSeek(to: max(0, player.currentTime() - settings.backwardLength))
    }

    @discardableResult internal func performPrevious() -> Bool {
        guard mediaPlayer != nil, playerItem != nil else { return false }
        if hasPrevious() { playPrevious(); return true }
        return false
    }

    @discardableResult internal func performNext() -> Bool {
        guard mediaPlayer != nil, playerItem != nil else { return false }
        if hasNext() { playNext(); return true }
        return false
    }

    @discardableResult internal func performStart(with post: BHPost) -> Bool {
        let fileUrl = BHDownloadsManager.shared.getFileUrl(post.id)
        let postItem = BHPlayerItem.Post(
            postId: post.id, title: post.title,
            userId: post.user.id, userName: post.user.fullName,
            coverUrl: post.coverUrl, url: post.recording?.publishUrl, file: fileUrl)
        let item = BHPlayerItem(post: postItem, playbackSettings: settings,
            position: post.playbackOffset, duration: 0, shouldPlay: true,
            isStream: post.isRadioStream() || post.isLiveStream(),
            autoplayContext: playerItem?.autoplayContext)
        start(with: item, post: post, playlist: [])
        return true
    }

    @discardableResult internal func performSeek(to position: Double, forceResume: Bool = false) -> Bool {
        BHLog.p("\(#function) - \(position)")
        guard let player = mediaPlayer else { return false }

        let resultPosition = max(0, position)

        if isEnded() { play(at: resultPosition); return true }

        let result = player.play(at: resultPosition, forceResume: forceResume)
        if result { mediaPlayer?.updateNowPlayingInfo() }
        BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        return result
    }
}
