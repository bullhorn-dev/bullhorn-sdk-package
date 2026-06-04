import Foundation

extension BHHybridPlayer: BHPlaybackQueueDelegate {

    // Единственная точка, где изменение очереди влияет на движок.
    // Заменяет три повтора `if isActive { clearNextItem; preloadNextQueueItem }`.
    func playbackQueueDidChange(_ queue: BHPlaybackQueueManager) {
        guard isActive() else { return }
        mediaPlayer?.clearNextItem()
        preloadNextQueueItem()
    }

    // MARK: - Public facade (имена сохранены ради внешних вызовов)

    func addToPlaybackQueue(_ post: BHPost, reason: BHQueueReason = .auto, moveToTop: Bool = false) {
        queue.add(post, reason: reason, moveToTop: moveToTop, hasCurrentItem: self.post != nil)
    }

    func addPostsToQueue(_ playlist: [BHPost]) {
        queue.append(playlist)
    }

    func removeFromPlaybackQueue(_ postId: String) {
        queue.remove(postId)
    }

    func removeQueue(_ withManually: Bool = false) {
        queue.clear(includingManual: withManually)
    }

    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        queue.updatePlayback(postId, offset: offset, completed: completed)
    }

    func isInQueue(_ postId: String) -> Bool { queue.contains(postId) }
    func hasQueue() -> Bool { !queue.isEmpty }

    func composeOrderedQueue(_ activePostId: String, posts: [BHPost]?, order: BHPlaybackQueueManager.BHQueueOrder) -> [BHPost]? {
        queue.orderedQueue(activePostId, posts: posts, order: order)
    }

    // Не трогают массив очереди — остаются здесь как были.
    func shouldShowQueueButton() -> Bool {
        guard let validPost = post else { return false }
        return UserDefaults.standard.playNextEnabled && validPost.hasRecording()
            && !validPost.isRadioStream() && !validPost.isLiveStream()
    }

    func isFullScreenEnabled() -> Bool {
        guard let validPost = post else { return false }
        return !validPost.isRadioStream()
    }

    func updateQueueItems() {
        queue.load { [weak self] in
            DispatchQueue.main.async { self?.restorePlayer() }
        }
    }

    func restorePlayer() {
        BHLog.p("\(#function)")
        guard let playedPostId = UserDefaults.standard.playerPostId, !playedPostId.isEmpty,
              let playedItem = queue.item(for: playedPostId) else { return }

        let autoplayContext = BHAutoplayContext(
            rawValue: UserDefaults.standard.playerAutoplayContext ?? BHAutoplayContext.actual.rawValue) ?? .actual

        shouldPlayAutomatically = false
        playRequest(with: playedItem.post, playlist: [], autoplayContext: autoplayContext,
                    position: playedItem.post.playbackOffset)
    }
}
