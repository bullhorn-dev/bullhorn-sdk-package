import Foundation
import CoreData

@objc(NetworkUsersMO)
public class NetworkUsersMO: NSManagedObject {
    
    static let entityName = "NetworkUsers"
    
    // MARK: - Public
        
    func toNetworkUsers() -> (users: [BHUser], page: Int, pages: Int) {

        var usrs: [BHUser] = []

        if let validUsers = users {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    usrs.append(user)
                }
            }
        }
        
        return (users: usrs, page: page, pages: pages)
    }
}
