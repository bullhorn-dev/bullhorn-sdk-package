
import Foundation

// MARK: Playback Queue

extension BHHybridPlayer {
    
    func addToPlaybackQueue(_ post: BHPost, reason: BHQueueReason = .auto, moveToTop: Bool = false) {
        BHLog.p("\(#function) - postId: \(post.id), title: \(post.title)")
        
        var validReason: BHQueueReason = reason

        if let currentIndex = playbackQueue.firstIndex(where: { $0.id == post.id }) {
            validReason = playbackQueue[currentIndex].reason == .manually ? .manually : reason
            playbackQueue.remove(at: currentIndex)
            removeStorageItem(post.id)
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

        if withManually {
            playbackQueue.removeAll()
        } else {
            playbackQueue.removeAll(where: { $0.reason == .auto })
        }
    }
    
    func updateQueueItems() {
        fetchStorageItems()
    }
    
    func updatePost(_ post: BHPost) {
        if let row = playbackQueue.firstIndex(where: {$0.post.id == post.id}) {
            self.playbackQueue[row].post = post
            self.updateStorageItem(self.playbackQueue[row])
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
    
    internal func currenItemIndex() -> Int {
        return post == nil ? -1 : 0
    }
    
    internal func addPostsToQueue(_ playlist: [BHPost]) {
        BHLog.p("\(#function)")

        for post in playlist {
            if !playbackQueue.contains(where: { $0.id == post.id }) {
                let item = BHQueueItem(id: post.id, post: post, reason: .auto)
                playbackQueue.append(item)
            }
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
}
