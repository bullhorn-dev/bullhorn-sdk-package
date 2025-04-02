import Foundation
import CoreData

@objc(NetworkFeaturedUsersMO)
public class NetworkFeaturedUsersMO: NSManagedObject {
    
    static let entityName = "NetworkFeaturedUsers"
    
    // MARK: - Public
        
    func toUsers() -> [BHUser] {

        var users: [BHUser] = []

        if let validUsers = featuredUsers {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    users.append(user)
                }
            }
        }
        
        return users
    }
}
