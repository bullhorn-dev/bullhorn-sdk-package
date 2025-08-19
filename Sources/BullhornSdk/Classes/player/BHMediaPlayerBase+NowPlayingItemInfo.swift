
import AVFoundation
import Foundation
import MediaPlayer

extension BHMediaPlayerBase {
    
    func updateNowPlayingItemInfo(with itemInfo: BHNowPlayingItemInfo? = nil) {
        
        if let validItemInfo = itemInfo ?? delegate?.mediaPlayerDidRequestNowPlayingItemInfo(self) {
            nowPlayingItemInfo = validItemInfo
        }
        updateNowPlayingInfo()
    }

    func updateNowPlayingItemState(isInterrupted: Bool? = nil) {
        
        let wasInterrupted = nowPlayingItemPlaybackState == .interrupted
        let resultInterrupted = isInterrupted ?? wasInterrupted
            
        let newState: MPNowPlayingPlaybackState
            
        if resultInterrupted  {
            newState = .interrupted
        }
        else {
            switch state {
            case .idle, .waiting, .ready: newState = .unknown
            case .playing: newState = .playing
            case .paused: newState = .paused
            case .ended, .failed: newState = .stopped
            }
        }
            
        nowPlayingItemPlaybackState = newState
    }
    
    func updateNowPlayingInfo() {
        
        let info = composeNowPlayingItemInfoDictionary()
        setNowPlayingInfo(info)
    }
    
    internal func clearNowPlayingInfo() {
        setNowPlayingInfo(nil)
    }
    
    internal func setNowPlayingInfo(_ info: [String: Any]?) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    internal func composeNowPlayingItemInfoDictionary() -> [String : Any] {
        
        var info = [String: Any]()
        
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        
        if let validTitle = nowPlayingItemInfo.title {
            info[MPMediaItemPropertyTitle] = validTitle
        }
        if let validAuthorName = nowPlayingItemInfo.authorName {
            info[MPMediaItemPropertyArtist] = validAuthorName
        }
        if let isLiveStream = nowPlayingItemInfo.isLiveStream {
            info[MPNowPlayingInfoPropertyIsLiveStream] = isLiveStream
        }
        if let validImage = nowPlayingItemInfo.itemImage {
            let imageSize = CGSize(width: 200, height: 200)
            let albumArt = MPMediaItemArtwork(boundsSize: imageSize) { _ in validImage }
            info[MPMediaItemPropertyArtwork] = albumArt
        }
        
        let validElapsedTime = nowPlayingItemInfo.elapsedTime ?? currentTime()
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = validElapsedTime
        
        let validDuration = max(nowPlayingItemInfo.duration ?? 0, duration())
        info[MPMediaItemPropertyPlaybackDuration] = validDuration
        
        let validRate = Float(nowPlayingItemInfo.rate ?? 0)
        info[MPNowPlayingInfoPropertyPlaybackRate] = validRate
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = Constants.defaultPlaybackRate
        
        return info
    }
}
