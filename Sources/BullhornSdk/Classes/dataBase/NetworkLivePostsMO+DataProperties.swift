import Foundation
import CoreData

extension NetworkLivePostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkLivePostsMO> {
        return NSFetchRequest<NetworkLivePostsMO>(entityName: NetworkLivePostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var livePosts: NSSet?
}
