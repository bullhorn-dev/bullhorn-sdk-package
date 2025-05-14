import Foundation
import CoreData

@objc(OffsetMO)
public class OffsetMO: NSManagedObject {
    
    static let entityName = "Offset"
    
    // MARK: - Public
    
    func toOffset() -> BHOffset? {
        guard let validId = id else { return nil }
                
        return BHOffset(id: validId, offset: offset, timestamp: timestamp, completed: completed)
    }
}

