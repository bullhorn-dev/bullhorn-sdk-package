
import Foundation

struct StorageSettings: Equatable {

    enum AuthType: String {
        case basic = "basic"
        case bearer = "bearer"
    }

    let urlString: String
    let authString: String
    let authType: AuthType
    let containerSid: String
}

class BHAccount: NSObject, NSCoding, NSCopying {

    private struct CoderKeys {
        static let authToken    = "authToken"
        static let serviceToken = "serviceToken"
        static let userObject   = "userObject"
    }
    
    struct Difference: OptionSet {

        let rawValue: Int

        static let authToken = Difference(rawValue: 1 << 0)
        static let serviceToken = Difference(rawValue: 1 << 1)
        static let userData = Difference(rawValue: 1 << 2)
        static let storageSettings = Difference(rawValue: 1 << 3)
        static let all = Difference(rawValue: authToken.rawValue + serviceToken.rawValue + userData.rawValue + storageSettings.rawValue)
    }

    var user: BHSelfUser
    var authToken: String
    var serviceToken: String?
    var storageSettings: StorageSettings?

    var isValid: Bool { return !authToken.isEmpty }

    init(user: BHSelfUser, authToken: String) {

        self.user = user
        self.authToken = authToken

        super.init()
    }

    // MARK: - NSCoding

    required init?(coder aDecoder: NSCoder) {

        guard let user = aDecoder.decodeObject(forKey: CoderKeys.userObject) as? BHSelfUser else { return nil }
        self.user = user

        guard let authToken = aDecoder.decodeObject(forKey: CoderKeys.authToken) as? String else { return nil }
        self.authToken = authToken
    }

    func encode(with aCoder: NSCoder) {

        aCoder.encode(authToken, forKey: CoderKeys.authToken)
        aCoder.encode(user, forKey: CoderKeys.userObject)
    }

    // MARK: - NSCopying

    func copy(with zone: NSZone? = nil) -> Any {

        // Shallow copy, because 'user' is not copied deeply
        let accountCopy = BHAccount.init(user: user, authToken: authToken)
        accountCopy.serviceToken = serviceToken
        accountCopy.storageSettings = storageSettings

        return accountCopy
    }

    // MARK: - Public

    func merged(with another: BHAccount) -> BHAccount {

        let mergedCopy = self.copy() as! BHAccount

        mergedCopy.user = another.user

        if !another.authToken.isEmpty {
            mergedCopy.authToken = another.authToken
        }

        if let validServiceToken = another.serviceToken {
            mergedCopy.serviceToken = validServiceToken
        }

        if let validStorageSettings = storageSettings {
            mergedCopy.storageSettings = validStorageSettings
        }

        return mergedCopy
    }

    func getDifference(with another: BHAccount) -> Difference {

        var difference = Difference()

        if user !== another.user {
            difference.insert(.userData)
        }

        if authToken != another.authToken {
            difference.insert(.authToken)
        }

        if serviceToken != another.serviceToken {
            difference.insert(.serviceToken)
        }

        if storageSettings != another.storageSettings {
            difference.insert(.storageSettings)
        }

        return difference
    }
    
    // MARK: - Parse
    
    static func parse(from user: BHSelfUser) -> BHAccount {
        
        let authToken = user.authToken ?? ""

        let account = BHAccount.init(user: user, authToken: authToken)
        
        account.serviceToken = user.accessToken

        return account
    }
}
