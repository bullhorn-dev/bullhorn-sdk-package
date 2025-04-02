
import Foundation

typealias Parameters = [String: Any]

enum JsonApiError: Error {

    case cantProcess(data: Any)
    case notDictionary(data: Any, value: Any?)
    case notFoundTypeOrId(data: Any)
    case relationshipNotFound(data: Any)
    case unableToConvertNSDictionaryToParams(data: Any)
    case unableToConvertDataToJson(data: Any)
}

private struct Consts {
    
    struct APIKeys {

        static let data = "data"
        static let id = "id"
        static let type = "type"
        static let included = "included"
        static let relationships = "relationships"
        static let attributes = "attributes"
        static let meta = "meta"
    }
    
    struct General {
        static let dictCapacity = 20
    }
}

private struct TypeIdPair {

    let type: String
    let id: String
}

struct JsonApiKit {
    
    enum Decoder {}
    enum Encoder {}
}

extension JsonApiKit.Decoder {
    
    struct Options {
        
        public var parseNotIncludedRelationships: Bool = false

        public init(parseNotIncludedRelationships: Bool = false) {
            self.parseNotIncludedRelationships = parseNotIncludedRelationships
        }
    }
}

extension JsonApiKit.Decoder.Options {
    
    static var `default`: JsonApiKit.Decoder.Options { .init() }
}

extension JsonApiKit.Encoder {
    
    struct Options {
        
        public var includeMetaToCommonNamespce: Bool = false
        
        public var relationshipList: String?
        
        public init(includeMetaToCommonNamespce: Bool = false, relationshipList: String? = nil) {
            self.includeMetaToCommonNamespce = includeMetaToCommonNamespce
            self.relationshipList = relationshipList
        }
    }
}

extension JsonApiKit.Encoder.Options {
    
    static var `default`: JsonApiKit.Encoder.Options { .init() }
}

// MARK: - Decoding

extension JsonApiKit.Decoder {
    
    static func jsonObject(withJSONAPIObject object: Parameters, includeList: String? = nil, options: JsonApiKit.Decoder.Options = .default) throws -> Parameters {

        let decoded: Any

        if let includeList = includeList {
            decoded = try decode(jsonApiInput: object, include: includeList, options: options)
        } else {
            decoded = try decode(jsonApiInput: object as NSDictionary, options: options)
        }
        if let decodedProperties = decoded as? Parameters {
            return decodedProperties
        }
        throw JsonApiError.unableToConvertNSDictionaryToParams(data: decoded)
    }
    
    static func data(withJSONAPIObject object: Parameters, includeList: String? = nil, options: JsonApiKit.Decoder.Options = .default) throws -> Data {

        let decoded = try jsonObject(withJSONAPIObject: object, includeList: includeList, options: options)

        return try JSONSerialization.data(withJSONObject: decoded)
    }
    
    static func jsonObject(with data: Data, includeList: String? = nil, options: JsonApiKit.Decoder.Options = .default) throws -> Parameters {

        let jsonApiObject = try JSONSerialization.jsonObject(with: data)
        
        if let includeList = includeList {
            guard let json = jsonApiObject as? Parameters else {
                throw JsonApiError.unableToConvertDataToJson(data: data)
            }
            return try decode(jsonApiInput: json, include: includeList, options: options)
        }
        
        guard let json = jsonApiObject as? NSDictionary else {
            throw JsonApiError.unableToConvertDataToJson(data: data)
        }
        let decoded = try decode(jsonApiInput: json as NSDictionary, options: options)
        
        if let decodedProperties = decoded as? Parameters {
            return decodedProperties
        }
        throw JsonApiError.unableToConvertNSDictionaryToParams(data: decoded)
    }
    
    static func data(with data: Data, includeList: String? = nil, options: JsonApiKit.Decoder.Options = .default) throws -> Data {

        let decoded = try jsonObject(with: data, includeList: includeList, options: options)

        return try JSONSerialization.data(withJSONObject: decoded)
    }
}

// MARK: - Encoding

extension JsonApiKit.Encoder {
    
