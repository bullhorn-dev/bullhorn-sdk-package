import Foundation
import CoreData


private let PropertyMapperNestedAttributesKey = "attributes"

// MARK: - Enums

enum SyncPropertyMapperRelationshipType: Int {
    case none = 0
    case array
    case nested
}

enum SyncPropertyMapperInflectionType: Int {
    case snakeCase = 0
    case camelCase
}

// MARK: - NSManagedObject Extension (PropertyMapper)

extension NSManagedObject {

    // MARK: - Public methods
    
    func fillWithDictionary(_ dictionary: [String: Any]) {
        self.hyp_fillWithDictionary(dictionary: dictionary)
    }
    
    func hyp_fillWithDictionary(dictionary: [String: Any]) {
        for key in dictionary.keys {
            let value: Any? = dictionary[key]
            
            if let attributeDescription = self.attributeDescriptionForRemoteKey(key) {
                let valueExists: Bool = (value != nil && !(value is NSNull))
                if valueExists && (value is [String: Any]) && attributeDescription.attributeType != NSAttributeType.binaryDataAttributeType {
                    let remoteKey: String? = self.remoteKeyForAttributeDescription(attributeDescription, inflectionType: .snakeCase)
                    let hasCustomKeyPath: Bool = (remoteKey != nil && remoteKey!.contains("."))
                    if hasCustomKeyPath {
                        let keyPathAttributeDescriptions: [NSAttributeDescription] = self.attributeDescriptionsForRemoteKeyPath(remoteKey!)
                        for keyPathAttributeDescription in keyPathAttributeDescriptions {
                            let remoteKeyInner: String? = self.remoteKeyForAttributeDescription(keyPathAttributeDescription, inflectionType: .snakeCase)
                            let localKey: String = keyPathAttributeDescription.name
                            let dictValue: Any? = (dictionary as NSDictionary).value(forKeyPath: remoteKeyInner ?? localKey)
                            self.hyp_setDictionaryValue(dictValue, forKey: localKey, attributeDescription: keyPathAttributeDescription)
                        }
                    }
                } else {
                    let localKey: String = attributeDescription.name
                    self.hyp_setDictionaryValue(value, forKey: localKey, attributeDescription: attributeDescription)
                }
            }
        }
    }
    
    func hyp_setDictionaryValue(_ value: Any?, forKey key: String, attributeDescription: NSAttributeDescription) {
        let valueExists: Bool = (value != nil && !(value is NSNull))
        if valueExists {
            let processedValue: Any? = self.valueForAttributeDescription(attributeDescription, usingRemoteValue: value as Any)
            
            let currentValue: Any? = self.value(forKey: key)
            if (currentValue as AnyObject).isEqual(processedValue) == false {
                self.setValue(processedValue, forKey: key)
            }
        } else if self.value(forKey: key) != nil {
            self.setValue(nil, forKey: key)
        }
    }
    
    func hyp_dictionary() -> [String: Any] {
        return self.hyp_dictionaryUsingInflectionType(.snakeCase)
    }
    
    func hyp_dictionaryUsingInflectionType(_ inflectionType: SyncPropertyMapperInflectionType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(self.defaultDateFormatter(),
                                                    parent: nil,
                                                    usingInflectionType: inflectionType,
                                                    andRelationshipType: .nested)
    }
    
    func hyp_dictionaryUsinginflectionType(_ inflectionType: SyncPropertyMapperInflectionType,
                                                   andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(self.defaultDateFormatter(),
                                                    parent: nil,
                                                    usingInflectionType: inflectionType,
                                                    andRelationshipType: relationshipType)
    }
    
    func hyp_dictionaryUsingRelationshipType(_ relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(self.defaultDateFormatter(),
                                                    usingRelationshipType: relationshipType)
    }
    
