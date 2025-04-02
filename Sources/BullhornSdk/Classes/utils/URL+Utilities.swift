
import Foundation

extension URL {

    var baseURL: URL {

        var resultURL = self
        while resultURL.lastPathComponent != "/" {
            resultURL.deleteLastPathComponent()
        }

        return resultURL
    }

    var pathComponentsWithoutDelimiters: [String] {
        return pathComponents.filter { $0 != "/" }
    }
    
    public var queryParameters: [String: String] {
        
        var parameters = [String: String]()
        
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return parameters
        }
        
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        return parameters
    }
}

extension URL {
    
    var key: String {
        get {
            return "audio_\(self.absoluteString.hashed)"
        }
    }
}

fileprivate extension String {
 
    var hashed: UInt64 {
        get {
            var result = UInt64 (8742)
            let buf = [UInt8](self.utf8)
            for b in buf {
                result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
            }
            return result
        }
    }
}
