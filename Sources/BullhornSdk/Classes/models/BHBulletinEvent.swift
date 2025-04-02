
import Foundation

// MARK: - BHBulletinEvent

struct BHBulletinEvent: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case startAt = "start_at"
        case endAt = "end_at"
        case bulletinTile = "bulletin_tile"
    }
    
    let id: String
    let type: String = "bulletin_event"
    
    let startAt: Double //ms
    let endAt: Double //ms
    var bulletinTile: BHBulletinTile
    
    init(id: String,
         startAt: Double = 0,
         endAt: Double = 0,
         bulletinTile: BHBulletinTile) {
        
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.bulletinTile = bulletinTile
    }
    
    var tileCategory: BHBulletinTile.Category {
        return bulletinTile.tileCategory
    }
    
    func hasLink() -> Bool { bulletinTile.url != nil }
    
    func position() -> Double {
        //        ? CommonUtils.convertPosMsToS(this.startAt(state))
        //        : this.startAt(state)
        return 0
    }
    
    func checkPosition(_ position: Double) -> Bool { (position >= startAt) && (position < endAt) }
    func isBanner() -> Bool { tileCategory == .banner }
    
    func checkTilePosition(_ position: Double) -> Bool { checkPosition(position) && !isBanner() }
    func checkBannerPosition(_ position: Double) -> Bool { checkPosition(position) && isBanner() }
}

// MARK: - BHBulletinPreShowEvent

struct BHBulletinPreShowEvent: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case duration
        case bulletinTile = "bulletin_tile"
        case index = "placement_index"
    }

    var id: String
    var type: String = "pre_show_event"

    let duration: Double
    let index: Int
    var bulletinTile: BHBulletinTile

    init(id: String, duration: Double, bulletinTile: BHBulletinTile, index: Int) {

        self.id = id
        self.bulletinTile = bulletinTile
        self.duration = duration
        self.index = index
    }

    var tileCategory: BHBulletinTile.Category { return bulletinTile.tileCategory }

    func hasLink() -> Bool { bulletinTile.url != nil }
}

// MARK: - BHBulletinVideoEvent

struct BHBulletinVideoEvent: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case startAt = "start_at"
        case endAt = "end_at"
    }
    
    let id: String
    let type: String = "video_event"

    let startAt: Double //ms
    let endAt: Double //ms

    init(id: String,
         startAt: Double = 0,
         endAt: Double = 0) {

        self.id = id
        self.startAt = startAt
        self.endAt = endAt
    }
}

// MARK: - BHBulletinMessage

struct BHBulletinMessage: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case text
        case createdAt = "created_at"
        case startAt = "start_at"
        case startAtMs = "start_at_ms"
//        case reactions = "reactions_summary"
        case index = "placement_index"
        case user
    }
    
    let id: String
    let type: String = "message"

    let text: String
    let createdAt: String
    let startAt: Double //ms
    let startAtMs: Double //ms
//    let reactions: [String]?
    let index: Int?
    let user: BHBulletinUser?

    init(id: String,
         text: String,
         createdAt: String,
         startAt: Double = 0,
         startAtMs: Double = 0,
//         reactions: [String]?,
         index: Int?,
         user: BHBulletinUser?) {

        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.startAt = startAt
        self.startAtMs = startAtMs
//        self.reactions = reactions
        self.index = index
        self.user = user
    }
    
    var createdDate: Date {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: createdAt) ?? Date()
        return date
    }
}

// MARK: - BHBulletinQuestion

struct BHBulletinQuestion: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case text
        case startAt = "start_at"
        case startAtMs = "start_at_ms"
        case likes
        case liked = "is_user_liked"
        case user
//        case questionsEvents = "questions_events"
    }
    
    let id: String
    let type: String = "question"

    let text: String
    let startAt: Double //ms
    let startAtMs: Double //ms
    let likes: Int
    let liked: Bool?
    let user: BHBulletinUser?
//    let questionsEvents: [BHQuestionsEvent]?

    init(id: String,
         text: String,
         startAt: Double = 0,
         startAtMs: Double = 0,
         likes: Int,
         liked: Bool?,
         user: BHBulletinUser?) {

        self.id = id
        self.text = text
        self.startAt = startAt
        self.startAtMs = startAtMs
        self.likes = likes
        self.liked = liked
        self.user = user
    }
}

// MARK: - BHBulletinUser

struct BHBulletinUser: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case username
        case fullName = "full_name"
        case profilePictureBig = "profile_picture_big"
        case profilePicture = "profile_picture"
        case profilePictureTiny = "profile_picture_tiny"
    }
    
    let id: String
    let type: String = "user"

    let username: String
    let fullName: String
    let profilePictureBig: URL?
    let profilePicture: URL?
    let profilePictureTiny: URL?

    init(id: String,
         username: String,
         fullName: String,
         profilePicture: URL?,
         profilePictureBig: URL?,
         profilePictureTiny: URL?) {

        self.id = id
        self.username = username
        self.fullName = fullName
        self.profilePicture = profilePicture
        self.profilePictureBig = profilePictureBig
        self.profilePictureTiny = profilePictureTiny
    }
}

// MARK: - BHQuestionsEvent

struct BHQuestionsEvent: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case startAt = "start_at"
        case endAt = "end_at"
    }
    
    let id: String
    let type: String = "questions_event"

    let startAt: Double
    let endAt: Double

    init(id: String,
         startAt: Double,
         endAt: Double) {

        self.id = id
        self.startAt = startAt
        self.endAt = endAt
    }
}
