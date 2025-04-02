import Foundation
import CoreData

extension NetworkRadiosMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkRadiosMO> {
        return NSFetchRequest<NetworkRadiosMO>(entityName: NetworkRadiosMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var radios: NSSet?
}