    static func encode(data: Data, additionalParams: Parameters? = nil, options: JsonApiKit.Encoder.Options = .default) throws -> Parameters {

        let json = try JSONSerialization.jsonObject(with: data)

        if let jsonObject = json as? Parameters {
            return try encode(json: jsonObject, additionalParams: additionalParams, options: options)
        }
        if let jsonArray = json as? [Parameters] {
            return try encode(json: jsonArray, additionalParams: additionalParams, options: options)
        }
        throw JsonApiError.unableToConvertDataToJson(data: json)
    }
    
    static func encode(json: Parameters, additionalParams: Parameters? = nil, options: JsonApiKit.Encoder.Options = .default) throws -> Parameters {

        var params = additionalParams ?? [:]

        params[Consts.APIKeys.data] = try encodeAttributesAndRelationships(on: json, options: options)
        return params
    }
    
    static func encode(json: [Parameters], additionalParams: Parameters? = nil, options: JsonApiKit.Encoder.Options = .default) throws -> Parameters {

        var params = additionalParams ?? [:]

        params[Consts.APIKeys.data] = try json.compactMap { try encodeAttributesAndRelationships(on: $0, options: options) as AnyObject }
        return params
    }
}

// MARK: - Private Decoding

private extension JsonApiKit.Decoder {
    
    static func decode(jsonApiInput: Parameters, include: String, options: JsonApiKit.Decoder.Options) throws -> Parameters {

        let params = include
            .split(separator: ",")
            .map { $0.split(separator: ".") }
        
        let paramsDict = NSMutableDictionary(capacity: Consts.General.dictCapacity)

        for lineArray in params {
            var dict: NSMutableDictionary = paramsDict
            for param in lineArray {
                if let newDict = dict[param] as? NSMutableDictionary {
                    dict = newDict
                } else {
                    let newDict = NSMutableDictionary(capacity: Consts.General.dictCapacity)
                    dict.setObject(newDict, forKey: param as NSCopying)
                    dict = newDict
                }
            }
        }
        
        let dataObjectsArray = try jsonApiInput.array(from: Consts.APIKeys.data) ?? []
        let includedObjectsArray = (try? jsonApiInput.array(from: Consts.APIKeys.included) ?? []) ?? []
        let allObjectsArray = dataObjectsArray + includedObjectsArray
        let allObjects = try allObjectsArray.reduce(into: [TypeIdPair: Parameters]()) { (result, object) in
            result[try object.extractTypeIdPair()] = object
        }
        
        let objects = try dataObjectsArray.map { (dataObject) -> Parameters in
            return try resolve(object: dataObject, allObjects: allObjects, paramsDict: paramsDict, options: options)
        }
        
        var jsonApi = jsonApiInput
        let isObject = jsonApiInput[Consts.APIKeys.data].map { $0 is Parameters } ?? false
        jsonApi[Consts.APIKeys.data] = (objects.count == 1 && isObject) ? objects[0] : objects
        jsonApi.removeValue(forKey: Consts.APIKeys.included)
        return jsonApi
    }
    
    static func decode(jsonApiInput: NSDictionary, options: JsonApiKit.Decoder.Options) throws -> NSDictionary {
        let jsonApi = jsonApiInput.mutable
        
        let dataObjectsArray = try jsonApi.array(from: Consts.APIKeys.data) ?? []
        let includedObjectsArray = (try? jsonApi.array(from: Consts.APIKeys.included) ?? []) ?? []
        
        var dataObjects = [TypeIdPair]()
        var objects = [TypeIdPair: NSMutableDictionary]()
        dataObjects.reserveCapacity(dataObjectsArray.count)
        objects.reserveCapacity(dataObjectsArray.count + includedObjectsArray.count)
        
        for dic in dataObjectsArray {
            let typeId = try dic.extractTypeIdPair()
            dataObjects.append(typeId)
            objects[typeId] = dic.mutable
        }
        for dic in includedObjectsArray {
            let typeId = try dic.extractTypeIdPair()
            objects[typeId] = dic.mutable
        }
        
        try resolveAttributes(from: objects)
        try resolveRelationships(from: objects, options: options)
        
        let isObject = jsonApiInput.object(forKey: Consts.APIKeys.data) is NSDictionary
        if isObject && dataObjects.count == 1 {
            jsonApi.setObject(objects[dataObjects[0]]!, forKey: Consts.APIKeys.data as NSCopying)
        } else {
            jsonApi.setObject(dataObjects.map { objects[$0]! }, forKey: Consts.APIKeys.data as NSCopying)
        }
        jsonApi.removeObject(forKey: Consts.APIKeys.included)
        return jsonApi
    }
}

