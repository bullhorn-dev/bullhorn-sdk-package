import Foundation
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

// Global constants (values assumed based on original usage)
let DateParserDateNoTimestampFormat = "2015-09-10T00:00:00"
let DateParserTimestamp = "."
let DateParserDescriptionDate = "2009-10-09 00:00:00"

// Enum for DateType
@objc enum DateType: Int {
    case iso8601
    case unixTimestamp
}

// Helper function to copy characters similar to strncpy
func strncpySwift(dest: inout [CChar], destOffset: Int, src: [CChar], srcOffset: Int, count: Int) {
    for i in 0..<count {
        if destOffset + i < dest.count && srcOffset + i < src.count {
            dest[destOffset + i] = src[srcOffset + i]
        }
    }
}

// Helper function to calculate C-string length from a CChar array
func cStringLength(_ buffer: [CChar]) -> Int {
    var length = 0
    for char in buffer {
        if char == 0 { break }
        length += 1
    }
    return length
}

extension NSDate {

    @objc class func dateFromDateString(_ dateString: NSString) -> NSDate? {
        var parsedDate: NSDate? = nil

        // DateType dateType = [dateString dateType];
        let dateType: DateType = dateString.dateType()
        switch dateType {
        case .iso8601:
            // parsedDate = [self dateFromISO8601String:dateString];
            parsedDate = self.dateFromISO8601String(dateString)
        case .unixTimestamp:
            // parsedDate = [self dateFromUnixTimestampString:dateString];
            parsedDate = self.dateFromUnixTimestampString(dateString)
        }
        // default: break;
        return parsedDate
    }

    // + (NSDate *)dateFromISO8601String:(NSString *)dateString {
    @objc class func dateFromISO8601String(_ dateString: NSString) -> NSDate? {
        if dateString.length == 0 || dateString.isEqual(NSNull()) {
            return nil
        }
        // Parse string
        // else if ([dateString isKindOfClass:[NSString class]]) {
        // In Swift, dateString is always NSString here.
        var workingDateString = dateString as String

        if workingDateString.count == DateParserDateNoTimestampFormat.count {
            // NSMutableString *mutableRemoteValue = [dateString mutableCopy];
            // [mutableRemoteValue appendString:DateParserTimestamp];
            // dateString = [mutableRemoteValue copy];
            workingDateString += DateParserTimestamp
        }

        // Convert NSDate description to NSDate
        // Current date: 2009-10-09 00:00:00
        // Will become:  2009-10-09T00:00:00
        // Unit test L
        if workingDateString.count == DateParserDescriptionDate.count {
            let index = workingDateString.index(workingDateString.startIndex, offsetBy: 10)
            let spaceString = String(workingDateString[index])
            if spaceString == " " {
                workingDateString.replaceSubrange(index...index, with: "T")
            }
        }

        // Convert to C string using UTF8 encoding
        var origCString = Array(workingDateString.utf8CString)
        let originalLength = Int(strlen(&origCString))
        if originalLength == 0 {
            return nil
        }

        // Create a buffer for currentString of length 25, prefilled with zeros
        var currentString = [CChar](repeating: 0, count: 25)
        var hasTimezone = false
        var hasDeciseconds = false
        var hasCentiseconds = false
        var hasMiliseconds = false
        var hasMicroseconds = false

        // ----
        // In general lines, if a Z is found, then the Z is removed since all dates operate
        // in GMT as a base, unless they have timezone, and Z is the GMT indicator.
        //
        // If +00:00 or any number after + is found, then it means that the date has a timezone.
        // This means that `hasTimezone` will have to be set to YES, and since all timezones go to
        // the end of the date, then they will be parsed at the end of the process and appended back
        // to the parsed date.
        //
        // If after the date theres `.` and a number `2014-03-30T09:13:00.XXX` the `XXX` is the milisecond
        // then `hasMiliseconds` will be set to YES. The same goes for `XX` decisecond (hasCentiseconds set to YES).
        // and microseconds `XXXXXX` (hasMicroseconds set yo YES).
        //
        // If your date format is not supported, then you'll get "Signal Sigabrt". Just ask your format to be included.
        // ----

