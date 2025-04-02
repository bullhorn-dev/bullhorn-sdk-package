import Foundation
import CoreData

extension NetworkFeaturedPostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkFeaturedPostsMO> {
        return NSFetchRequest<NetworkFeaturedPostsMO>(entityName: NetworkFeaturedPostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var featuredPosts: NSSet?
}
