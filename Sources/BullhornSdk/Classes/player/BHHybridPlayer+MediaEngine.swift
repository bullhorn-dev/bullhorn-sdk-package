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

        if let fileURL = BHDownloadsManager.shared.getFileUrl(expectedPostId) {
            urlToPlay = fileURL
        }
        
        BHID3Parser.isGoodForStream(urlToPlay) { [weak self] _, _, isVideo in
            guard let self else { return }
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
        player.clearNextItem()
        if player.isPlaying() || player.isReady() { _ = player.stop() }
        lastSentPosition = 0
        lastSentDuration = 0
        mediaPlayer = nil
    }

    // MARK: - Seamless Queue Preloading

    internal func nextQueuePost() -> BHPost? { queue.next(after: playerItem?.post.postId) }

    internal func preloadNextQueueItem() {
        
        guard UserDefaults.standard.playNextEnabled else {
            mediaPlayer?.clearNextItem()
            return
        }
        
        guard !isVideoAvailable else {
            mediaPlayer?.clearNextItem()
            return
        }

        guard let nextPost = nextQueuePost() else {
            mediaPlayer?.clearNextItem()
            return
        }

        guard !nextPost.isRadioStream(),
              !nextPost.isLiveStream(),
              !nextPost.hasVideo() else {
            mediaPlayer?.clearNextItem()
            return
        }

        let offset = BHOffsetsManager.shared.offset(for: nextPost.id)?.offset ?? 0
        guard offset < 10 else {
            mediaPlayer?.clearNextItem()
            return
        }

        let expectedNextId = nextPost.id
        let urlToPlay: URL

        if let fileUrl = BHDownloadsManager.shared.getFileUrl(expectedNextId) {
            urlToPlay = fileUrl
        } else if let remoteUrl = nextPost.recording?.publishUrl,
                  BHReachabilityManager.shared.isConnected() {
            urlToPlay = remoteUrl
        } else {
            mediaPlayer?.clearNextItem()
            return
        }

        BHID3Parser.isGoodForStream(urlToPlay) { [weak self] _, _, isVideo in
            guard let self else { return }
            
            DispatchQueue.main.async {
                guard self.nextQueuePost()?.id == expectedNextId else {
                    self.mediaPlayer?.clearNextItem()
                    return
                }
                
                guard !isVideo else {
                    BHLog.p("preloadNextQueueItem: \(nextPost.title) is video — skipping preload")
                    self.mediaPlayer?.clearNextItem()
                    return
                }
                
                self.mediaPlayer?.preloadNextItem(url: urlToPlay)
                BHLog.p("Queued seamless preload for: \(nextPost.title)")
            }
        }
    }

    internal func handleSeamlessAdvance(completedItemPosition: TimeInterval) {
        BHLog.p("\(#function) completedItemPosition: \(completedItemPosition)")

        postPlaybackOffset(overridePosition: completedItemPosition,
                           overrideDuration: completedItemPosition)
        stopPlayback(send: true, position: completedItemPosition)

        guard let nextPost = nextQueuePost() else { return }

        if let completedPostId = post?.id {
            removeFromPlaybackQueue(completedPostId)
        }

        let fileUrl = BHDownloadsManager.shared.getFileUrl(nextPost.id)
        let postItem = BHPlayerItem.Post(
            postId: nextPost.id, title: nextPost.title,
            userId: nextPost.user.id, userName: nextPost.user.fullName,
            coverUrl: nextPost.coverUrl, url: nextPost.recording?.publishUrl, file: fileUrl)
        let newPlayerItem = BHPlayerItem(
            post: postItem, playbackSettings: settings,
            position: 0, duration: 0, shouldPlay: true,
            isStream: false, autoplayContext: playerItem?.autoplayContext)

        // Transition state
        UserDefaults.standard.playerPostId = nextPost.id
        lastSentPosition = 0
        lastSentDuration = 0
        manualPosition = 0

        playerItem = newPlayerItem
        post = nextPost        // triggers bulletin + transcript fetch via didSet

        // Start CDR for new episode
        startPlayback()

        // Preload the episode after next
        preloadNextQueueItem()
        
        if !hasNext() && !(playerItem?.isStream ?? false) {
            fetchPlaylist()
        }

        // Notify listeners — UI updates title, artwork etc.
        observersContainer.notifyObserversAsync { $0.hybridPlayer(self, initializedWith: newPlayerItem) }

        // Refresh NowPlaying with new episode metadata
        mediaPlayer?.updateNowPlayingItemInfo(with: composeNowPlayingItemInfo(skipCachedImage: true))
        updateNowPlayingItemInfoImage()
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

        if isEnded() {
            play(at: resultPosition)
            return true
        }

        let result = player.play(at: resultPosition, forceResume: forceResume)
        
        if result {
            mediaPlayer?.updateNowPlayingInfo()
        }
        
        BullhornSdk.shared.delegate?.bullhornSdkDidStartPlaying()
        
        return result
    }
}

