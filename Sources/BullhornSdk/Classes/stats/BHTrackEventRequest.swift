
import Foundation

// MARK: - Category

enum BHTrackCategory: String, Codable {
    case initiation
    case account
    case explore
    case player
    case interactive
    case live
}

// MARK: - Action

enum BHTrackAction: String, Codable {
    case sessionGen = "session_gen"
    case error = "error"
    case ui = "ui"
}

// MARK: - Banner

enum BHTrackBanner: String, Codable {
    //ui
    case openPlayer        = "open_player"
    case openPodcast       = "open_podcast"
    case openEpisode       = "open_episode"
    case openRadio         = "open_radio"
    case openFavorites     = "open_favorites"
    case openDownloads     = "open_downloads"
    case openRecent        = "open_recent"
    case sharePodcast      = "share_podcast"
    case shareEpisode      = "share_episode"
    case downloadEpisode   = "download_episode"
    case likeEpisode       = "like_episode"
    case dislikeEpisode    = "dislike_episode"
    case connectCarPlay    = "connect_carplay"
    //error
    case playerFailed      = "player_failed"
    case downloadFailed    = "download_failed"
    case contentLoadFailed = "content_load_failed"
    case storageFailed     = "storage_operation_failed"
    //player
    case playerPlay        = "player_play"
    case playerPause       = "player_pause"
    case playerSeek        = "player_seek"
    case playerClose       = "player_close"
    case playerSleepTimer  = "player_sleep_timer"
    case playerSpeed       = "player_playback_speed"
}

// MARK: - Keys

enum BHTrackKeys: String, Codable {
    case banner
    case context
    case variant
    case podcastId = "podcast_id"
    case podcastTitle = "podcast_title"
    case episodeId = "episode_id"
    case episodeTitle = "episode_title"
}

// MARK: - Event Request

struct BHTrackEventRequest: Codable {

    enum CodingKeys: String, CodingKey {
        case category
        case action
        case banner
        case context
        case variant
        case extraParams = "extra_params"
        case podcastId = "podcast_id"
        case podcastTitle = "podcast_title"
        case episodeId = "episode_id"
        case episodeTitle = "episode_title"
        case episodeType = "episode_type"
    }

    let category: BHTrackCategory
    let action: BHTrackAction
    let banner: BHTrackBanner?
    let context: String?
    let variant: String?
    let podcastId: String?
    let podcastTitle: String?
    let episodeId: String?
    let episodeTitle: String?
    let episodeType: String?
    let extraParams: [String : String]?
    
    static func createRequest(category: BHTrackCategory, action: BHTrackAction, banner: BHTrackBanner? = nil, context: String? = nil, variant: String? = nil, podcastId: String? = nil, podcastTitle: String? = nil, episodeId: String? = nil, episodeTitle: String? = nil, episodeType: String? = nil, extraParams: [String : String]? = [:]) -> BHTrackEventRequest {

        return BHTrackEventRequest(category: category, action: action, banner: banner, context: context, variant: variant, podcastId: podcastId, podcastTitle: podcastTitle, episodeId: episodeId, episodeTitle: episodeTitle, episodeType: episodeType, extraParams: extraParams)
    }
}
