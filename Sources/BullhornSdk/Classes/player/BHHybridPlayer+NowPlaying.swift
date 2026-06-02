import Foundation
import SDWebImage

/// Composes NowPlaying metadata and updates the media player.
extension BHHybridPlayer {

    internal func composeNowPlayingItemInfo(with image: UIImage? = nil) -> BHNowPlayingItemInfo {
        let playbackRate = isPlaying() ? mediaPlayer?.rate : 0
        let currentItemImage = image ?? mediaPlayer?.nowPlayingItemInfo.itemImage

        return BHNowPlayingItemInfo(
            title: playerItem?.post.title,
            audioTitle: playerItem?.post.userName,
            authorName: playerItem?.post.userName,
            duration: totalDuration(),
            elapsedTime: playerItem?.position,
            itemImage: currentItemImage,
            isLiveStream: playerItem?.isStream,
            rate: playbackRate)
    }

    internal func updateNowPlayingItemInfoImage() {
        guard let coverUrl = playerItem?.post.coverUrl else { return }

        SDWebImageDownloader.shared.downloadImage(with: coverUrl, options: .useNSURLCache, progress: nil) { (image, _, error, finished) in
            guard finished else { return }

            if let validError = error {
                BHLog.w("\(#function) - Failed to load image: \(validError)")
            }
            else if let validImage = image, coverUrl == self.playerItem?.post.coverUrl, let validPlayer = self.mediaPlayer {
                validPlayer.updateNowPlayingItemInfo(with: self.composeNowPlayingItemInfo(with: validImage))
            }
        }
    }
}
