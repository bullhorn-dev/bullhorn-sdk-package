import Foundation

class InflectionsStringStorage: NSObject {

    var _snakeCaseStorage: NSMutableDictionary?
    var _camelCaseStorage: NSMutableDictionary?

    var serialQueue = DispatchQueue(label: "com.syncdb.NSString_Inflections.serialQueue", qos: .default)

    static let sharedInstance: InflectionsStringStorage = {
        let instance = InflectionsStringStorage()
        return instance
    }()

    override init() {
        super.init()
    }

    var snakeCaseStorage: NSMutableDictionary {
        if _snakeCaseStorage == nil {
            _snakeCaseStorage = NSMutableDictionary()
        }
        return _snakeCaseStorage!
    }

    var camelCaseStorage: NSMutableDictionary {
        if _camelCaseStorage == nil {
            _camelCaseStorage = NSMutableDictionary()
        }
        return _camelCaseStorage!
    }

    func performOnDictionary(_ block: @escaping () -> Void) {
        serialQueue.sync {
            block()
        }
    }
}

// MARK: - NSString (Inflections) Extension in Swift as String Extension

extension String {

    // MARK: - Private Methods

    // Returns the snake_case version of the string.
    func hyp_snakeCase() -> String {
        let stringStorage = InflectionsStringStorage.sharedInstance
        var storedResult: String? = nil

        stringStorage.performOnDictionary {
            storedResult = stringStorage.snakeCaseStorage[self] as? String
        }

        if let storedResult = storedResult {
            return storedResult
        } else {
            let firstLetterLowercase = self.hyp_lowerCaseFirstLetter()
            let result = firstLetterLowercase.hyp_replaceIdentifierWithString("_")!
            stringStorage.performOnDictionary {
                stringStorage.snakeCaseStorage[self] = result
            }
            return result
        }
    }

    // Returns the camelCase version of the string.
    func hyp_camelCase() -> String {
        let stringStorage = InflectionsStringStorage.sharedInstance
        var storedResult: String? = nil

        stringStorage.performOnDictionary {
            storedResult = stringStorage.camelCaseStorage[self] as? String
        }

        if let storedResult = storedResult {
            return storedResult
        } else {
            var result: String

            if self.contains("_") {
                var processedString = self.hyp_replaceIdentifierWithString("")!
                let remoteStringIsAnAcronym = (NSString.acronyms().contains(processedString.lowercased()))
                result = remoteStringIsAnAcronym ? processedString.lowercased() : processedString.hyp_lowerCaseFirstLetter()
            } else {
                result = self.hyp_lowerCaseFirstLetter()
            }

            stringStorage.performOnDictionary {
                stringStorage.camelCaseStorage[self] = result
            }

            return result
        }
    }

    // Checks if the string contains a specific word separated by underscores.
    func hyp_containsWord(_ word: String) -> Bool {
        var found = false
        let components = self.components(separatedBy: "_")
        for component in components {
            if component == word {
                found = true
                break
            }
        }
        return found
    }

    // Returns the string with the first letter lowercased.
    func hyp_lowerCaseFirstLetter() -> String {
        var mutableString = self
        let firstLetter = String(mutableString.prefix(1)).lowercased()
        mutableString.replaceSubrange(mutableString.startIndex...mutableString.startIndex, with: firstLetter)
        return mutableString
    }

    // Replaces identifier characters with the provided replacement string.
    func hyp_replaceIdentifierWithString(_ replacementString: String) -> String? {
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = nil
        scanner.caseSensitive = true

        let identifierSet = CharacterSet(charactersIn: "_- ")
        let alphanumericSet = CharacterSet.alphanumerics
        let uppercaseSet = CharacterSet.uppercaseLetters
        let lowercaseLettersSet = CharacterSet.lowercaseLetters
        let decimalDigitSet = CharacterSet.decimalDigits
        let lowercaseSet = lowercaseLettersSet.union(decimalDigitSet)

        var buffer: NSString? = nil
        let output = NSMutableString()

        while !scanner.isAtEnd {
            var isExcludedCharacter = false
            if scanner.scanCharacters(from: identifierSet, into: &buffer) {
                isExcludedCharacter = true
            }
            if isExcludedCharacter {
                continue
            }

            if replacementString.count > 0 {
                var isUppercaseCharacter = false
                if scanner.scanCharacters(from: uppercaseSet, into: &buffer) {
                    isUppercaseCharacter = true
                    if let buf = buffer as String? {
                        for string in NSString.acronyms() {
                            if buf.lowercased().range(of: string) != nil {
                                if buf.count == string.count {
                                    buffer = string as NSString
                                } else {
                                    buffer = "\(string)_\((buf.lowercased().replacingOccurrences(of: string, with: "")))" as NSString
                                }
                                break
                            }
                        }
                        output.append(replacementString)
                        if let validBuffer = buffer as? String {
                            output.append(validBuffer.lowercased())
                        }
                    }
                }

                if scanner.scanCharacters(from: lowercaseSet, into: &buffer) {
                    if let buf = buffer as String? {
                        output.append(buf.lowercased())
                    }
                }
            } else if scanner.scanCharacters(from: alphanumericSet, into: &buffer) {
                if let buf = buffer as String? {
                    if NSString.acronyms().contains(buf) {
                        output.append(buf.uppercased())
                    } else {
                        output.append(buf.capitalized)
                    }
                }
            } else {
                return nil
            }
        }

        return output as String
    }

    // Returns an array of acronym strings.
    static func acronyms() -> [String] {
        return ["uuid", "id", "pdf", "url", "png", "jpg", "uri", "json", "xml"]
    }
}

// MARK: - NSString Acronyms Helper Extension

extension NSString {
    static func acronyms() -> [String] {
        return String.acronyms()
    }
}

