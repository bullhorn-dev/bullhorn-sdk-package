
import Foundation

struct BHChannel: Codable, Hashable {
    
    static let mainChannelId: String = "89f11713-92f7-4568-928d-aa840446ced7"

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case categories
        case groupPodcastsByCategories = "group_podcasts_by_categories"
    }

    let id: String
    let name: String
    let title: String
    let categories: [BHUserCategory]?
    let groupPodcastsByCategories: Bool?
    
    func isMain() -> Bool { return id == BHChannel.mainChannelId }
    
    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func fromDictionary(_ params: [String: Any]) -> BHChannel? {
        guard let validId = params[CodingKeys.id.rawValue] as? String else { return nil }
        guard let validName = params[CodingKeys.name.rawValue] as? String else { return nil }
        guard let validTitle = params[CodingKeys.title.rawValue] as? String else { return nil }
        let groupPodcastsByCategories = params[CodingKeys.groupPodcastsByCategories.rawValue] as? Bool ?? false
        
        var validCategories: [BHUserCategory] = []

        if let ctgrs = params[CodingKeys.categories.rawValue] as? [[String:Any]] {
            ctgrs.forEach({ item in
                if let category = BHUserCategory.fromDictionary(item) {
                    validCategories.append(category)
                }
            })
        }

        return BHChannel(id: validId, name: validName, title: validTitle, categories: validCategories, groupPodcastsByCategories: groupPodcastsByCategories)
    }
}
