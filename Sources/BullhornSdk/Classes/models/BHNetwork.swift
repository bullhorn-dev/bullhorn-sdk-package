import Foundation

struct BHNetwork: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case description
        case name
        case path
        case podcastsCount = "podcasts_count"
        case profilePicture = "profile_picture"
        case profilePictureBig = "profile_picture_big"
        case profilePictureTiny = "profile_picture_tiny"
        case shareLink = "share_link"
    }

    let id: String
    let createdAt: String
    let description: String
    let name: String
    let path: String
    let podcastsCount: Int
    var profilePicture: URL?
    var profilePictureBig: URL?
    var profilePictureTiny: URL?
    var shareLink: URL?
    
    var createdAtDate: Date? {
        return dateStringFormatter.date(from: createdAt)
    }
    
    var dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        return formatter
    }()
}
