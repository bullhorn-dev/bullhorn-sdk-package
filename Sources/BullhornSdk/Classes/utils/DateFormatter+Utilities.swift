
import Foundation

extension DateFormatter {

    static fileprivate let prettyTimeFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static fileprivate let prettyShortWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static fileprivate let prettyLongWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static fileprivate let prettyDateFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static fileprivate let prettyLongDateFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "MMMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static fileprivate let prettyYearFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static fileprivate let prettyFullDateFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func prettyFormatString(from date: Date) -> String {

        let currectCalendar = Calendar.current

        let formatter: DateFormatter
        if currectCalendar.isDateInToday(date) {
            formatter = .prettyTimeFormatter
        }
        else {
            let weekOfDate = currectCalendar.component(.weekOfYear, from: date)
            let weekOfToday = currectCalendar.component(.weekOfYear, from: Date())

            if weekOfDate == weekOfToday {
                formatter = .prettyShortWeekdayFormatter
            }
            else {
                let yearOfDate = currectCalendar.component(.year, from: date)
                let yearOfToday = currectCalendar.component(.year, from: Date())

                if yearOfDate == yearOfToday {
                    formatter = .prettyDateFormatter
                }
                else {
                    formatter = .prettyYearFormatter
                }
            }
        }

        return formatter.string(from: date)
    }

    func prettyDayFormatString(from date: Date) -> String {

        let currectCalendar = Calendar.current

        var formatter: DateFormatter = .prettyFullDateFormatter
        var formattedString: String?

        if currectCalendar.isDateInToday(date) {
            formattedString = NSLocalizedString("Today", comment: "")
        }
        else if currectCalendar.isDateInYesterday(date) {
            formattedString = NSLocalizedString("Yesterday", comment: "")
        }
        else {
            let weekOfDate = currectCalendar.component(.weekOfYear, from: date)
            let weekOfToday = currectCalendar.component(.weekOfYear, from: Date())

            if weekOfDate == weekOfToday {
                formatter = .prettyLongWeekdayFormatter
            }
            else {
                let yearOfDate = currectCalendar.component(.year, from: date)
                let yearOfToday = currectCalendar.component(.year, from: Date())

                if yearOfDate == yearOfToday {
                    formatter = .prettyDateFormatter
                }
                else {
                    formatter = .prettyFullDateFormatter
                }
            }
        }

        return formattedString ?? formatter.string(from: date)
    }
    
    func prettyFutureDayFormatString(from date: Date) -> String {

        let currectCalendar = Calendar.current

        var formatter: DateFormatter = .prettyFullDateFormatter
        var formattedDate: String = ""
        var formattedTime: String = ""

        if currectCalendar.isDateInToday(date) {
            formattedDate = NSLocalizedString("Today", comment: "")
        }
        else if currectCalendar.isDateInTomorrow(date) {
            formattedDate = NSLocalizedString("Tomorrow", comment: "")
        }
        else {
            let weekOfDate = currectCalendar.component(.weekOfYear, from: date)
            let weekOfToday = currectCalendar.component(.weekOfYear, from: Date())

            if weekOfDate == weekOfToday {
                formatter = .prettyLongWeekdayFormatter
            }
            else {
                let yearOfDate = currectCalendar.component(.year, from: date)
                let yearOfToday = currectCalendar.component(.year, from: Date())

                if yearOfDate == yearOfToday {
                    formatter = .prettyDateFormatter
                }
                else {
                    formatter = .prettyFullDateFormatter
                }
            }
            formattedDate = formatter.string(from: date)
        }
        
        formatter = .prettyTimeFormatter
        formattedTime = formatter.string(from: date)

        return "\(formattedDate) at \(formattedTime)".lowercased()
    }
    
    static func secondsToComponents(_ seconds : Int) -> (h: Int, m: Int, s: Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    static func formatDuration(withSeconds seconds: Int) -> String {
        let components = DateFormatter.secondsToComponents(seconds)
        let formatted = components.h != 0 ? "\(components.h):\(String(format: "%02d", components.m)):\(String(format: "%02d", components.s))" : "\(components.m):\(String(format: "%02d", components.s))"
        return formatted
    }
}
