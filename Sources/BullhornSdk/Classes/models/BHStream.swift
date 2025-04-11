
import Foundation

// MARK: - Radio

struct BHRadio: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case playbackUrl = "playback_url"
        case phoneNumber = "phone_number"
        case streams
    }

    let id: String
    let title: String
    let playbackUrl: URL?
    let phoneNumber: String?
    let streams: [BHStream]
    
    var laterStreams: [BHStream] {
        if streams.count > 1 {
            return Array(streams.dropFirst())
        }
        return []
    }
    
    func asPost() -> BHPost? {
        guard let stream = streams.first else { return nil }

        let user = BHUser(id: stream.id, fullName: title, profilePicture: stream.coverUrl)
        let recording = BHRecording(id: id, duration: 100000, publishUrl: playbackUrl)
        let post = BHPost(id: stream.id, title: stream.title, description: nil, postType: .radioStream, alias: nil, startTime: nil, endTime: nil, scheduledAt: nil, hasMeetingRoom: false, originalTime: nil, playbackOffset: 0, isPlaybackCompleted: false, privacy: .public, published: true, publishedAt: "", liked: false, shareLink: playbackUrl!, user: user, recording: recording, bulletin: nil, status: .onAir)

        return post
    }
}

// MARK: - Stream

struct BHStream: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startAt = "start_at"
        case endAt = "end_at"
        case coverUrl = "cover_url"
        case phoneNumber = "phone_number"
    }

    let id: String
    let title: String
    let startAt: Int
    let endAt: Int
    let coverUrl: URL?
    let phoneNumber: String?
    
    // MARK: - Public
    
    func localStartTime() -> String {
        let estSecondsFromGMT = TimeZone(abbreviation: "EST")!.secondsFromGMT()
        let estTimeFromGMT = estSecondsFromGMT * 100 / 3600
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        let timeFromGMT = secondsFromGMT * 100 / 3600
        let currentTime = abs((startAt + timeFromGMT - estTimeFromGMT) % 2400)
        var str: String = ""
            
        if (currentTime > 1259) {
            str = "\(currentTime-1200)pm"
        } else {
            let time = currentTime < 100 ? "12\(currentTime)" : "\(currentTime)"
            let suffix = currentTime >= 1200 ? "pm" : "am"
            str = time + suffix
        }
        str = str.count == 5 ? str.substring(with: 0..<1) + ":" + str.substring(with: 1..<5) : str.substring(with: 0..<2) + ":" + str.substring(with: 2..<6)
        return str.replacingOccurrences(of: ":00", with: "")
    }
    
    func isTimeToUpdate() -> Bool {
        let estTimeZone = TimeZone(abbreviation: "EST")
        var calendar = Calendar.current
        calendar.timeZone = estTimeZone!

        let date = Date()
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let estTime = hour * 100 + minute
        
        return endAt < estTime
    }
}
