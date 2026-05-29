import Foundation

/// Internal state machine for BHMediaPlayerBase and its subclasses.
///
/// The key invariant: every transition is explicit and handles both orderings
/// of "engine ready" vs "play command received".
enum BHPlaybackState {

    // MARK: - Cases

    /// No media assigned.
    case idle

    /// AVPlayer is loading the item.
    /// `intent` records what to do the moment the engine becomes ready.
    case loading(intent: LoadIntent)

    /// AVPlayer finished loading but no play/restore command has arrived yet.
    /// This handles the race where the item becomes ready BEFORE play(at:) is called.
    case ready

    /// A seek is in flight.
    /// `resume` tells us whether to play or stay paused after the seek completes.
    case seeking(to: TimeInterval, resume: Bool)

    /// Engine is actively playing.
    case playing

    /// Paused — either by user command or restored from a previous session.
    case paused

    /// Played to the end.
    case ended

    /// Unrecoverable error.
    case failed(Error?)

    // MARK: - Load Intent

    enum LoadIntent {

        /// Normal launch: seek to `position`, then start playing automatically.
        case play(from: TimeInterval)

        /// Session restore: seek to `position`, then stay paused.
        case restore(at: TimeInterval)

        var startPosition: TimeInterval {
            switch self {
            case .play(let t), .restore(let t): return t
            }
        }

        var shouldAutoPlay: Bool {
            if case .play = self { return true }
            return false
        }
    }

    // MARK: - Helpers

    /// True once AVPlayer has loaded and we can issue seeks or play/pause immediately.
    var isEngineReady: Bool {
        switch self {
        case .ready, .playing, .paused, .seeking: return true
        default: return false
        }
    }

    /// The position currentTime() should report while the engine is loading
    /// or mid-seek, so the UI doesn't jump back to 0.
    var pendingPosition: TimeInterval? {
        switch self {
        case .loading(let intent):  return intent.startPosition
        case .seeking(let to, _):   return to
        default:                    return nil
        }
    }

    // MARK: - External state mapping

    var asExternalState: BHMediaPlayerBase.State {
        switch self {
        case .idle:                          return .idle
        case .loading:                       return .waiting
        case .ready:                         return .ready
        case .seeking(_, let resume):        return resume ? .playing : .paused
        case .playing:                       return .playing
        case .paused:                        return .paused
        case .ended:                         return .ended
        case .failed(let e):                 return .failed(e: e)
        }
    }
}
