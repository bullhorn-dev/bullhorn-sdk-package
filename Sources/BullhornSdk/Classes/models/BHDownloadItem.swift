
import Foundation

enum DownloadType: Int, Codable {
    case atOnce = 0
    case queue
}

enum DownloadReason: Int, Codable {
    case manually = 0
    case auto
}

enum DownloadStatus: Int, Codable {
    case pending = 0
    case start
    case progress
    case success
    case failure
    
    func isStarted() -> Bool { self == .start }
    func isProgress() -> Bool { self == .progress }
    func isSuccess() -> Bool { self == .success }
    func isFailed() -> Bool { self == .failure }
    func isPending() -> Bool { self == .pending }
    func isFetching() -> Bool { isStarted() || isProgress() }
    func isFetched() -> Bool { isSuccess() || isFailed() }
}

class BHDownloadItem: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case post
        case status
        case prevStatus = "prev_status"
        case reason
        case progress
        case url
        case file
        case time
    }
    
    let id: String
    var post: BHPost
    var status: DownloadStatus
    var prevStatus: DownloadStatus
    let reason: DownloadReason
    var progress: Double = 0.0
    let url: URL
    var file: URL?
    let time: Double
    
    init(id: String, post: BHPost, status: DownloadStatus, prevStatus: DownloadStatus, reason: DownloadReason, progress: Double, url: URL, file: URL? = nil, time: Double) {
        
        self.id = id
        self.post = post
        self.status = status
        self.prevStatus = prevStatus
        self.reason = reason
        self.progress = progress
        self.url = url
        self.file = file
        self.time = time
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: time)
    }
}
