import Foundation

extension Array {

    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}

extension Array where Element == Any? {

    var toLog: String  {
        var strs:[String] = []
        for element in self {
            strs.append("\(element ?? "nil")")
        }
        return strs.joined(separator: " |^| ")
    }
}

