
import Foundation

extension Data {
    func legacyUnarchivedObject() -> Any? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: self) else { return nil }
        unarchiver.requiresSecureCoding = false
        let obj = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        unarchiver.finishDecoding()
        return obj
    }
}
