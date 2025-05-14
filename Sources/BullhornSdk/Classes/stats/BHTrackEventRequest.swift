
import Foundation

// MARK: - Category

enum BHTrackCategory: String, Codable {
    case initiation /// events generated during startup (specifically starting a new session)
    case account /// everything related with account (register, login logout)
    case explore /// everything about podcasts and episodes
    case player /// everything about recordings playback
    case interactive /// everything related to user
    case live /// everything related to live episodes
    case carplay /// everything related to carPlay
}

// MARK: - Action

enum BHTrackAction: String, Codable {
    case sessionGen = "session_gen"
    case error = "error"
    case ui = "ui"
}

// MARK: - Banner

enum BHTrackBanner: String, Codable {
    /// ui-account
    case login             = "log_in"
    case logout            = "log_out"
    /// ui-interactive
    case openHome          = "open_home"
    case opennSearch       = "open_search"
    case openRadio         = "open_radio"
    case openAccount       = "open_account"
    case openFavorites     = "open_favorites"
    case openNotifications = "open_notifications"
    case openDownloads     = "open_downloads"
    case openRecent        = "open_recent"
    /// ui-explore
    case openPodcast       = "open_podcast"
    case openEpisode       = "open_episode"
    case sharePodcast      = "share_podcast"
    case shareEpisode      = "share_episode"
    case notificationsOn   = "podcast_notifications_on"
    case notificationsOff  = "podcast_notifications_off"
    case downloadEpisode   = "download_episode"
    case episodeLikeOn     = "episode_like_on"
    case episodeLikeOff    = "episode_like_off"
    /// ui-player
    case playerOpen        = "player_open"
    case playerPlay        = "player_play"
    case playerPause       = "player_pause"
    case playerSeek        = "player_seek"
    case playerClose       = "player_close"
    case playerSleepTimer  = "player_sleep_timer"
    case playerSpeed       = "player_playback_speed"
    case playerPlayback    = "player_playback"
    /// ui-carplay
    case carplayConnect    = "carplay_connect"
    case carplayDisconnect = "carplay_disconnect"
    case carplayOpenHome   = "carplay_open_home"
    case carplayOpenRadio  = "carplay_open_radio"
    case carplayOpenDownloads = "carplay_open_downloads"
    /// error-explore
    case playerFailed      = "player_failed"
    case downloadFailed    = "download_failed"
    case contentLoadFailed = "content_load_failed"
    case storageFailed     = "storage_operation_failed"
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
