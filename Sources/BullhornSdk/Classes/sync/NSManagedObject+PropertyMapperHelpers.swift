import Foundation
import CoreData

private let PropertyMapperDestroyKey: String = "destroy"

// MARK: - NSManagedObject Extension (PropertyMapperHelpers)

extension NSManagedObject {
    
    func valueForAttributeDescription(_ attributeDescription: NSAttributeDescription,
                                      dateFormatter: DateFormatter,
                                      relationshipType: SyncPropertyMapperRelationshipType) -> Any? {
        var value: Any?
        if attributeDescription.attributeType != NSAttributeType.transformableAttributeType {
            value = self.value(forKey: attributeDescription.name)
            let nilOrNullValue: Bool = (value == nil || (value is NSNull))
            let customTransformerName: String? = attributeDescription.customTransformerName()
            if nilOrNullValue {
                value = NSNull()
            } else if value is Date {
                value = dateFormatter.string(from: value as! Date)
            } else if value is UUID {
                value = (value as! UUID).uuidString
            } else if value is URL {
                value = (value as! URL).absoluteString
            } else if let customTransformerName = customTransformerName {
                if let transformer = ValueTransformer(forName: NSValueTransformerName(customTransformerName)) {
                    value = transformer.reverseTransformedValue(value)
                }
            }
        }
        
        return value
    }
    
    func attributeDescriptionForRemoteKey(_ remoteKey: String) -> NSAttributeDescription? {
        return self.attributeDescriptionForRemoteKey(remoteKey, usingInflectionType: .snakeCase)
    }
    
    func attributeDescriptionForRemoteKey(_ remoteKey: String,
                                          usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> NSAttributeDescription? {
        var foundAttributeDescription: NSAttributeDescription?
        
        let properties = self.entity.properties

        for propertyDescription in properties {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                
                let customRemoteKey = self.entity.propertiesByName[attributeDescription.name]?.customKey()
                let currentAttributeHasTheSameRemoteKey = (customRemoteKey?.count ?? 0 > 0 && customRemoteKey == remoteKey)
                if currentAttributeHasTheSameRemoteKey {
                    foundAttributeDescription = attributeDescription
                    break
                }
                
                let customRootRemoteKey = customRemoteKey?.components(separatedBy: ".").first
                let currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey?.count ?? 0 > 0 && customRootRemoteKey == remoteKey)
                if currentAttributeHasTheSameRootRemoteKey {
                    foundAttributeDescription = attributeDescription
                    break
                }
                
                if attributeDescription.name == remoteKey {
                    foundAttributeDescription = attributeDescription
                    break
                }
                
                var localKey = remoteKey.hyp_camelCase()
                let isReservedKey = NSManagedObject.reservedAttributes().contains(remoteKey)
                if isReservedKey {
                    let prefixedRemoteKey = self.prefixedAttribute(remoteKey, usingInflectionType: inflectionType)
                    localKey = prefixedRemoteKey.hyp_camelCase()
                }
                
                if attributeDescription.name == localKey {
                    foundAttributeDescription = attributeDescription
                    break
                }
            }
        }
        
        if foundAttributeDescription == nil {
            if let properties = self.entity.properties as? [NSPropertyDescription] {
                for propertyDescription in properties {
                    if let attributeDescription = propertyDescription as? NSAttributeDescription {
                        if remoteKey == SyncDefaultRemotePrimaryKey &&
                           (attributeDescription.name == SyncDefaultLocalPrimaryKey || attributeDescription.name == SyncDefaultLocalCompatiblePrimaryKey) {
                            foundAttributeDescription = self.entity.propertiesByName[attributeDescription.name] as? NSAttributeDescription
                        }
                        
                        if foundAttributeDescription != nil {
                            break
                        }
                    }
                }
            }
        }
        
