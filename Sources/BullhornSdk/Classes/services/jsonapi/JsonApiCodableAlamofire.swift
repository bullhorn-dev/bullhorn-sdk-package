
import Foundation
internal import Alamofire

extension DataRequest {
    
    @discardableResult
    func responseCodableJSONAPI<T: Decodable>(queue: DispatchQueue = .main, includeList: String? = nil, keyPath: String? = nil, decoder: JsonApiDecoder = JsonApiDecoder(), completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        return response(
            queue: queue,
            responseSerializer: DecodableJSONAPIResponseSerializer(includeList: includeList, keyPath: keyPath, decoder: decoder),
            completionHandler: completionHandler
        )
    }
}

extension DownloadRequest {

    @discardableResult
    func responseCodableJSONAPI<T: Decodable>(queue: DispatchQueue = .main, includeList: String? = nil, keyPath: String? = nil, decoder: JsonApiDecoder = JsonApiDecoder(), completionHandler: @escaping (AFDownloadResponse<T>) -> Void) -> Self {
        return response(
            queue: queue,
            responseSerializer: DecodableJSONAPIResponseSerializer(includeList: includeList, keyPath: keyPath, decoder: decoder),
            completionHandler: completionHandler
        )
    }
}

final class DecodableJSONAPIResponseSerializer<T: Decodable>: ResponseSerializer {
    
    let includeList: String?
    let keyPath: String?
    let decoder: JsonApiDecoder

    init(includeList: String?, keyPath: String?, decoder: JsonApiDecoder) {

        self.includeList = includeList
        self.keyPath = keyPath
        self.decoder = decoder
    }

    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        guard error == nil else { throw error! }
        
        guard let validData = data, validData.count > 0 else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        do {
            guard let keyPath = keyPath, !keyPath.isEmpty else  {
                return try decoder.decode(T.self, from: validData, includeList: includeList)
            }
            
            let json = try JsonApiKit.Decoder.jsonObject(with: validData, includeList: includeList, options: decoder.options)
            guard let jsonForKeyPath = (json as AnyObject).value(forKeyPath: keyPath) else {
                throw JsonApiAlamofireError.invalidKeyPath(keyPath: keyPath)
            }
            let data = try JSONSerialization.data(withJSONObject: jsonForKeyPath, options: .init(rawValue: 0))
            
            return try decoder.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
        }
    }
}
