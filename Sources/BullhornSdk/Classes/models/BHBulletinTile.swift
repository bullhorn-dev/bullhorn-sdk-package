
import Foundation
import UIKit

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
    
    func attributedDescription(baseColor: UIColor = UIColor.playerOnDisplayBackground()) -> NSAttributedString {
        guard let validText = description else { return NSAttributedString() }
        
        let font: UIFont = .fontWithName(.robotoMedium, size: 18)
        let base = Attrs().font(font).foregroundColor(baseColor)
        let links = Attrs().font(font).foregroundColor(baseColor).underlineStyle(.single)
        let a = Attrs().font(font).foregroundColor(baseColor)
        let b = Attrs().font(.fontWithName(.robotoBold, size: 14))
        let u = Attrs().underlineStyle(.single)
        let i = TagTuner { info in
            var set = Set<String>()
            set.insert(info.tag.name)
            info.outerTags.forEach { set.insert($0.name) }

            let attrs = Attrs()
            if set.contains("b") && set.contains("i") {
                attrs.font(UIFont(name: "HelveticaNeue-BoldItalic", size: 14)!)
            } else if set.contains("i") {
                attrs.font(UIFont(name: "HelveticaNeue-Italic", size: 14)!)
            } else if set.contains("b") {
                attrs.font(UIFont(name: "HelveticaNeue-Bold", size: 14)!)
            }
            return attrs
        }

        let attributedText = validText
            .style(tags: ["a": a, "u": u, "i": i, "b": b])
            .styleBase(base)
            .styleLinks(links)
            .attributedString

        return attributedText.trimmingWhitespaceAndNewlines()
    }
}