// MARK: - Decoding helper functions

private extension JsonApiKit.Decoder {
 
    static func resolve(object: Parameters, allObjects: [TypeIdPair: Parameters], paramsDict: NSDictionary, options: JsonApiKit.Decoder.Options) throws -> Parameters {

        var attributes = (try? object.dictionary(for: Consts.APIKeys.attributes)) ?? Parameters()

        attributes[Consts.APIKeys.type] = object[Consts.APIKeys.type]
        attributes[Consts.APIKeys.id] = object[Consts.APIKeys.id]
        
        let relationshipsReferences = object.asDictionary(from: Consts.APIKeys.relationships) ?? Parameters()
        
        let extractRelationship = resolveRelationship(
            from: allObjects,
            parseNotIncludedRelationships: options.parseNotIncludedRelationships
        )
        
        let relationships = try paramsDict.allKeys.compactMap({ $0 as? String }).reduce(into: Parameters(), { (result, relationshipsKey) in
            guard let relationship = relationshipsReferences.asDictionary(from: relationshipsKey) else { return }
            guard let otherObjectsData = try relationship.array(from: Consts.APIKeys.data) else {
                result[relationshipsKey] = NSNull()
                return
            }
            let otherObjects = try otherObjectsData
                .map { try $0.extractTypeIdPair() }
                .compactMap(extractRelationship)
                .map { try resolve(
                        object: $0,
                        allObjects: allObjects,
                        paramsDict: try paramsDict.dictionary(for: relationshipsKey),
                        options: options
                    )
                }

            let isObject = relationship[Consts.APIKeys.data].map { $0 is Parameters } ?? false
            if isObject {
                result[relationshipsKey] = (otherObjects.count == 1) ? otherObjects[0] : NSNull()
            } else {
                result[relationshipsKey] = otherObjects
            }
        })
        
        if options.parseNotIncludedRelationships {
            return try attributes.merging(appendAdditionalReferences(from: relationshipsReferences, to: relationships)) { $1 }
        } else {
            return attributes.merging(relationships) { $1 }
        }
    }
    
    static func appendAdditionalReferences(from relationshipsReferences: Parameters, to relationships: Parameters) throws -> Parameters {
        let additionlReferences = try relationshipsReferences.reduce(into: Parameters()) { (result, relationship) in
            guard let relationshipParams = relationship.value as? Parameters else {
                throw JsonApiError.relationshipNotFound(data: relationship)
            }
            result[relationship.key] = relationshipParams[Consts.APIKeys.data]
        }
        return additionlReferences.merging(relationships) { $1 }
    }
    
    static func resolveAttributes(from objects: [TypeIdPair: NSMutableDictionary]) throws {
        objects.values.forEach { (object) in
            let attributes = try? object.dictionary(for: Consts.APIKeys.attributes)
            attributes?.forEach { object[$0] = $1 }
            object.removeObject(forKey: Consts.APIKeys.attributes)
        }
    }
    
