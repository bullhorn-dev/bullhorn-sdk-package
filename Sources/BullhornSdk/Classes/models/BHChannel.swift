
import Foundation

struct BHChannel: Codable, Hashable {
    
    static let mainChannelId: String = "89f11713-92f7-4568-928d-aa840446ced7"

    enum Title: String {
        case all = "All"
        case news = "News"
        case sports = "Sports"
        case business = "Business"
        case entertainment = "Entertainment"
        case outkick = "Outkick"
        case television = "Television"
        case soul = "Soul"
        case deportes = "Deportes"
        case weather = "Weather"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case categories
    }

    let id: String
    let name: String
    let title: String
    let categories: [BHUserCategory]?
    
    func isMain() -> Bool { return id == BHChannel.mainChannelId }

    var parsedCategories: [String] {
        guard let t = Title(rawValue: title) else { return [] }

        switch t {
        case .all:
            return ["News Updates", "News & Politics", "True Crime", "Lifestyle", "People & Culture", "Sports", "Weather", "Business", "Deportes", "Entertainment", "TV", "Soul", "Outkick"]
        case .news:
            return ["News Updates", "News & Politics", "True Crime", "Lifestyle", "People & Culture"]
        case .sports:
            return ["Sports"]
        case .business:
            return ["News Updates", "Business"]
        case .entertainment:
            return ["Entertainment"]
        case .outkick:
            return ["Outkick"]
        case .television:
            return ["TV", "True Crime"]
        case .soul:
            return ["Soul"]
        case .deportes:
            return ["Deportes"]
        case .weather:
            return ["News Updates", "Weather"]
        }
    }
    
    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
