import Foundation
import CoreData

@objc(CategoryUsersMO)
public class CategoryUsersMO: NSManagedObject {
    
    static let entityName = "CategoryUsers"
    
    // MARK: - Public
        
    func toUsers() -> [BHUser] {

        var result: [BHUser] = []

        if let validUsers = categoryUsers {
            for userMO in validUsers.compactMap({ $0 as? UserMO }) {
                if let user = userMO.toUser() {
                    result.append(user)
                }
            }
        }
        
        return result
    }
}


