import Foundation
import CoreData

@objc(QueueItemMO)
public class QueueItemMO: NSManagedObject {
    
    static let entityName = "QueueItem"
    
    // MARK: - Public
    
    func toQueueItem() -> BHQueueItem? {

        guard let validId = id else { return nil }
        guard let validPost = post?.toPost() else { return nil }
        let r = BHQueueReason(rawValue: reason) ?? .manually

        let item = BHQueueItem(id: validId, post: validPost, reason: r)
                
        return item
    }
}

