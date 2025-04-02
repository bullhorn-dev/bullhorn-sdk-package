
import Foundation
import CoreData

extension LikedPostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LikedPostsMO> {
        return NSFetchRequest<LikedPostsMO>(entityName: LikedPostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var page: Int
    @NSManaged public var pages: Int
    @NSManaged public var likedPosts: NSSet?
}
