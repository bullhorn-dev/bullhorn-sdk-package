
import Foundation

public extension String {

    func detect(regex: String, options: NSRegularExpression.Options = []) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()

        let dataDetector = try? NSRegularExpression(pattern: regex, options: options)
        dataDetector?.enumerateMatches(
            in: self, options: [], range: NSMakeRange(0, (self as NSString).length),
            using: { result, _, _ in
                if let r = result, let range = Range(r.range, in: self) {
                    ranges.append(range)
                }
            }
        )

        return ranges
    }

    func detectHashtags() -> [Range<String.Index>] {
        return detect(regex: TagPattern.hashtags)
    }

    func detectMentions() -> [Range<String.Index>] {
        return detect(regex: TagPattern.mentions)
    }

    func detect(textCheckingTypes: NSTextCheckingResult.CheckingType) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()

        let dataDetector = try? NSDataDetector(types: textCheckingTypes.rawValue)
        dataDetector?.enumerateMatches(
            in: self, options: [], range: NSMakeRange(0, (self as NSString).length),
            using: { result, _, _ in
                if let r = result, let range = Range(r.range, in: self) {
                    ranges.append(range)
                }
            }
        )
        return ranges
    }

    func detectPhoneNumbers() -> [Range<String.Index>] {
        return detect(textCheckingTypes: [.phoneNumber])
    }

    func detectLinks() -> [Range<String.Index>] {
        return detect(regex: TagPattern.links)
    }
    
    func detectTimestamps() -> [Range<String.Index>] {
        return detect(regex: TagPattern.timestamps)
    }
}
