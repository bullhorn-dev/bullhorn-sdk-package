import Foundation
import CoreData

@objc(DownloadItemMO)
public class DownloadItemMO: NSManagedObject {
    
    static let entityName = "DownloadItem"
    
    // MARK: - Public
    
    func toDownloadItem() -> BHDownloadItem? {

        guard let validId = id else { return nil }
        guard let validPost = post?.toPost() else { return nil }
        guard let validUrlStr = url,
              let validUrl = URL(string: validUrlStr) else { return nil }

        let s = DownloadStatus(rawValue: status) ?? .start
        let prs = DownloadStatus(rawValue: prevStatus) ?? .start
        let r = DownloadReason(rawValue: reason) ?? .manually
        let f = file != nil ? URL(string: file!) : nil

        let item = BHDownloadItem(id: validId, post: validPost, status: s, prevStatus: prs, reason: r, progress: progress, url: validUrl, file: f, time: time)
                
        return item
    }
}
