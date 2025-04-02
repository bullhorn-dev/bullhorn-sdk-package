import Foundation
import CoreData

@objc(RecordingMO)
public class RecordingMO: NSManagedObject {
    
    static let entityName = "Recording"
    
    // MARK: - Public
    
    func toRecording() -> BHRecording? {

        guard let validId = id else { return nil }
        let dur = duration?.intValue ?? 0
        let url = publishUrl != nil ? URL(string: publishUrl!) : nil

        let recording = BHRecording(id: validId, duration: dur, publishUrl: url)
        
        return recording
    }
}