    func hyp_dictionaryUsingInflectionType(_ inflectionType: SyncPropertyMapperInflectionType,
                                                  andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(self.defaultDateFormatter(),
                                                    parent: nil,
                                                    usingInflectionType: inflectionType,
                                                    andRelationshipType: relationshipType)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                    parent: nil,
                                                    usingInflectionType: .snakeCase,
                                                    andRelationshipType: .nested)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter,
                                           usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                    parent: nil,
                                                    usingInflectionType: .snakeCase,
                                                    andRelationshipType: relationshipType)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter,
                                                  usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                    parent: nil,
                                                    usingInflectionType: inflectionType,
                                                    andRelationshipType: .nested)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter,
                                                  usingInflectionType inflectionType: SyncPropertyMapperInflectionType,
                                                  andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                    parent: nil,
                                                    usingInflectionType: inflectionType,
                                                    andRelationshipType: relationshipType)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter,
                                                  parent: NSManagedObject?) -> [String: Any] {
        return self.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                    parent: parent,
                                                    usingInflectionType: .snakeCase,
                                                    andRelationshipType: .nested)
    }
    
    func hyp_dictionaryWithDateFormatter(_ dateFormatter: DateFormatter,
                                                  parent: NSManagedObject?,
                                                  usingInflectionType inflectionType: SyncPropertyMapperInflectionType,
                                                  andRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> [String: Any] {
        let managedObjectAttributes = NSMutableDictionary()
        
        for propertyDescription in self.entity.properties {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                if attributeDescription.shouldExportAttribute() {
                    let value = self.valueForAttributeDescription(attributeDescription, dateFormatter: dateFormatter, relationshipType: relationshipType)
                    if let valueUnwrapped = value {
                        let remoteKey: String = self.remoteKeyForAttributeDescription(attributeDescription,
                                                                                       usingRelationshipType: relationshipType,
                                                                                       inflectionType: inflectionType)
                        var currentObj: NSMutableDictionary = managedObjectAttributes
                        let split: [String] = remoteKey.components(separatedBy: ".")
                        if split.count > 1 {
                            let components = split[0..<split.count-1]
                            for key in components {
                                var currentValue: Any? = currentObj[key]
                                if currentValue == nil {
                                    let newDict = NSMutableDictionary()
                                    currentObj.setObject(newDict, forKey: key as NSString)
                                    currentValue = newDict
                                }
                                if let dict = currentValue as? NSMutableDictionary {
                                    currentObj = dict
                                }
                            }
                        }
                        let lastKey: String = split.last ?? remoteKey
                        currentObj.setObject(valueUnwrapped, forKey: lastKey as NSString)
                    }
                }
            } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription,
                      relationshipType != .none {
                if relationshipDescription.shouldExportAttribute() {
                    let isValidRelationship: Bool = !(parent != nil &&
                        parent!.entity.isEqual(relationshipDescription.destinationEntity) &&
                        !relationshipDescription.isToMany)
                    if isValidRelationship {
                        let relationshipName: String = relationshipDescription.name
                        if let relationships = self.value(forKey: relationshipName) {
                            let isToOneRelationship: Bool = (!(relationships is NSSet) && !(relationships is NSOrderedSet))
                            if isToOneRelationship {
                                let attributesForToOneRelationship: [String: Any] = self.attributesForToOneRelationship(relationships as! NSManagedObject,
                                                                                                                             relationshipName: relationshipName,
                                                                                                                             usingRelationshipType: relationshipType,
                                                                                                                             parent: self,
                                                                                                                             dateFormatter: dateFormatter,
                                                                                                                             inflectionType: inflectionType)
                                managedObjectAttributes.addEntries(from: attributesForToOneRelationship)
                            } else {
                                let attributesForToManyRelationship: [String: Any] = self.attributesForToManyRelationship(relationships as! NSSet,
                                                                                                                               relationshipName: relationshipName,
                                                                                                                               usingRelationshipType: relationshipType,
                                                                                                                               parent: self,
                                                                                                                               dateFormatter: dateFormatter,
                                                                                                                               inflectionType: inflectionType)
                                managedObjectAttributes.addEntries(from: attributesForToManyRelationship)
                            }
                        }
                    }
                }
            }
        }
        
        return managedObjectAttributes.copy() as? [String: Any] ?? [:]
    }
    
    func attributesForToOneRelationship(_ relationship: NSManagedObject,
                                                 relationshipName: String,
                                                 usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType,
                                                 parent: NSManagedObject,
                                                 dateFormatter: DateFormatter,
                                                 inflectionType: SyncPropertyMapperInflectionType) -> [String: Any] {
        let attributesForToOneRelationship = NSMutableDictionary()
        let attributes: [String: Any] = relationship.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                                                     parent: parent,
                                                                                     usingInflectionType: inflectionType,
                                                                                     andRelationshipType: relationshipType)
        if attributes.count > 0 {
            var key: String = ""
            switch inflectionType {
            case .snakeCase:
                key = relationshipName.hyp_snakeCase()
            case .camelCase:
                key = relationshipName
            }
            if relationshipType == .nested {
                switch inflectionType {
                case .snakeCase:
                    key = "\(key)_\(PropertyMapperNestedAttributesKey)"
                case .camelCase:
                    key = "\(key)\(PropertyMapperNestedAttributesKey.capitalized)"
                }
            }
            attributesForToOneRelationship.setValue(attributes, forKey: key)
        }
        
        return attributesForToOneRelationship.copy() as? [String: Any] ?? [:]
    }
    
    func attributesForToManyRelationship(_ relationships: NSSet,
                                                  relationshipName: String,
                                                  usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType,
                                                  parent: NSManagedObject,
                                                  dateFormatter: DateFormatter,
                                                  inflectionType: SyncPropertyMapperInflectionType) -> [String: Any] {
        let attributesForToManyRelationship = NSMutableDictionary()
        var relationIndex: UInt = 0
        let relationsDictionary = NSMutableDictionary()
        let relationsArray = NSMutableArray()
        for case let relationship as NSManagedObject in relationships {
            let attributes: [String: Any] = relationship.hyp_dictionaryWithDateFormatter(dateFormatter,
                                                                                         parent: parent,
                                                                                         usingInflectionType: inflectionType,
                                                                                         andRelationshipType: relationshipType)
            if attributes.count > 0 {
                if relationshipType == .array {
                    relationsArray.add(attributes)
                } else if relationshipType == .nested {
                    let relationIndexString = "\(relationIndex)"
                    relationsDictionary.setValue(attributes, forKey: relationIndexString)
                    relationIndex += 1
                }
            }
        }
        
        var key: String = ""
        switch inflectionType {
        case .snakeCase:
            key = relationshipName.hyp_snakeCase()
        case .camelCase:
            key = relationshipName.hyp_camelCase()
        }
        if relationshipType == .array {
            attributesForToManyRelationship.setValue(relationsArray.copy(), forKey: key)
        } else if relationshipType == .nested {
            let nestedAttributesPrefix = "\(key)_\(PropertyMapperNestedAttributesKey)"
            attributesForToManyRelationship.setValue(relationsDictionary.copy(), forKey: nestedAttributesPrefix)
        }
        
        return attributesForToManyRelationship.copy() as? [String: Any] ?? [:]
    }
    
    // MARK: - Private
    
    func defaultDateFormatter() -> DateFormatter {
        struct Static {
            static let _dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                return formatter
            }()
        }
        return Static._dateFormatter
    }
}

// MARK: - NSRelationshipDescription Extension

extension NSRelationshipDescription {
    
    var isToMany: Bool {
        // Minimal dummy: assume if maxCount is not 1 then it is to-many.
        return self.maxCount != 1
    }
}
