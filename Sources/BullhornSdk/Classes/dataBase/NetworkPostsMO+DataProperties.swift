import Foundation
import CoreData

extension NetworkPostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkPostsMO> {
        return NSFetchRequest<NetworkPostsMO>(entityName: NetworkPostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var page: Int
    @NSManaged public var pages: Int
    @NSManaged public var posts: NSSet?
}
