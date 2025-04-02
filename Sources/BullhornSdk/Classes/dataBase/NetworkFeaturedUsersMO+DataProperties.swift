import Foundation
import CoreData

extension NetworkFeaturedUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkFeaturedUsersMO> {
        return NSFetchRequest<NetworkFeaturedUsersMO>(entityName: NetworkFeaturedUsersMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var featuredUsers: NSSet?
}