        // Copy all the date excluding the Z.
        // Current date: 2014-03-30T09:13:00Z
        // Will become:  2014-03-30T09:13:00
        // Unit test H
        if originalLength == 20 && origCString[originalLength - 1] == CChar(UnicodeScalar("Z").value) {
            // strncpy(currentString, originalString, originalLength - 1);
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: originalLength - 1)
        }
        // Copy all the date excluding the timezone also set `hasTimezone` to YES.
        // Current date: 2014-01-01T00:00:00+00:00
        // Will become:  2014-01-01T00:00:00
        // Unit test B and C
        else if originalLength == 25 && origCString[22] == CChar(UnicodeScalar(":").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasTimezone = true
        }
        // Copy all the date excluding the miliseconds and the Z.
        // Current date: 2014-03-30T09:13:00.000Z
        // Will become:  2014-03-30T09:13:00
        // Unit test G
        else if originalLength == 24 && origCString[originalLength - 1] == CChar(UnicodeScalar("Z").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasMiliseconds = true
        }
        // Copy all the date excluding the miliseconds and the Z.
        // Current date: 2017-12-22T18:10:14.07Z
        // Will become:  2014-03-30T09:13:00
        // Unit test M
        else if originalLength == 23 && origCString[originalLength - 1] == CChar(UnicodeScalar("Z").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasCentiseconds = true
        }
        // Copy all the date excluding the miliseconds.
        // Current date: 2017-12-22T18:10:14.070
        // Will become:  2017-12-22T18:10:14
        // Unit test O
        else if originalLength == 23 && origCString[originalLength - 1] != CChar(UnicodeScalar("Z").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasMiliseconds = true
        }
        // Copy all the date excluding the miliseconds and the Z.
        // Current date: 2017-11-02T17:27:52.2Z
        // Will become:  2014-03-30T09:13:00
        // Unit test N
        else if originalLength == 22 && origCString[originalLength - 1] == CChar(UnicodeScalar("Z").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasDeciseconds = true
        }
        // Copy all the date excluding the miliseconds and the timezone also set `hasTimezone` to YES.
        // Current date: 2015-06-23T12:40:08.000+02:00
        // Will become:  2015-06-23T12:40:08
        // Unit test A
        else if originalLength == 29 && origCString[26] == CChar(UnicodeScalar(":").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasTimezone = true
            hasMiliseconds = true
        }
        // Copy all the date excluding the microseconds and the timezone also set `hasTimezone` to YES.
        // Current date: 2015-08-23T09:29:30.007450+00:00
        // Will become:  2015-08-23T09:29:30
        // Unit test D
        else if originalLength == 32 && origCString[29] == CChar(UnicodeScalar(":").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasTimezone = true
            hasMicroseconds = true
        }
        // Copy all the date excluding the microseconds and the timezone.
        // Current date: 2015-09-10T13:47:21.116+0000
        // Will become:  2015-09-10T13:47:21
        // Unit test E
        else if originalLength == 28 && origCString[23] == CChar(UnicodeScalar("+").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasMiliseconds = true
        }
        // Copy all the date excluding the microseconds and the Z.
        // Current date: 2015-09-10T00:00:00.184968Z
        // Will become:  2015-09-10T00:00:00
        // Unit test F
        else if origCString[19] == CChar(UnicodeScalar(".").value) && origCString[originalLength - 1] == CChar(UnicodeScalar("Z").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasMicroseconds = true
        }
        // Copy all the date excluding the miliseconds.
        // Current date: 2016-01-09T00:00:00.00
        // Will become:  2016-01-09T00:00:00
        // Unit test J
        else if originalLength == 22 && origCString[19] == CChar(UnicodeScalar(".").value) {
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: 19)
            hasCentiseconds = true
        }
        // Poorly formatted timezone
        else {
            let countToCopy = originalLength > 24 ? 24 : originalLength
            strncpySwift(dest: &currentString, destOffset: 0, src: origCString, srcOffset: 0, count: countToCopy)
        }

        // Timezone
        let currentLength = cStringLength(currentString)
        if hasTimezone {
            // Add the first part of the removed timezone to the end of the string.
            // Orignal date: 2015-06-23T14:40:08.000+02:00
            // Current date: 2015-06-23T14:40:08
            // Will become:  2015-06-23T14:40:08+02
            strncpySwift(dest: &currentString, destOffset: currentLength, src: origCString, srcOffset: originalLength - 6, count: 3)
            // Add the second part of the removed timezone to the end of the string.
            // Original date: 2015-06-23T14:40:08.000+02:00
            // Current date:  2015-06-23T14:40:08+02
            // Will become:   2015-06-23T14:40:08+0200
            strncpySwift(dest: &currentString, destOffset: currentLength + 3, src: origCString, srcOffset: originalLength - 2, count: 2)
        } else {
            // Add GMT timezone to the end of the string
            // Current date: 2015-09-10T00:00:00
            // Will become:  2015-09-10T00:00:00+0000
            let timezoneStr = Array("+0000".utf8CString)
            strncpySwift(dest: &currentString, destOffset: currentLength, src: timezoneStr, srcOffset: 0, count: 5)
        }

        // Add null terminator
        currentString[currentString.count - 1] = 0

        // Parse the formatted date using `strptime`.
        // %F: Equivalent to %Y-%m-%d, the ISO 8601 date format
        //  T: The date, time separator
        // %T: Equivalent to %H:%M:%S
        // %z: An RFC-822/ISO 8601 standard timezone specification
        var tm = tm()
        let ret: UnsafeMutablePointer<CChar>? = currentString.withUnsafeMutableBufferPointer { buffer in
            let baseAddress = buffer.baseAddress
            return strptime(baseAddress, "%FT%T%z", &tm)
        }
        if ret == nil {
            return nil
        }

        let timeStruct = mktime(&tm)
        var timeInterval = Double(timeStruct)

        if hasDeciseconds || hasCentiseconds || hasMiliseconds || hasMicroseconds {
            // Converts to NSString to use substringFromIndex with constant length.
            let trimmedDate = (workingDateString as NSString).substring(from: "2015-09-10T00:00:00.".count)

            if hasDeciseconds {
                let centisecondsString = (trimmedDate as NSString).substring(to: "0".count)
                let centiseconds = (centisecondsString as NSString).doubleValue / 10.0
                timeInterval += centiseconds
            }

            if hasCentiseconds {
                let centisecondsString = (trimmedDate as NSString).substring(to: "00".count)
                let centiseconds = (centisecondsString as NSString).doubleValue / 100.0
                timeInterval += centiseconds
            }

            if hasMiliseconds {
                let milisecondsString = (trimmedDate as NSString).substring(to: "000".count)
                let miliseconds = (milisecondsString as NSString).doubleValue / 1000.0
                timeInterval += miliseconds
            }

            if hasMicroseconds {
                // Converts microseconds to miliseconds to keep consistency with NSDateFormatter
                // since it doesn't handle microseconds
                let microsecondsString = (trimmedDate as NSString).substring(to: "000000".count)
                let reducedHundreds = (microsecondsString as NSString).doubleValue / 1000.0
                let hundredsInt = Int(reducedHundreds)
                let microsecondsWithoutHundreds = reducedHundreds - Double(hundredsInt)
                let removedMicroseconds = microsecondsWithoutHundreds * 1000
                let convertedMicroseconds = (microsecondsString as NSString).doubleValue - removedMicroseconds
                let miliseconds = convertedMicroseconds / 1000000.0
                timeInterval += miliseconds
            }
        }

        return NSDate(timeIntervalSince1970: timeInterval)
        // }

        // NSAssert1(NO, @"Failed to parse date: %@", dateString);
        // In Swift, assertion failure:
        // (This line will not be reached because of the return above.)
        // But for exact translation, we add:
        assert(false, "Failed to parse date: \(dateString)")
        // return nil;
    }

    // + (NSDate *)dateFromUnixTimestampNumber:(NSNumber *)unixTimestamp {
    @objc class func dateFromUnixTimestampNumber(_ unixTimestamp: NSNumber) -> NSDate? {
        return self.dateFromUnixTimestampString(unixTimestamp.stringValue as NSString)
    }

    // + (NSDate *)dateFromUnixTimestampString:(NSString *)unixTimestamp {
    @objc class func dateFromUnixTimestampString(_ unixTimestamp: NSString) -> NSDate? {
        var parsedString = unixTimestamp as String

        let validUnixTimestamp = "1441843200"
        let validLength = validUnixTimestamp.count
        if (unixTimestamp.length > validLength) {
            parsedString = (unixTimestamp as String).prefix(validLength).description
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        guard let unixTimestampNumber = numberFormatter.number(from: parsedString) else {
            return nil
        }
        let date = NSDate(timeIntervalSince1970: unixTimestampNumber.doubleValue)
        return date
    }
}

extension NSString {
    // @implementation NSString (Parser)
    // - (DateType)dateType {
    @objc func dateType() -> DateType {
        if self.contains("-") {
            return DateType.iso8601
        } else {
            return DateType.unixTimestamp
        }
    }
    // @end
}

