import Foundation
import CoreData

extension FollowedUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowedUsersMO> {
        return NSFetchRequest<FollowedUsersMO>(entityName: FollowedUsersMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var followedUsers: NSSet?
}

