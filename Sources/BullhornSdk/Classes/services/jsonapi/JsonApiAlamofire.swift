
import Foundation
internal import Alamofire

enum JsonApiAlamofireError: Error {
    
    case invalidKeyPath(keyPath: String)
}

extension JsonApiAlamofireError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case let .invalidKeyPath(keyPath: keyPath):
            return "Nested JSON doesn't exist by keyPath: \(keyPath)."
        }
    }
}

extension DataRequest {

    @discardableResult
    func responseJSONAPI(
        queue: DispatchQueue = .main,
        includeList: String? = nil,
        options: JsonApiKit.Decoder.Options = .default,
        completionHandler: @escaping (AFDataResponse<Parameters>) -> Void
    ) -> Self {
        return response(
            queue: queue,
            responseSerializer: JSONAPIResponseSerializer(includeList: includeList, options: options),
            completionHandler: completionHandler
        )
    }
}

extension DownloadRequest {

    @discardableResult
    func responseJSONAPI(
        queue: DispatchQueue = .main,
        includeList: String? = nil,
        options: JsonApiKit.Decoder.Options = .default,
        completionHandler: @escaping (AFDownloadResponse<Parameters>) -> Void
    ) -> Self {
        return response(
            queue: queue,
            responseSerializer: JSONAPIResponseSerializer(includeList: includeList, options: options),
            completionHandler: completionHandler
        )
    }
}

final class JSONAPIResponseSerializer: ResponseSerializer {
    
    let includeList: String?
    let options: JsonApiKit.Decoder.Options

    init(includeList: String?, options: JsonApiKit.Decoder.Options) {

        self.includeList = includeList
        self.options = options
    }
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Parameters {
        guard error == nil else { throw error! }
        
        guard var data = data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            return [:]
        }
        
        data = try dataPreprocessor.preprocess(data)
        
        do {
            return try JsonApiKit.Decoder.jsonObject(with: data, includeList: includeList, options: options)
        } catch {
            throw AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
        }
    }
}
