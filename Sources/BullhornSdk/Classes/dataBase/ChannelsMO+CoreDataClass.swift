import Foundation
import CoreData

@objc(ChannelsMO)
public class ChannelsMO: NSManagedObject {
    
    static let entityName = "Channels"
    
    // MARK: - Public
        
    func toChannels() -> [BHChannel] {

        var items: [BHChannel] = []

        if let validChannels = channels {
            for channelMO in validChannels.compactMap({ $0 as? ChannelMO }) {
                if let channel = channelMO.toChannel() {
                    items.append(channel)
                }
            }
        }
        
        return items
    }
}

