
import Foundation

// MARK: Playback Queue

extension BHHybridPlayer {
    
    enum BHQueueOrder: Int {
        case straight
        case reversed
    }
    
    // MARK: - Public
    
    func addToPlaybackQueue(_ post: BHPost, reason: BHQueueReason = .auto, moveToTop: Bool = false) {
        BHLog.p("\(#function) - postId: \(post.id), title: \(post.title)")
        
        var validReason: BHQueueReason = reason

        if let currentIndex = playbackQueue.firstIndex(where: { $0.id == post.id }) {
            validReason = playbackQueue[currentIndex].reason == .manually ? .manually : reason
            var playbackQueueCopy = playbackQueue

            for index in 0..<currentIndex+1 {
                let item = playbackQueue[index]
                if item.reason == .auto {
                    removeStorageItem(item.post.id)
                    if let idx = playbackQueueCopy.firstIndex(where: { $0.id == item.id }) {
                        playbackQueueCopy.remove(at: idx)
                    }
                }
            }
            playbackQueue = playbackQueueCopy
        }
        
        let item = BHQueueItem(id: post.id, post: post, reason: validReason)

        if self.post == nil || moveToTop {
            playbackQueue.insert(item, at: 0)
        } else if playbackQueue.count > 0 {
            playbackQueue.insert(item, at: 1)
        }
        insertStorageItem(item)
    }
    
    func removeFromPlaybackQueue(_ postId: String) {
        BHLog.p("\(#function) - postId: \(postId)")

        if let currentIndex = playbackQueue.firstIndex(where: { $0.id == postId }) {
            playbackQueue.remove(at: currentIndex)
            removeStorageItem(postId)
        }
    }
    
    func removeQueue(_ withManually: Bool = false) {
        BHLog.p("\(#function)")

        removeStorageItems(withManually)

        if withManually {
            playbackQueue.removeAll()
        } else {
            playbackQueue.removeAll(where: { $0.reason == .auto })
        }
    }
    
    func updateQueueItems() {
        fetchStorageItems()
        restorePlayer()
    }
    
    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        let item = playbackQueue.first(where: { $0.id == postId })
        item?.post.updatePlaybackOffset(offset, completed: completed)
        
        if let validItem = item, let row = playbackQueue.firstIndex(where: {$0.id == postId}) {
            playbackQueue[row] = validItem
            updateStorageItem(validItem)
        }
    }
    
    func isInQueue(_ postId: String) -> Bool {
        return playbackQueue.contains(where: { $0.post.id == postId })
    }
    
    func hasQueue() -> Bool {
        return playbackQueue.count > 0
    }
    
    func shouldShowQueueButton() -> Bool {
        guard let validPost = post else { return false }

        return UserDefaults.standard.playNextEnabled && validPost.hasRecording() && !validPost.isRadioStream() && !validPost.isLiveStream()
    }
    
    func restorePlayer() {
        BHLog.p("\(#function)")
        
        if let playedPostId = UserDefaults.standard.playerPostId, playedPostId.count > 0 {
            if let playedItem = playbackQueue.first(where: { $0.id == playedPostId }) {
                shouldPlayAutomatically = false
                playRequest(with: playedItem.post, playlist: [], position: playedItem.post.playbackOffset)
            }
        }
    }
    
    func composeOrderedQueue(_ activePostId: String, posts: [BHPost]?, order: BHQueueOrder) -> [BHPost]?  {
        guard let unsorted = posts else { return nil }
        guard let activeIndex = posts?.firstIndex(where: { $0.id == activePostId }) else { return nil }

        switch order {
        case .straight:
            return Array(unsorted[activeIndex...])
        case .reversed:
            let itemsBeforeIndexSlice = unsorted.prefix(activeIndex)
            return Array(itemsBeforeIndexSlice).reversed()
        }
    }
    
    // MARK: - Private
        
    internal func currenItemIndex() -> Int {
        return post == nil ? -1 : 0
    }
    
    internal func addPostsToQueue(_ playlist: [BHPost]) {
        BHLog.p("\(#function)")

        for post in playlist {
            if !playbackQueue.contains(where: { $0.id == post.id }) {
                let item = BHQueueItem(id: post.id, post: post, reason: .auto)
                playbackQueue.append(item)
                insertStorageItem(item)            }
        }
    }
    
    // MARK: - Storage Providers
    
    fileprivate func fetchStorageItems() {
        DataBaseManager.shared.fetchQueue() { items in
            self.playbackQueue = items
        }
    }

    fileprivate func fetchStorageItem(_ id: String) -> BHQueueItem? {
        return DataBaseManager.shared.fetchQueueItem(with: id)
    }

    fileprivate func insertStorageItem(_ item: BHQueueItem) {
        if !DataBaseManager.shared.insertOrUpdateQueueItem(with: item) {
            BHLog.w("\(#function) - failed to insert queue item")
        }
    }

    fileprivate func updateStorageItem(_ item: BHQueueItem) {
        if !DataBaseManager.shared.updateQueueItem(with: item) {
            BHLog.w("\(#function) - failed to update queue item")
        }
    }

    fileprivate func removeStorageItem(_ id: String) {
        if !DataBaseManager.shared.removeQueueItem(with: id) {
            BHLog.w("\(#function) - failed to remove queue item")
        }
    }
    
    fileprivate func removeStorageItems(_ withManually: Bool = false) {
        if withManually {
            for item in playbackQueue {
                removeStorageItem(item.id)
            }
        } else {
            for item in playbackQueue {
                if item.reason == .auto {
                    removeStorageItem(item.id)
                }
            }
        }
    }
}
