import Foundation
import CoreData

@objc(FollowedUsersMO)
public class FollowedUsersMO: NSManagedObject {
    
    static let entityName = "FollowedUsers"
    
    // MARK: - Public
        
    func toUsers() -> [BHUser] {

        var users: [BHUser] = []

        if let validUsers = followedUsers {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    users.append(user)
                }
            }
        }
        
        return users
    }
}

