
import Foundation

struct BHChannel: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
    }

    let id: String
    let name: String
    let title: String
    
    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
