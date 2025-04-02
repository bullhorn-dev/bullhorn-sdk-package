import Foundation
import CoreData

@objc(StreamMO)
public class StreamMO: NSManagedObject {
    
    static let entityName = "Stream"
    
    // MARK: - Public
    
    func toStream() -> BHStream? {

        guard let validId = id else { return nil }
        guard let validTitle = title else { return nil }

        let start = startAt?.intValue ?? 0
        let end = endAt?.intValue ?? 0
        let cover = coverUrl != nil ? URL(string: coverUrl!) : nil
        let phone = phoneNumber

        let stream = BHStream(id: validId, title: validTitle, startAt: start, endAt: end, coverUrl: cover, phoneNumber: phone)
        
        return stream
    }
}

