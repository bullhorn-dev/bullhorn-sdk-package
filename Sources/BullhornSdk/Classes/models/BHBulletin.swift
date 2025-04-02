
import Foundation

struct BHBulletin: JsonApiCodable {
        
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case preShowChatTimer = "pre_show_chat_timer"
        case preShowQuestionsTimer = "pre_show_questions_timer"
        case preShowCallInTimer = "pre_show_call_in_timer"
        case publishedAt = "published_at" //str
        case chatEnabled = "chat_enabled"
        case questionsEnabled = "questions_enabled"
        case callInEnabled = "call_in_enabled"
        case hasTiles = "has_tiles" //true
        case hasVideo = "has_video"
        case userIsBanned = "user_is_banned"
        case bulletinEvents = "bulletin_events"
        case preShowEvents  = "pre_show_events"
    }
    
    let id: String
    let type: String = "bulletin"
    
    let preShowChatTimer: String?
    let preShowQuestionsTimer: String?
    let preShowCallInTimer: String?
    let publishedAt: String?
    let chatEnabled: Bool
    let questionsEnabled: Bool
    let callInEnabled: Bool
    let hasTiles: Bool
    let hasVideo: Bool
    let userIsBanned: Bool

    var bulletinEvents: [BHBulletinEvent]?
    var preShowEvents: [BHBulletinPreShowEvent]?
    
    init(id: String,
         preShowChatTimer: String? = nil,
         preShowQuestionsTimer: String? = nil,
         preShowCallInTimer: String? = nil,
         publishedAt: String? = nil,
         chatEnabled: Bool = false,
         questionsEnabled: Bool = false,
         callInEnabled: Bool = false,
         hasTiles: Bool = false,
         hasVideo: Bool = true,
         userIsBanned: Bool = false,
         bulletinEvents: [BHBulletinEvent]? = nil,
         preShowEvents: [BHBulletinPreShowEvent]? = nil) {

        self.id = id
        self.preShowChatTimer = preShowChatTimer
        self.preShowQuestionsTimer = preShowQuestionsTimer
        self.preShowCallInTimer = preShowCallInTimer
        self.publishedAt = publishedAt
        self.chatEnabled = chatEnabled
        self.questionsEnabled = questionsEnabled
        self.callInEnabled = callInEnabled
        self.hasTiles = hasTiles
        self.hasVideo = hasVideo
        self.userIsBanned = userIsBanned
        self.bulletinEvents = bulletinEvents
        self.preShowEvents = preShowEvents
    }
    
    func hasTimelineEvent(_ position: Double) -> Bool {
        guard (bulletinEvents?.first(where: { $0.checkTilePosition(position) })) != nil else {
            return false
        }
        return true
    }

    func getTimelineEvent(_ position: Double) -> BHBulletinEvent? {
        return bulletinEvents?.first(where: { $0.checkTilePosition(position) })
    }

    mutating func updateTile(_ tile: BHBulletinTile) {
        if let index = preShowEvents?.firstIndex(where: {$0.bulletinTile.id == tile.id}) {
            preShowEvents?[index].bulletinTile = tile
        }
        if let index = bulletinEvents?.firstIndex(where: {$0.bulletinTile.id == tile.id}) {
            bulletinEvents?[index].bulletinTile = tile
        }
    }

    mutating func updatePollVariant(_ variant: BHBulletinPollVariant) {
        if let index = preShowEvents?.firstIndex(where: {$0.bulletinTile.hasPollVariant(variant.id)}) {
            preShowEvents?[index].bulletinTile.updatePollVariant(variant)
        }
        if let index = bulletinEvents?.firstIndex(where: {$0.bulletinTile.hasPollVariant(variant.id)}) {
            bulletinEvents?[index].bulletinTile.updatePollVariant(variant)
        }
    }
}
