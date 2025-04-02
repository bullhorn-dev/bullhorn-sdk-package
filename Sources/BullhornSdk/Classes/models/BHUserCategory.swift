import Foundation

// MARK: - User Category

struct BHUserCategory: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case id
        case icon
        case alias
        case gradientFrom = "gradient_from"
        case gradientTo = "gradient_to"
        case gradientDegree = "gradient_degree"
        case name
        case users
        case subCategoriesCount = "sub_categories_count"
    }
    
    let id: Int
    var icon: URL?
    var alias: String?
    var gradientFrom: String?
    var gradientTo: String?
    var gradientDegree: Int?
    var name: String?
    var users: [String]?
    var subCategoriesCount: Int?
    
    var hashValue: Int {
        return id.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
