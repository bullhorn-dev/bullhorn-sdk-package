
import Foundation

enum BHBulletinLayoutContentType: String {
    case liveVideo = "live-video"
    case composedVideo = "composed-video"
    case interactive = "interactive"
    case callIn = "callin"
    case question = "question"
}

enum BHBulletinLayoutPresenterType: String {
    case external = "external"
    case coHost = "cohost"
    case callIn = "callin"
}

// MARK: - BHBulletinLayout

struct BHBulletinLayout {
    
    var events: [BHBulletinLayoutEvent] = []
    
    func hasLayoutEvent(_ position: Double) -> Bool {
        guard (events.first(where: { $0.checkPosition(position) })) != nil else {
            return false
        }
        return true
    }

    func getLayoutEvent(_ position: Double) -> BHBulletinLayoutEvent? {
        return events.first(where: { $0.checkPosition(position) })
    }
}

// MARK: - BHBulletinLayoutEvent

struct BHBulletinLayoutEvent: JsonApiCodable {
    
    enum CodingKeys: String, CodingKey {

        case id
        case type
        case startAt = "start_at"
        case endAt = "end_at"
        case portrait = "portrait"
        case landscape = "landscape"
//        case callIn = "callIn"
    }
    
    let id: String
    let type: String = "layout"

    let startAt: Double //ms
    let endAt: Double? //ms
    let portrait: BHBulletinLayoutContent
    let landscape: BHBulletinLayoutContent
//    let callIn: [BHBulletinLayoutCallInContent]

    init(id: String,
         startAt: Double = 0,
         endAt: Double,
         portrait: BHBulletinLayoutContent,
         landscape: BHBulletinLayoutContent /*,
         callIn: [BHBulletinLayoutCallInContent]*/) {

        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.portrait = portrait
        self.landscape = landscape
//        self.callIn = callIn
    }
    
    func checkPosition(_ position: Double) -> Bool {
        if let endTime = endAt {
            return (position >= startAt) && (position < endTime)
        } else {
            return position >= startAt
        }
    }

    func isEnded() -> Bool { endAt != nil }
    
    func getEmptySpaces(_ isPortrait: Bool = true) -> BHEmptySpaces {
        if isPortrait {
            return portrait.content.first?.emptySpaces ?? BHEmptySpaces.initial()
        } else {
            return landscape.content.first?.emptySpaces ?? BHEmptySpaces.initial()
        }
    }
}

// MARK: - BHBulletinLayoutContent

struct BHBulletinLayoutContent: Codable {

    enum CodingKeys: String, CodingKey {

        case bgColor = "bgcolor"
        case content
    }

    let bgColor: String?
    let content: [BHBulletinLayoutComposedVideoContent]
}

// MARK: - BHEmptySpaces

struct BHEmptySpaces: Codable {
    
    enum CodingKeys: String, CodingKey {

        case left
        case right
    }
    
    let left: CGFloat
    let right: CGFloat
    
    static func initial() -> BHEmptySpaces {
        return BHEmptySpaces(left: 0, right: 0)
    }
}

// MARK: - BHBulletinLayoutComposedVideoContent

struct BHBulletinLayoutComposedVideoContent: Codable {
    
    enum CodingKeys: String, CodingKey {

        case type
        case x0 = "x0"
        case y0 = "y0"
        case x1 = "x1"
        case y1 = "y1"
        case z = "z"
        case emptySpaces = "empty_spaces"
    }
    
    let type: String = BHBulletinLayoutContentType.composedVideo.rawValue
    let x0: CGFloat
    let y0: CGFloat
    let x1: CGFloat
    let y1: CGFloat
    let z: CGFloat?
    let emptySpaces: BHEmptySpaces?
}

// MARK: - BHBulletinLayoutCallInContent

struct BHBulletinLayoutCallInContent: Codable {

    enum CodingKeys: String, CodingKey {

        case type
        case callId = "callId"
        case placeholder = "placeholder"
        case presenterType = "presenterType"
        case profilePicture = "profilePicture"
        case x0 = "x0"
        case y0 = "y0"
        case x1 = "x1"
        case y1 = "y1"
        case z = "z"
    }
    
    let type: String = BHBulletinLayoutContentType.callIn.rawValue

    let callId: String
    let placeholder: String
    let presenterType: String
    let profilePicture: String?
    let x0: CGFloat
    let y0: CGFloat
    let x1: CGFloat
    let y1: CGFloat
    let z: CGFloat?
}
