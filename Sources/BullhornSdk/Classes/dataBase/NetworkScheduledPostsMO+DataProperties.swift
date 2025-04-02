import Foundation
import CoreData

extension NetworkScheduledPostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkScheduledPostsMO> {
        return NSFetchRequest<NetworkScheduledPostsMO>(entityName: NetworkScheduledPostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var scheduledPosts: NSSet?
}
