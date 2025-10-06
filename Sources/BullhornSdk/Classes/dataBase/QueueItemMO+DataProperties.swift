import Foundation
import CoreData

extension QueueItemMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QueueItemMO> {
        return NSFetchRequest<QueueItemMO>(entityName: QueueItemMO.entityName)
    }

    @NSManaged public var id: String?
    @NSManaged public var post: PostMO?
    @NSManaged public var reason: Int
}

