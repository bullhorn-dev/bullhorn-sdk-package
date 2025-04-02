import Foundation
import CoreData

@objc(NetworkMO)
public class NetworkMO: NSManagedObject {
    
    static let entityName = "Network"
    
    // MARK: - Public
        
    func toNetwork() -> BHNetwork? {

        guard let validId = id else { return nil }
        guard let validCreatedAt = createdAt else { return nil }
        guard let validDescr = descr else { return nil }
        guard let validName = name else { return nil }
        guard let validPath = path else { return nil }

        var network = BHNetwork(id: validId, createdAt: validCreatedAt, description: validDescr, name: validName, path: validPath, podcastsCount: podcastsCount)
        
        network.profilePicture = profilePicture != nil ? URL(string: profilePicture!) : nil
        network.profilePictureBig = profilePictureBig != nil ? URL(string: profilePictureBig!) : nil
        network.profilePictureTiny = profilePictureTiny != nil ? URL(string: profilePictureTiny!) : nil
        network.shareLink = shareLink != nil ? URL(string: shareLink!) : nil
        
        return network
    }
}
