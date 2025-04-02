
import Foundation

protocol JsonApiDecodable: Decodable {

    var type: String { get }
    var id: String { get }
}

protocol JsonApiEncodable: Encodable {
    var type: String { get }
}

typealias JsonApiCodable = JsonApiDecodable & JsonApiEncodable

final class JsonApiEncoder {
    
    let jsonEncoder: JSONEncoder
    
    let options: JsonApiKit.Encoder.Options
    
    init(jsonEncoder: JSONEncoder = JSONEncoder(), options: JsonApiKit.Encoder.Options = .default) {
        self.jsonEncoder = jsonEncoder
        self.options = options
    }
    
    func encode<T>(_ value: T, additionalParams: Parameters? = nil) throws -> Parameters where T : Encodable {
        let data = try jsonEncoder.encode(value)
        return try JsonApiKit.Encoder.encode(data: data, additionalParams: additionalParams, options: options)
    }
}

final class JsonApiDecoder {
    
    let jsonDecoder: JSONDecoder
    
    let options: JsonApiKit.Decoder.Options
    
    init(jsonDecoder: JSONDecoder = JSONDecoder(), options: JsonApiKit.Decoder.Options = .default) {
        self.jsonDecoder = jsonDecoder
        self.options = options
    }
    
    func decode<T>(_ type: T.Type, from json: Parameters, includeList: String? = nil) throws -> T where T : Decodable {
        let data = try JsonApiKit.Decoder.data(withJSONAPIObject: json, includeList: includeList, options: options)
        return try jsonDecoder.decode(type, from: data)
    }
    
    public func decode<T>(_ type: T.Type, from data: Data, includeList: String? = nil) throws -> T where T : Decodable {
        let data = try JsonApiKit.Decoder.data(with: data, includeList: includeList, options: options)
        return try jsonDecoder.decode(type, from: data)
    }
}
