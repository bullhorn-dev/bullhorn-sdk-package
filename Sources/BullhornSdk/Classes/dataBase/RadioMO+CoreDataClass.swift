import Foundation
import CoreData

@objc(RadioMO)
public class RadioMO: NSManagedObject {
    
    static let entityName = "Radio"
    
    // MARK: - Public
    
    func toRadio() -> BHRadio? {

        guard let validId = id else { return nil }
        guard let validTitle = title else { return nil }

        let purl = playbackUrl != nil ? URL(string: playbackUrl!) : nil
        let number = phoneNumber

        var s: [BHStream] = []

        if let validStreams = streams {
            for streamMO in validStreams.compactMap({ $0 as? StreamMO }) {
                if let stream = streamMO.toStream() {
                    s.append(stream)
                }
            }
        }

        let radio = BHRadio(id: validId, title: validTitle, playbackUrl: purl, phoneNumber: number, streams: s)

        return radio
    }
}

