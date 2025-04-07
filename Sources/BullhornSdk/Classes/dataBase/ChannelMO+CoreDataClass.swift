import Foundation
import CoreData

@objc(ChannelMO)
public class ChannelMO: NSManagedObject {
    
    static let entityName = "Channel"
    
    // MARK: - Public
        
    func toChannel() -> BHChannel? {

        guard let validId = id else { return nil }
        guard let validName = name else { return nil }
        guard let validTitle = title else { return nil }

        return BHChannel(id: validId, name: validName, title: validTitle)
    }
}

