import Foundation
import CoreData

@objc(RelatedUsersMO)
public class RelatedUsersMO: NSManagedObject {
    
    static let entityName = "RelatedUsers"
    
    // MARK: - Public
        
    func toUsers() -> [BHUser] {

        var users: [BHUser] = []

        if let validUsers = relatedUsers {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    users.append(user)
                }
            }
        }
        
        return users
    }
}
