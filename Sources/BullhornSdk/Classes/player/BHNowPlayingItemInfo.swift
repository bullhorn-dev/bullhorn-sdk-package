
import Foundation
import UIKit

struct BHNowPlayingItemInfo: Equatable {
    
    let title: String?
    let audioTitle: String?
    let authorName: String?
    let duration: TimeInterval?
    let elapsedTime: TimeInterval?
    let itemImage: UIImage?
    let isLiveStream: Bool?
    let rate: Float?
    
    static let invalid = BHNowPlayingItemInfo.init(title: nil, audioTitle: nil, authorName: nil, duration: nil, elapsedTime: nil, itemImage: nil, isLiveStream: nil, rate: nil)
}
