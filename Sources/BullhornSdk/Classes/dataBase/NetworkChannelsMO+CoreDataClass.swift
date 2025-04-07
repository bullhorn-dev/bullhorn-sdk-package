import Foundation
import CoreData

@objc(NetworkChannelsMO)
public class NetworkChannelsMO: NSManagedObject {
    
    static let entityName = "NetworkChannels"
    
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

