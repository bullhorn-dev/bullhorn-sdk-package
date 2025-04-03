
import Foundation
import FoxKitProfile

class ProfileInformation: NSObject, NSSecureCoding {
    
    static var supportsSecureCoding: Bool = true
    
    var accessToken: String?
    var refreshToken: String?
    let profileId: String
    let displayName: String?
    let userType: String?
    let email: String?
    let gender: String?

    init(loginResponse: ProfileUserResponse) {
        accessToken = loginResponse.accessToken
        refreshToken = loginResponse.refreshToken
        profileId = loginResponse.profileId ?? "unknown"
        displayName = loginResponse.displayName
        email = loginResponse.email
        gender = loginResponse.gender
        userType = loginResponse.userType
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(accessToken, forKey: "accessToken")
        coder.encode(refreshToken, forKey: "refreshToken")
        coder.encode(profileId, forKey: "profileId")
        coder.encode(displayName, forKey: "displayName")
        coder.encode(userType, forKey: "userType")
        coder.encode(email, forKey: "email")
        coder.encode(gender, forKey: "gender")
    }
    
    required init?(coder: NSCoder) {
        accessToken = coder.decodeObject(forKey: "accessToken") as? String
        refreshToken = coder.decodeObject(forKey: "refreshToken") as? String
        profileId = coder.decodeObject(forKey: "profileId") as! String
        displayName = coder.decodeObject(forKey: "displayName") as? String
        userType = coder.decodeObject(forKey: "userType") as? String
        email = coder.decodeObject(forKey: "email") as? String
        gender = coder.decodeObject(forKey: "gender") as? String
    }
    
    public var initials: String {
        var finalString = String()
        guard var words = displayName?.components(separatedBy: .whitespacesAndNewlines) else { return "A" }
        
        if let firstCharacter = words.first?.first {
          finalString.append(String(firstCharacter))
          words.removeFirst()
        }
        
        if let lastCharacter = words.last?.first {
          finalString.append(String(lastCharacter))
        }
        
        return finalString.uppercased()
    }
}
