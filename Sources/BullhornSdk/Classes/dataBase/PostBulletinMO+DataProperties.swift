import Foundation
import CoreData

extension PostBulletinMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostBulletinMO> {
        return NSFetchRequest<PostBulletinMO>(entityName: PostBulletinMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var updatedAt: String?
    @NSManaged public var hasVideo: NSNumber?
    @NSManaged public var hasTiles: NSNumber?
}
