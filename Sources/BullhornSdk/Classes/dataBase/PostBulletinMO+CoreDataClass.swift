import Foundation
import CoreData

@objc(PostBulletinMO)
public class PostBulletinMO: NSManagedObject {
    
    static let entityName = "PostBulletin"
    
    // MARK: - Public

    func toPostBulletin() -> BHPostBulletin? {

        guard let validId = id else { return nil }
        guard let validUpdatedAt = updatedAt else { return nil }
        let video = hasVideo?.boolValue ?? false
        let tiles = hasTiles?.boolValue ?? false

        let bulletin = BHPostBulletin(id: validId, updatedAt: validUpdatedAt, hasVideo: video, hasTiles: tiles)
                
        return bulletin
    }
}
