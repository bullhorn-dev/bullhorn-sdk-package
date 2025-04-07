import Foundation
import CoreData

extension NetworkUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkUsersMO> {
        return NSFetchRequest<NetworkUsersMO>(entityName: NetworkUsersMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var users: NSSet?
}
