
import Foundation

/// CarPlay-facing helpers for reading the playback queue and jumping within it.
/// Purely additive — keeps the "Up Next" wiring out of the core player file.
extension BHHybridPlayer {

    /// Posts queued after the currently playing one — the CarPlay "Up Next" list.
    ///
    /// The queue holds the full ordered list including the current post (this is the
    /// same model `playNext()` relies on via `queue.next(after:)`), so "up next" is
    /// everything after the current post's index. If there is no current post, or it
    /// isn't found in the queue, the whole queue is treated as upcoming.
    func upNextPosts() -> [BHPost] {
        let allPosts = queue.items.map { $0.post }

        guard let currentId = post?.id,
              let index = allPosts.firstIndex(where: { $0.id == currentId }) else {
            return allPosts
        }

        let nextIndex = allPosts.index(after: index)
        guard nextIndex < allPosts.count else { return [] }
        return Array(allPosts[nextIndex...])
    }

    /// Jump playback to a post that is already in the queue, preserving the rest of
    /// the queue. Mirrors what `playNext()` does for the immediate next item
    /// (`clearQueue: false` keeps the remaining queue intact).
    func playQueuedPost(_ post: BHPost) {
        playRequest(with: post,
                    playlist: [],
                    autoplayContext: playerItem?.autoplayContext,
                    clearQueue: false)
    }
}
