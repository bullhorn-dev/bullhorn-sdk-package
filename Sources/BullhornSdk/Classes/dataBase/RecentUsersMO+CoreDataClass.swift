import Foundation
import CoreData

@objc(RecentUsersMO)
public class RecentUsersMO: NSManagedObject {
    
    static let entityName = "RecentUsers"
    
    // MARK: - Public
        
    func toUsers() -> (users: [BHUser], page: Int, pages: Int) {

        var users: [BHUser] = []

        if let validUsers = recentUsers {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    users.append(user)
                }
            }
        }
        
        return (users: users, page: page, pages: pages)
    }
}


