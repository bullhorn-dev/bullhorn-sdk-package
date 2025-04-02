
import Foundation

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }

    var notEmpty: Wrapped? {
        return (self?.isEmpty ?? true) ? nil : self
    }
}

extension Optional where Wrapped == NSSet {

    func array<T: Hashable>(of: T.Type) -> [T] {
        if let set = self as? Set<T> {
            return Array(set)
        }
        return [T]()
    }
}
