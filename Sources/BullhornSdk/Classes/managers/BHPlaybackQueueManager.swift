
import Foundation

/// Notifies the player that the queue's contents changed structurally, so the
/// player can decide whether to refresh seamless preloading. The manager never
/// touches the media engine directly — this is the only edge pointing back at
/// the player, which keeps the dependency one-directional.
protocol BHPlaybackQueueDelegate: AnyObject {
    func playbackQueueDidChange(_ queue: BHPlaybackQueueManager)
}

/// Owns the playback queue: the in-memory order, its persistence, the
/// deduplication rules on insert, and pure lookups (next / previous / contains).
///
/// Deliberately *stateless about the current episode*: the id of the currently
/// playing post is passed in per call, so there is no second source of truth
/// competing with `BHHybridPlayer.post` / `playerItem`.
final class BHPlaybackQueueManager {

    enum BHQueueOrder: Int {
        case straight
        case reversed
        case straightAndReversed
    }

    weak var delegate: BHPlaybackQueueDelegate?

    /// Read-only to the outside; every mutation goes through the methods below
    /// so persistence and change-notification stay in lockstep.
    private(set) var items: [BHQueueItem] = []

    @inline(__always)
    private func assertMain() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }

    // MARK: - Lookups

    var isEmpty: Bool { assertMain(); return items.isEmpty }
    var count: Int { assertMain(); return items.count }
    var first: BHPost? { assertMain(); return items.first?.post }

    func contains(_ postId: String) -> Bool {
        assertMain()
        return items.contains(where: { $0.post.id == postId })
    }

    func item(for postId: String) -> BHQueueItem? {
        assertMain()
        return items.first(where: { $0.id == postId })
    }

    func next(after postId: String?) -> BHPost? {
        assertMain()
        guard let postId,
              let index = items.firstIndex(where: { $0.id == postId }),
              index < items.count - 1 else { return nil }
        return items[items.index(after: index)].post
    }

    func previous(before postId: String?) -> BHPost? {
        assertMain()
        guard let postId,
              let index = items.firstIndex(where: { $0.id == postId }),
              index > 0 else { return nil }
        return items[items.index(before: index)].post
    }

    func hasNext(after postId: String?) -> Bool {
        assertMain()
        guard let postId, let index = items.firstIndex(where: { $0.id == postId }) else { return false }
        return index < items.count - 1
    }

    func hasPrevious(before postId: String?) -> Bool {
        assertMain()
        guard let postId, let index = items.firstIndex(where: { $0.id == postId }) else { return false }
        return index > 0
    }

    func orderedQueue(_ activePostId: String, posts: [BHPost]?, order: BHQueueOrder) -> [BHPost]? {
        assertMain()
        guard let unsorted = posts else { return nil }
        guard let activeIndex = unsorted.firstIndex(where: { $0.id == activePostId }) else { return nil }

        switch order {
        case .straight:
            return Array(unsorted[activeIndex...])
        case .reversed:
            return Array(unsorted.prefix(activeIndex)).reversed()
        case .straightAndReversed:
            let reversed = Array(unsorted.prefix(activeIndex)).reversed()
            return reversed.isEmpty ? Array(unsorted[activeIndex...]) : Array(reversed)
        }
    }

    // MARK: - Loading

    func load(completion: (() -> Void)? = nil) {
        assertMain()
        DataBaseManager.shared.fetchQueue { [weak self] items in
            DispatchQueue.main.async {
                self?.items = items
                completion?()
            }
        }
    }

    // MARK: - Mutations

    func add(_ post: BHPost,
             reason: BHQueueReason = .auto,
             moveToTop: Bool = false,
             hasCurrentItem: Bool) {
        assertMain()
        BHLog.p("\(#function) - postId: \(post.id), title: \(post.title)")

        var validReason = reason

        if let currentIndex = items.firstIndex(where: { $0.id == post.id }) {
            validReason = items[currentIndex].reason == .manually ? .manually : reason

            var copy = items
            for index in 0...currentIndex {
                let existing = items[index]
                if existing.reason == .auto || existing.post.id == post.id {
                    removeStorageItem(existing.post.id)
                    if let idx = copy.firstIndex(where: { $0.id == existing.id }) {
                        copy.remove(at: idx)
                    }
                }
            }
            items = copy
        }

        let item = BHQueueItem(id: post.id, post: post, reason: validReason)

        if !hasCurrentItem || moveToTop {
            items.insert(item, at: 0)
        } else if !items.isEmpty {
            items.insert(item, at: 1)
        } else {
            items.insert(item, at: 0)
        }
        insertStorageItem(item)

        delegate?.playbackQueueDidChange(self)
    }

    func append(_ posts: [BHPost]) {
        assertMain()
        BHLog.p("\(#function)")

        var changed = false
        for post in posts where !items.contains(where: { $0.id == post.id }) {
            let item = BHQueueItem(id: post.id, post: post, reason: .auto)
            items.append(item)
            insertStorageItem(item)
            changed = true
        }

        if changed { delegate?.playbackQueueDidChange(self) }
    }

    func remove(_ postId: String) {
        assertMain()
        BHLog.p("\(#function) - postId: \(postId)")

        guard let index = items.firstIndex(where: { $0.id == postId }) else { return }
        items.remove(at: index)
        removeStorageItem(postId)
        delegate?.playbackQueueDidChange(self)
    }

    func insert(_ item: BHQueueItem, at index: Int) {
        assertMain()
        BHLog.p("\(#function) - postId: \(item.post.id), index: \(index)")

        let safeIndex = min(max(index, 0), items.count)
        items.insert(item, at: safeIndex)
        insertStorageItem(item)
        delegate?.playbackQueueDidChange(self)
    }

    @discardableResult
    func remove(at index: Int) -> BHQueueItem? {
        assertMain()
        guard items.indices.contains(index) else {
            BHLog.w("\(#function) - index \(index) out of range (count \(items.count))")
            return nil
        }
        let removed = items.remove(at: index)
        removeStorageItem(removed.id)
        delegate?.playbackQueueDidChange(self)
        return removed
    }

    func clear(includingManual: Bool = false) {
        assertMain()
        BHLog.p("\(#function)")

        removeStorageItems(includingManual: includingManual)

        if includingManual {
            items.removeAll()
        } else {
            items.removeAll(where: { $0.reason == .auto })
        }
    }

    func updatePlayback(_ postId: String, offset: Double, completed: Bool) {
        assertMain()
        guard let item = items.first(where: { $0.id == postId }) else { return }
        item.post.updatePlaybackOffset(offset, completed: completed)
        updateStorageItem(item)
    }

    // MARK: - Storage Providers

    private func insertStorageItem(_ item: BHQueueItem) {
        if !DataBaseManager.shared.insertOrUpdateQueueItem(with: item) {
            BHLog.w("\(#function) - failed to insert queue item")
        }
    }

    private func updateStorageItem(_ item: BHQueueItem) {
        if !DataBaseManager.shared.updateQueueItem(with: item) {
            BHLog.w("\(#function) - failed to update queue item")
        }
    }

    private func removeStorageItem(_ id: String) {
        if !DataBaseManager.shared.removeQueueItem(with: id) {
            BHLog.w("\(#function) - failed to remove queue item")
        }
    }

    private func removeStorageItems(includingManual: Bool) {
        for item in items where includingManual || item.reason == .auto {
            removeStorageItem(item.id)
        }
    }
}

