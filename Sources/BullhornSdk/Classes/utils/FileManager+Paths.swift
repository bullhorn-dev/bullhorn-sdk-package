import Foundation

extension FileManager {

    func documentsDirectory() -> URL? {
        return directoryURL(for: .documentDirectory)
    }

    func libraryDirectory() -> URL? {
        return directoryURL(for: .libraryDirectory)
    }

    func cachesDirectory() -> URL? {
        return directoryURL(for: .cachesDirectory)
    }

    func urlForFileInDocuments(with fileName: String) -> URL? {
        return documentsDirectory()?.appendingPathComponent(fileName)
    }

    func urlForFileInCaches(with fileName: String) -> URL? {
        return cachesDirectory()?.appendingPathComponent(fileName)
    }

    func urlForFileToUpload(with fileName: String) -> URL? {

        guard let uploadDirectoryURL = cachesDirectory()?.appendingPathComponent("upload", isDirectory: true) else {
            BHLog.w("\(#function) - Cannot create 'upload' directory")
            return nil
        }

        let resultURL: URL?

        do {
            try FileManager.default.createDirectory(at: uploadDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            resultURL = uploadDirectoryURL.appendingPathComponent(fileName)
        }
        catch {
            BHLog.w("\(#function) - \(String.init(describing: error))")
            resultURL = nil
        }

        return resultURL
    }

    fileprivate func directoryURL(for type: SearchPathDirectory) -> URL? {

        let path = urls(for: type, in: .userDomainMask).first

        if path == nil {
            BHLog.w("\(#function) - URL for \(type) is nil")
        }

        return path
    }
}