    static func resolveRelationships(from objects: [TypeIdPair: NSMutableDictionary], options: JsonApiKit.Decoder.Options) throws {
        
        let extractRelationship = resolveRelationship(
            from: objects,
            parseNotIncludedRelationships: options.parseNotIncludedRelationships
        )
        
        try objects.values.forEach { (object) in
            
            try object.dictionary(for: Consts.APIKeys.relationships, defaultDict: NSDictionary()).forEach { (relationship) in
                
                guard let relationshipParams = relationship.value as? NSDictionary else {
                    throw JsonApiError.relationshipNotFound(data: relationship)
                }
                
                // Extract type-id pair from single object / array
                guard let others = try relationshipParams.array(from: Consts.APIKeys.data) else {
                    object.setObject(NSNull(), forKey: relationship.key as! NSCopying)
                    return
                }
                
                // Fetch those object from `objects`
                let othersObjects = try others
                    .map { try $0.extractTypeIdPair() }
                    .compactMap(extractRelationship)
                
                // Store relationships
                let isObject = relationshipParams
                    .object(forKey: Consts.APIKeys.data)
                    .map { $0 is NSDictionary } ?? false
                
                if others.count == 1 && isObject {
                    object.setObject(othersObjects.first as Any, forKey: relationship.key as! NSCopying)
                } else {
                    object.setObject(othersObjects, forKey: relationship.key as! NSCopying)
                }
            }
            object.removeObject(forKey: Consts.APIKeys.relationships)
        }
    }

    static func resolveRelationship(
        from objects: [TypeIdPair: Parameters],
        parseNotIncludedRelationships: Bool
    ) -> ((TypeIdPair) -> Parameters?) {
        if parseNotIncludedRelationships {
            return { objects[$0] ?? $0.asDictionary }
        } else {
            return { objects[$0] }
        }
    }
    
    static func resolveRelationship(
        from objects: [TypeIdPair: NSMutableDictionary],
        parseNotIncludedRelationships: Bool
    ) -> ((TypeIdPair) -> NSMutableDictionary?) {
        if parseNotIncludedRelationships {
            return { objects[$0] ?? $0.asNSDictionary.mutable }
        } else {
            return { objects[$0] }
        }
    }

}

// MARK: - Encoding

private extension JsonApiKit.Encoder {
    
    static func encodeAttributesAndRelationships(on jsonObject: Parameters, options: JsonApiKit.Encoder.Options) throws -> Parameters {

        var object = jsonObject
        var attributes = Parameters()
        var relationships = Parameters()
        let objectKeys = object.keys
        
        let relationshipExtractor = extractRelationshipData(
            includeMetaToCommonNamespce: options.includeMetaToCommonNamespce
        )
        
        let isRelationship = testIsRelationship(relationshipList: options.relationshipList)
        
        for key in objectKeys where key != Consts.APIKeys.type && key != Consts.APIKeys.id {
            
            if options.includeMetaToCommonNamespce && key == Consts.APIKeys.meta {
                continue
            }
            
            if let array = object.asArray(from: key) {
                
                let isArrayOfRelationships = try isRelationship((key: key, object: array.first))
                if !isArrayOfRelationships {
                    attributes[key] = array
                    object.removeValue(forKey: key)
                    continue
                }
                let dataArray = try array.map(relationshipExtractor)
                relationships[key] = [Consts.APIKeys.data: dataArray]
                object.removeValue(forKey: key)
                continue
            }
            if let obj = object.asDictionary(from: key) {
                if try !isRelationship((key: key, object: obj)) {
                    attributes[key] = obj
                    object.removeValue(forKey: key)
                    continue
                }
                let dataObj = try relationshipExtractor(obj)
                relationships[key] = [Consts.APIKeys.data: dataObj]
                object.removeValue(forKey: key)
                continue
            }
            attributes[key] = object[key]
            object.removeValue(forKey: key)
        }
        object[Consts.APIKeys.attributes] = attributes
        object[Consts.APIKeys.relationships] = relationships
        return object
    }
    
    typealias KeyObjectPair = (key: String, object: Parameters?)
    static func testIsRelationship(relationshipList: String?) -> (KeyObjectPair) throws -> Bool {
        guard let relationshipList = relationshipList else {
            return { $0.object?.containsTypeAndId() ?? false }
        }
        let list = relationshipList
            .components(separatedBy: ",")
            .compactMap { $0.components(separatedBy: ".").first }
        return {
            switch (list.contains($0.key), $0.object?.containsTypeAndId()) {
            case (let containsInList, nil):
                return containsInList
            case (true, true?): return true
            case (true, false?): throw JsonApiError.notFoundTypeOrId(data: $0.object!)
            case (false, _?): return false
            }
        }
    }
    
