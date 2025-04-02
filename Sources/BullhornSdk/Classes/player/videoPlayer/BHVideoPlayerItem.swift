
import Foundation
import AVFoundation

class BHVideoPlayerResource {

    let name: String
    let cover: URL?
    let definitions: [BHVideoPlayerResourceDefinition]
    
    convenience init(url: URL, name: String = "", cover: URL? = nil, subtitle: URL? = nil) {
        let definition = BHVideoPlayerResourceDefinition(url: url, definition: "")
                
        self.init(name: name, definitions: [definition], cover: cover)
    }
    
    init(name: String = "", definitions: [BHVideoPlayerResourceDefinition], cover: URL? = nil) {
        self.name        = name
        self.cover       = cover
        self.definitions = definitions
    }
}


class BHVideoPlayerResourceDefinition {

    let url: URL
    let definition: String
    
    var options: [String : Any]?
    
    var avURLAsset: AVURLAsset {
        get {
            guard !url.isFileURL, url.pathExtension != "m3u8" else {
                return AVURLAsset(url: url)
            }
            return BHVideoPlayerManager.asset(for: self)
        }
    }
    
    init(url: URL, definition: String, options: [String : Any]? = nil) {
        self.url        = url
        self.definition = definition
        self.options    = options
    }
}
