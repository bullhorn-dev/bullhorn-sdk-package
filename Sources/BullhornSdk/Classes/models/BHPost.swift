import Foundation

// MARK: - Recording

struct BHRecording: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case duration = "duration"
        case publishUrl = "publish_uri"
    }
    
    let id: String
    let duration: Int
    let publishUrl: URL?
}

// MARK: - Bulletin

struct BHPostBulletin: Codable {
        
    enum CodingKeys: String, CodingKey {
        case id
        case updatedAt = "updated_at"
        case hasVideo = "has_video"
        case hasTiles = "has_tiles"
    }

    let id: String
    let updatedAt: String
    let hasVideo: Bool
    let hasTiles: Bool
}

// MARK: - Post

struct BHPost: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case title = "title"
        case description = "description"
        case postType = "post_type"
        case alias
        case startTime = "start_time"
        case endTime = "end_time"
        case scheduledAt = "scheduled_at"
        case hasMeetingRoom = "has_meeting_room"
        case originalTime = "original_time"
        case isPlaybackCompleted = "playback_completed"
//        case playbackTimestamp = "playback_timestamp"
        case playbackOffset = "playback_offset"
        case privacy
        case published
        case publishedAt = "published_at"
        case liked
        case shareLink = "share_link"
        case user
        case recording
        case bulletin
        case status
    }
    
    enum PostType: String, Codable {
        case preRecorded = "pre_recorded_event"
        case liveEpisode = "live_episode"
        case radioStream = "radio_stream"
    }
    
    enum PostPrivacy: String, Codable {
        case `public` = "public"
        case `private` = "private"
    }
    
    enum PostLiveType: Int {
        case scheduled = 0
        case live
        case liveNow
    }

    enum PostStatus: String, Codable {
        case finished = "finished"
        case onAir = "on_air"
    }

    enum PostLiveStatus: Int {
        case scheduled = 0
        case preShow
        case live
        case liveEnding
        case ended
        
        func isLive() -> Bool { self == .live }
        func isLiveEnding() -> Bool { self == .liveEnding }
        func isEnded() -> Bool { self == .ended }
        func isScheduled() -> Bool { self == .scheduled || self == .preShow }
        func inMeeting() -> Bool { self == .preShow || self == .live }
        func isActive() -> Bool { self == .live || self == .liveEnding || self == .ended }
    }

    let id: String
    let title: String
    let description: String?
    let postType: PostType
    let alias: String?
    let startTime: String?
    let endTime: String?
    let scheduledAt: String?
    let hasMeetingRoom: Bool
    let originalTime: String?
//    let playbackTimestamp: Double
    var playbackOffset: Double
    var isPlaybackCompleted: Bool
    let privacy: PostPrivacy
    let published: Bool
    let publishedAt: String?
    var liked: Bool
    let shareLink: URL
    let user: BHUser
    let recording: BHRecording?
    let bulletin: BHPostBulletin?
    let status: PostStatus
    
    var isDownloaded: Bool {
        return BHDownloadsManager.shared.isPostDownloaded(id)
    }
    
    var downloadStatus: DownloadStatus {
        return BHDownloadsManager.shared.item(for: id)?.status ?? .start
    }
    
    var downloadReason: DownloadReason {
        return BHDownloadsManager.shared.item(for: id)?.reason ?? .manually
    }
    
    var originalTimeDate: Date? {
        return originalTime != nil ? dateStringFormatter.date(from: originalTime!) : nil
    }
    var publishedAtDate: Date? {
        return publishedAt != nil ? dateStringFormatter.date(from: publishedAt!) : nil
    }
    var scheduledAtDate: Date? {
        return scheduledAt != nil ? dateStringFormatter.date(from: scheduledAt!) : nil
    }
    var startTimeDate: Date? {
        return startTime != nil ? dateStringFormatter.date(from: startTime!) : nil
    }
    var endTimeDate: Date? {
        return endTime != nil ? dateStringFormatter.date(from: endTime!) : nil
    }

    func hasRecording() -> Bool { recording != nil }

    func isPreRecorded() -> Bool { postType == .preRecorded }
    func isLive() -> Bool { postType == .liveEpisode }
    func isLiveNow() -> Bool { isLive() /*&& endTime == nil*/  && !hasRecording() }
    func isLiveStream() -> Bool { hasRecording() && status == .onAir}
    func isRadioStream() -> Bool { postType == .radioStream }

    func liveScheduledInPast() -> Bool {
        guard let scheduledDate = scheduledAtDate else { return true }
        return scheduledDate.timeIntervalSinceNow < 0
    }
    
    var liveStatus: PostLiveStatus {
        var status: PostLiveStatus

        if (endTime != nil) {
            status = .ended
        } else if (startTime != nil) {
            status = .live
        } else if (hasMeetingRoom) {
            status = .preShow
        } else {
            status = .scheduled
        }
        
        return status
    }

    func isInteractive() -> Bool {
        return bulletin != nil
    }
    
    func hasTiles() -> Bool {
        return bulletin != nil ? bulletin!.hasTiles : false
    }

    func hasVideo() -> Bool {
        return bulletin != nil ? bulletin!.hasVideo : false
    }
    
    mutating func updatePlaybackOffset(_ offset: Double, completed: Bool) {
        playbackOffset = offset
        isPlaybackCompleted = isPlaybackCompleted ? true : completed
    }
    
    var postDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()
    
    var dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        return formatter
    }()
}

// MARK: - Equatable

extension BHPost: Equatable {

    static func == (lhs: BHPost, rhs: BHPost) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension BHPost: Hashable {

    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Playback Offset

struct BHPlaybackOffset: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case offset
        case postId = "post_id"
        case playbackCompleted = "playback_completed"
    }

    let id: Int
    let offset: Double
    let postId: String
    let playbackCompleted: Bool
}

// MARK: - Post Offset

struct BHOffset: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case offset
        case timestamp
        case completed
    }

    let id: String
    let offset: Double
    let timestamp: Double
    let completed: Bool
}


