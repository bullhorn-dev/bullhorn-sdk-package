
import Foundation

// MARK: - BHBulletinPollVariant

struct BHBulletinPollVariant: JsonApiCodable {

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case value
        case answersCount = "answers_count"
        case userVoted = "user_voted"
    }

    let id: String
    let type: String = "poll_variant"

    let value: String
    let answersCount: Int
    let userVoted: Bool
    
    init(id: String,
         value: String = "",
         answersCount: Int = 0,
         userVoted: Bool = false) {

        self.id = id
        self.value = value
        self.answersCount = answersCount
        self.userVoted = userVoted
    }
}

// MARK: - BHBulletinTile

struct BHBulletinTile: JsonApiCodable {
    
    // MARK: - Category

    enum Category: String, Decodable {

        case text = "text"
        case image = "image"
        case ad = "ad"
        case poll = "poll"
        case banner = "banner"
    }

    // MARK: - Kind

    enum Kind: String, Decodable {

        case regular = "regular"
        case lowThird = "lowthird"
    }

    
    enum CodingKeys: String, CodingKey {

        case id
        case type
        case category
        case title
        case description
        case url
        case image
        case imageSmall = "image_small"
        case imageTiny = "image_tiny"
        case pollVariants = "poll_variants"
        case kind
    }

    let id: String
    let type: String = "bulletin_tile"

    let category: String
    let title: String?
    let description: String?
    let url: URL?
    let image: URL?
    let imageSmall: URL?
    let imageTiny: URL?
    var pollVariants: [BHBulletinPollVariant]?
    let kind: String?
    
    init(id: String,
         category: String,
         title: String? = nil,
         description: String? = nil,
         url: URL? = nil,
         image: URL? = nil,
         imageSmall: URL? = nil,
         imageTiny: URL? = nil,
         pollVariants: [BHBulletinPollVariant]? = nil,
         kind: String? = nil) {

        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.url = url
        self.image = image
        self.imageSmall = imageSmall
        self.imageTiny = imageTiny
        self.pollVariants = pollVariants
        self.kind = kind
    }
    
    var tileCategory: Category {
        return BHBulletinTile.Category(rawValue: category) ?? .text
    }
    
    var tileKind: Kind {
        return BHBulletinTile.Kind(rawValue: kind ?? "") ?? .regular
    }

    func isAd() -> Bool { tileCategory == .ad }
    func isImage() -> Bool { tileCategory == .image }
    func isPoll() -> Bool { tileCategory == .poll }
    func isText() -> Bool { tileCategory == .text }
    func isBanner() -> Bool { tileCategory == .banner }
    
    func totalPollAnswersCount() -> Int {
        guard let variants = pollVariants else { return 0 }
        
        var result: Int = 0
        
        variants.forEach { result += $0.answersCount }
        
        return result
    }
    
    func isPollVariantWinner(_ pollVariant: BHBulletinPollVariant?) -> Bool {
        guard let variants = pollVariants else { return false }
        guard let variant = pollVariant else { return false }

        var maxAnswersCount: Int = 0
        
        variants.forEach {
            if $0.answersCount > maxAnswersCount {
                maxAnswersCount = $0.answersCount
            }
        }
        
        return variant.answersCount >= maxAnswersCount
    }
    
    func isVoted() -> Bool {
        guard let variants = pollVariants else { return false }
        
        if variants.first(where: { $0.userVoted }) != nil {
            return true
        }
        
        return false
    }
    
    func hasPollVariant(_ variantId: String) -> Bool {
        return (pollVariants?.firstIndex(where: {$0.id == variantId})) != nil
    }

    mutating func updatePollVariant(_ variant: BHBulletinPollVariant) {
        if let index = pollVariants?.firstIndex(where: {$0.id == variant.id}) {
            pollVariants?[index] = variant
        }
    }
}
