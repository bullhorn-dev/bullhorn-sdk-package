
import Foundation

class BHPlaybacksManager {

    enum CommonResult {
        case success
        case failure(e: Error, handled: Bool)
    }

    static var shared: BHPlaybacksManager = BHPlaybacksManager()

    fileprivate static let fileName = "playbacks.json"
    fileprivate let fileURL = FileManager.default.urlForFileInCaches(with: BHPlaybacksManager.fileName)
    
    fileprivate var playbacksQueue: Set<BHPostPlayback> = Set()
    
    // MARK: Public
    
    func add(playback: BHPostPlayback, shouldSend: Bool = false) {
        
        if let existingPlayback = playbacksQueue.first(where: { $0.episodeId == playback.episodeId }) {
            playbacksQueue.remove(existingPlayback)
            existingPlayback.finishedAt += playback.finishedAt - playback.startedAt
            playbacksQueue.insert(existingPlayback)
        }
        else {
            playbacksQueue.insert(playback)
        }
        
        if shouldSend {
            send()
        }
    }
    
    func send() {
        
        if playbacksQueue.count == 0 {
            return
        }

        let playbacksToSend = playbacksQueue

        DispatchQueue.main.async {
            for playback in playbacksToSend {
                /// track stats
                let duration: Int = Int((playback.finishedAt - playback.startedAt) * 1000)
                let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .playerPlayback, context: String(duration), podcastId: playback.podcastId, podcastTitle: playback.podcastTitle, episodeId: playback.episodeId, episodeTitle: playback.episodeTitle, episodeType: playback.episodeType, extraParams: ["playback_ms" : duration])
                BHTracker.shared.trackEvent(with: request)

                self.playbacksQueue = self.playbacksQueue.filter { $0.uuid != playback.uuid }
            }
        }
    }
    
    func savePlaybacks() {
        BHLog.p("\(#function)")

        guard let validFileURL = fileURL else {
            BHLog.w("\(#function) - failed to get \(BHPlaybacksManager.fileName) path.")
            return
        }
        
        let playbacksJsonArray = self.playbacksQueue.map({ $0.toJson() })
            
        FileManager.default.writeJsonArray(array: playbacksJsonArray, forKey: "playbacks", toFile: validFileURL)
    }

    func restorePlaybacks() {
        BHLog.p("\(#function)")

        guard let validFileURL = fileURL else {
            BHLog.w("\(#function) - failed to get \(BHPlaybacksManager.fileName) path.")
            return
        }
        
        FileManager.default.readJsonArray(fromFile: validFileURL, forKey: "playbacks") { jsonArray in
            
            for item in jsonArray {
                if let playback = BHPostPlayback.fromJson(item) {
                    self.playbacksQueue.insert(playback)
                }
            }
            self.send()
        }
    }
}

