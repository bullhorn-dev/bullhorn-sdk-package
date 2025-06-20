
import Foundation

extension FileManager {
    
    func writeJsonArray(array: [Any], forKey key: String, toFile file: URL) {
        DispatchQueue.global(qos: .userInteractive).async {
            
            do {
                let jsonObject: [String: Any] = [key: Array(array)]
                
                let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
                try data.write(to: file, options: [])
            }
            catch {
                BHLog.w("\(#function) - Failed to write \(key) to file \(file): \(error)")
            }
        }
    }
    
    func readJsonArray(fromFile file: URL, forKey key: String, completion: @escaping ([[String : Any]]) -> Void) {
        
        var result: [[String : Any]] = Array()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            do {
                let data = try Data(contentsOf: file, options: [])
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                
                if let validJsonObj = jsonObj,
                   let jsonArray = validJsonObj[key] as? [[String : Any]] {
                    result = jsonArray
                } else {
                    BHLog.w("\(#function) - failed to read \(key) array from file \(file).")
                }
                
                try FileManager.default.removeItem(at: file)
            }
            catch {
//                BHLog.w("\(#function) - Failed to read data from file \(file): \(error)")
            }
            
            DispatchQueue.main.sync { completion(result) }
        }
    }
}
