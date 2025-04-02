import Foundation
import CoreData

@objc(NetworkRadiosMO)
public class NetworkRadiosMO: NSManagedObject {
    
    static let entityName = "NetworkRadios"
    
    // MARK: - Public
        
    func toRadios() -> [BHRadio] {

        var r: [BHRadio] = []

        if let validRadios = radios {
            for radioMO in validRadios.compactMap({ $0 as? RadioMO }) {
                if let radio = radioMO.toRadio() {
                    r.append(radio)
                }
            }
        }
        
        return r
    }
}

