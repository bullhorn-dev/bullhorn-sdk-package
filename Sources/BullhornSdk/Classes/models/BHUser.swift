import Foundation

// MARK: - User (podcast)

struct BHUser: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case id
        case bio
        case external
        case level
        case username
        case fullName = "full_name"
        case profilePicture = "profile_picture"
        case profilePictureBig = "profile_picture_big"
        case profilePictureTiny = "profile_picture_tiny"
        case isNetwork = "is_network"
        case hasActiveLive = "has_active_live"
        case shareLink = "share_link"
        case website
        case channels = "network_channels"
        case categories
        case ratingsCount = "ratings_count"
        case ratingValue = "rating_value"
        case outgoingStatus = "outgoing_status"
    }
    
    enum Level: Int, Codable {
        case anonymous = 0
        case normal = 1
    }
    
    enum Status: String, Codable {
        case none = "none"
        case follows = "follows"
        case requested = "requested"
    }

    let id: String
    var bio: String?
    var username: String?
    var fullName: String?
    var profilePicture: URL?
    var profilePictureBig: URL?
    var profilePictureTiny: URL?
    var level: Level = .normal
    var external: Bool = true
    var isNetwork: Bool = false
    var hasActiveLive: Bool = false
    var shareLink: URL?
    var website: URL?
    var channels: [BHChannel]?
    var categories: [BHUserCategory]?
    var ratingsCount: Int?
    var ratingValue: Double?
    var outgoingStatus: String?

    var categoryName: String {
        return categories?.first?.name ?? "News Updates"
    }
    
    func belongsChannel(_ channelId: String) -> Bool {
        return channels?.contains(where: { $0.id == channelId }) ?? false
    }
    
    var isFollowed: Bool {
        guard let status = outgoingStatus else { return false }
        return status == Status.follows.rawValue || status == Status.requested.rawValue
    }
    
    var coverUrl: URL? {
        if profilePicture != nil {
            return profilePicture
        } else if profilePictureTiny != nil {
            return profilePictureTiny
        } else {
            return profilePictureBig
        }
    }

    var coverUrlBig: URL? {
        if profilePictureBig != nil {
            return profilePictureBig
        } else if profilePicture != nil {
            return profilePicture
        } else {
            return profilePictureTiny
        }
    }

    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Self User

public class BHSelfUser: NSObject, Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case accessToken = "access_token"
        case authToken = "auth_token"
        case username
        case profilePicture = "profile_picture"
        case fullName = "full_name"
        case level
        case newUser = "new_user"
        case phoneNumber = "phone_number"
        case sdkUserId = "sdk_user_id"
    }
    
    enum Level: Int, Codable {
        case anonymous = 0
        case normal = 1
    }

    let id: String
    var accessToken: String?
    var authToken: String?
    var username: String?
    public var fullName: String?
    public var profilePicture: URL?
    var level: Level = .normal
    var newUser: Bool = false
    var phoneNumber: String?
    var sdkUserId: String?

    var isAnonymous: Bool { return level == .anonymous }
    
    init(withIdentifier id: String) {
        self.id = id
        super.init()
    }

    // MARK: - NSCoding

    required init?(coder aDecoder: NSCoder) {

        guard let validId = aDecoder.decodeObject(forKey: CodingKeys.id.rawValue) as? String else { return nil }

        id = validId
        username = aDecoder.decodeObject(forKey: CodingKeys.username.rawValue) as? String
        fullName = aDecoder.decodeObject(forKey: CodingKeys.fullName.rawValue) as? String
        accessToken = aDecoder.decodeObject(forKey: CodingKeys.accessToken.rawValue) as? String
        authToken = aDecoder.decodeObject(forKey: CodingKeys.authToken.rawValue) as? String
        profilePicture = aDecoder.decodeObject(forKey: CodingKeys.profilePicture.rawValue) as? URL
        level = Level.init(rawValue: aDecoder.decodeInteger(forKey: CodingKeys.level.rawValue)) ?? .normal
        newUser = aDecoder.decodeBool(forKey: CodingKeys.newUser.rawValue)
        phoneNumber = aDecoder.decodeObject(forKey: CodingKeys.phoneNumber.rawValue) as? String
        sdkUserId = aDecoder.decodeObject(forKey: CodingKeys.sdkUserId.rawValue) as? String
    }

    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id, forKey: CodingKeys.id.rawValue)
        aCoder.encode(username, forKey: CodingKeys.username.rawValue)
        aCoder.encode(fullName, forKey: CodingKeys.fullName.rawValue)
        aCoder.encode(accessToken, forKey: CodingKeys.accessToken.rawValue)
        aCoder.encode(authToken, forKey: CodingKeys.authToken.rawValue)
        aCoder.encode(profilePicture, forKey: CodingKeys.profilePicture.rawValue)
        aCoder.encode(level.rawValue, forKey: CodingKeys.level.rawValue)
        aCoder.encode(newUser, forKey: CodingKeys.newUser.rawValue)
        aCoder.encode(phoneNumber, forKey: CodingKeys.phoneNumber.rawValue)
        aCoder.encode(sdkUserId, forKey: CodingKeys.sdkUserId.rawValue)
    }

    // MARK: NSObjectProtocol

    public override func isEqual(_ object: Any?) -> Bool {
        
        if let anotherUser = object as? BHSelfUser {
            let isEqual = (self.id == anotherUser.id &&
                self.username == anotherUser.username &&
                self.fullName == anotherUser.fullName &&
                self.profilePicture == anotherUser.profilePicture &&
                self.level == anotherUser.level)
            
            return isEqual
        } else {
            return false
        }
    }
}
