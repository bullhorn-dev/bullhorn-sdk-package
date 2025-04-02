
import Foundation

struct BHPhoneNumber: Codable {
    
    enum CodingKeys: String, CodingKey {
        case ipMismatch = "ip_mismatch"
        case localPhoneNumber = "local_phone_number"
        case countryCode = "country_code"
        case phoneNumber = "phone_number"
        case internationalPhoneNumber = "international_phone_number"
    }

    let ipMismatch: Bool
    let localPhoneNumber: String
    let countryCode: String
    let phoneNumber: String
    let internationalPhoneNumber: String
}
