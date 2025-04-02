
import Foundation

struct BHLog {

    static private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
//        formatter.locale = Locale.init(identifier: "en_US_POSIX")
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZ"
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)

        return formatter
    }()

    public static func p(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if !DISABLE_SWIFT_LOG
        if BullhornSdk.shared.isLoggingEnabled {
            let timestamp = BHLog.dateTimeFormatter.string(from: Date())
            let stringItem = "[\(timestamp)] " + items.map( {"\($0)"} ).joined(separator: separator) + terminator
            Swift.print(stringItem, terminator: terminator)
        }
        #endif
    }

    public static func w(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if !DISABLE_SWIFT_LOG
        if BullhornSdk.shared.isLoggingEnabled {
            let timestamp = BHLog.dateTimeFormatter.string(from: Date())
            let stringItem = "[\(timestamp)] " + items.map( {"\($0)"} ).joined(separator: separator) + terminator + "*******************" + terminator
            Swift.print("\(terminator)*******************\(terminator)WARNING - " + stringItem, terminator: terminator)
        }
        #endif
    }
}