    static func extractRelationshipData(includeMetaToCommonNamespce: Bool) -> (Parameters) throws -> (Any) {
        if !includeMetaToCommonNamespce {
            return { try $0.asDataWithTypeAndId() }
        }
        return { object in
            var params = try object.asDataWithTypeAndId()
            if let meta = object[Consts.APIKeys.meta] {
                params[Consts.APIKeys.meta] = meta
            }
            return params
        }
    }
}

// MARK: - General helper extensions

extension TypeIdPair: Hashable, Equatable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(id)
    }

    static func == (lhs: TypeIdPair, rhs: TypeIdPair) -> Bool {
        return lhs.type == rhs.type && lhs.id == rhs.id
    }
}

extension TypeIdPair {

    var asNSDictionary: NSDictionary {
        return asDictionary as NSDictionary
    }
    
    var asDictionary: Parameters {
        return [
            Consts.APIKeys.type: type,
            Consts.APIKeys.id: id
        ]
    }

}

private extension Dictionary where Key == String {
    
    func containsTypeAndId() -> Bool {
        return keys.contains(Consts.APIKeys.type) && keys.contains(Consts.APIKeys.id)
    }
    
    func asDataWithTypeAndId() throws -> Parameters {
        guard let type = self[Consts.APIKeys.type], let id = self[Consts.APIKeys.id] else {
            throw JsonApiError.notFoundTypeOrId(data: self)
        }
        return [Consts.APIKeys.type: type, Consts.APIKeys.id: id]
    }
    
    func extractTypeIdPair() throws -> TypeIdPair {
        if let id = self[Consts.APIKeys.id] as? String, let type = self[Consts.APIKeys.type] as? String {
            return TypeIdPair(type: type, id: id)
        }
        throw JsonApiError.notFoundTypeOrId(data: self)
    }
    
    func asDictionary(from key: String) -> Parameters? {
        return self[key] as? Parameters
    }
    
    func dictionary(for key: String) throws -> Parameters {
        if let value = self[key] as? Parameters {
            return value
        }
        throw JsonApiError.notDictionary(data: self, value: self[key])
    }
    
    func asArray(from key: String) -> [Parameters]? {
        return self[key] as? [Parameters]
    }
    
    func array(from key: String) throws -> [Parameters]? {

        let value = self[key]

        if let array = value as? [Parameters] {
            return array
        }
        if let dict = value as? Parameters {
            return [dict]
        }
        if value == nil || value is NSNull {
            return nil
        }
        throw JsonApiError.cantProcess(data: self)
    }
}

private extension NSDictionary {
    
    var mutable: NSMutableDictionary {
        if #available(iOS 10.0, *) {
            return self as? NSMutableDictionary ?? self.mutableCopy() as! NSMutableDictionary
        } else {
            return self.mutableCopy() as! NSMutableDictionary
        }
    }
    
    func extractTypeIdPair() throws -> TypeIdPair {
        if let id = self.object(forKey: Consts.APIKeys.id) as? String, let type = self.object(forKey: Consts.APIKeys.type) as? String {
            return TypeIdPair(type: type, id: id)
        }
        throw JsonApiError.notFoundTypeOrId(data: self)
    }
    
    func dictionary(for key: String, defaultDict: NSDictionary) -> NSDictionary {
        return (self.object(forKey: key) as? NSDictionary) ?? defaultDict
    }
    
    func dictionary(for key: String) throws -> NSDictionary {
        if let value = self.object(forKey: key) as? NSDictionary {
            return value
        }
        throw JsonApiError.notDictionary(data: self, value: self[key])
    }
    
    func array(from key: String) throws -> [NSDictionary]? {
        let value = self.object(forKey: key)
        if let array = value as? [NSDictionary] {
            return array
        }
        if let dict = value as? NSDictionary {
            return [dict]
        }
        if value == nil || value is NSNull {
            return nil
        }
        throw JsonApiError.cantProcess(data: self)
    }
}