        return foundAttributeDescription
    }
    
    func attributeDescriptionsForRemoteKeyPath(_ remoteKey: String) -> [NSAttributeDescription] {
        let foundAttributeDescriptions = NSMutableArray()
        
        if let properties = self.entity.properties as? [NSPropertyDescription] {
            for propertyDescription in properties {
                if let attributeDescription = propertyDescription as? NSAttributeDescription {
                    let customRemoteKeyPath = self.entity.propertiesByName[attributeDescription.name]?.customKey()
                    let customRootRemoteKey = customRemoteKeyPath?.components(separatedBy: ".").first
                    let rootRemoteKey = remoteKey.components(separatedBy: ".").first
                    let currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey?.count ?? 0 > 0 && customRootRemoteKey == rootRemoteKey)
                    if currentAttributeHasTheSameRootRemoteKey {
                        foundAttributeDescriptions.add(attributeDescription)
                    }
                }
            }
        }
        
        return foundAttributeDescriptions as? [NSAttributeDescription] ?? []
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription,
                                                       usingRelationshipType: .nested,
                                                       inflectionType: .snakeCase)
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription,
                                          inflectionType: SyncPropertyMapperInflectionType) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription,
                                                       usingRelationshipType: .nested,
                                                       inflectionType: inflectionType)
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription,
                                          usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType) -> String {
        return self.remoteKeyForAttributeDescription(attributeDescription,
                                                       usingRelationshipType: relationshipType,
                                                       inflectionType: .snakeCase)
    }
    
    func remoteKeyForAttributeDescription(_ attributeDescription: NSAttributeDescription,
                                          usingRelationshipType relationshipType: SyncPropertyMapperRelationshipType,
                                          inflectionType: SyncPropertyMapperInflectionType) -> String {
        let localKey = attributeDescription.name
        var remoteKey: String
        
        if let customRemoteKey = attributeDescription.customKey() {
            remoteKey = customRemoteKey
        } else if localKey == SyncDefaultLocalPrimaryKey || localKey == SyncDefaultLocalCompatiblePrimaryKey {
            remoteKey = SyncDefaultRemotePrimaryKey
        } else if localKey == PropertyMapperDestroyKey &&
                    relationshipType == .nested {
            remoteKey = "_\(PropertyMapperDestroyKey)"
        } else {
            switch inflectionType {
            case .snakeCase:
                remoteKey = localKey.hyp_snakeCase()
            case .camelCase:
                remoteKey = localKey
            }
        }
        
        let isReservedKey = self.reservedKeys(usingInflectionType: inflectionType).contains(remoteKey)
        if isReservedKey {
            var prefixedKey = remoteKey
            prefixedKey = prefixedKey.replacingOccurrences(of: self.remotePrefix(usingInflectionType: inflectionType),
                                                            with: "",
                                                            options: [.caseInsensitive],
                                                            range: prefixedKey.startIndex..<prefixedKey.endIndex)
            remoteKey = prefixedKey

            if inflectionType == .camelCase {
                remoteKey = remoteKey.hyp_camelCase()
            }
        }
        
        return remoteKey
    }
    
    func valueForAttributeDescription(_ attributeDescription: NSAttributeDescription,
                                      usingRemoteValue remoteValue: Any?) -> Any? {
        var value: Any?
        
        let attributedClass: AnyClass? = NSClassFromString(attributeDescription.attributeValueClassName ?? "")
        
        if let attributedClass = attributedClass,
           let remoteValueUnwrapped = remoteValue as? AnyObject,
           remoteValueUnwrapped.isKind(of: attributedClass) {
            value = remoteValue
        }
        
        let customTransformerName: String? = attributeDescription.customTransformerName()
        if let customTransformerName = customTransformerName {
            if let transformer = ValueTransformer(forName: NSValueTransformerName(customTransformerName)) {
                value = transformer.transformedValue(remoteValue)
            }
        }
        
        let stringValueAndNumberAttribute = (remoteValue is String && attributedClass == NSNumber.self)
        let numberValueAndStringAttribute = (remoteValue is NSNumber && attributedClass == NSString.self)
        let stringValueAndDateAttribute = (remoteValue is String && attributedClass == NSDate.self)
        let numberValueAndDateAttribute = (remoteValue is NSNumber && attributedClass == NSDate.self)
        let stringValueAndUUIDAttribute = (remoteValue is String && attributedClass == NSUUID.self)
        let stringValueAndURIAttribute = (remoteValue is String && attributedClass == NSURL.self)
        let dataAttribute = (attributedClass == NSData.self)
        let numberValueAndDecimalAttribute = (remoteValue is NSNumber && attributedClass == NSDecimalNumber.self)
        let stringValueAndDecimalAttribute = (remoteValue is String && attributedClass == NSDecimalNumber.self)
        let transformableAttribute = (attributedClass == nil && attributeDescription.valueTransformerName != nil && value == nil)
        
        if stringValueAndNumberAttribute {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US")
            value = formatter.number(from: remoteValue as! String)
        } else if numberValueAndStringAttribute {
            value = "\(remoteValue!)"
        } else if stringValueAndDateAttribute {
            value = NSDate.dateFromDateString(remoteValue as! NSString)
        } else if numberValueAndDateAttribute {
            value = NSDate.dateFromUnixTimestampNumber(remoteValue as! NSNumber)
        } else if stringValueAndUUIDAttribute {
            value = UUID(uuidString: remoteValue as! String)
        } else if stringValueAndURIAttribute {
            value = URL(string: remoteValue as! String)
        } else if dataAttribute {
            value = try? NSKeyedArchiver.archivedData(withRootObject: remoteValue as Any, requiringSecureCoding: false)
        } else if numberValueAndDecimalAttribute {
            if let number = remoteValue as? NSNumber {
                value = NSDecimalNumber(decimal: number.decimalValue)
            }
        } else if stringValueAndDecimalAttribute {
            value = NSDecimalNumber(string: remoteValue as? String)
        } else if transformableAttribute {
            if let transformer = ValueTransformer(forName: NSValueTransformerName(attributeDescription.valueTransformerName!)) {
                if let newValue = transformer.transformedValue(remoteValue) {
                    value = newValue
                }
            }
        }
        
        return value
    }
    
    func remotePrefix(usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> String {
        switch inflectionType {
        case .snakeCase:
            return "\(self.entity.name?.hyp_snakeCase() ?? "")_"
        case .camelCase:
            return self.entity.name?.hyp_camelCase() ?? ""
        }
    }
    
    func prefixedAttribute(_ attribute: String, usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> String {
        let remotePrefix = self.remotePrefix(usingInflectionType: inflectionType)
        
        switch inflectionType {
        case .snakeCase:
            return "\(remotePrefix)\(attribute)"
        case .camelCase:
            return "\(remotePrefix)\(attribute.capitalized)"
        }
    }
    
    func reservedKeys(usingInflectionType inflectionType: SyncPropertyMapperInflectionType) -> [String] {
        var keys = [String]()
        let reservedAttributes = NSManagedObject.reservedAttributes()
        
        for attribute in reservedAttributes {
            keys.append(self.prefixedAttribute(attribute, usingInflectionType: inflectionType))
        }
        
        return keys
    }

    // MARK:

    class func reservedAttributes() -> [String] {
        return ["type", "description", "signed"]
    }
}

