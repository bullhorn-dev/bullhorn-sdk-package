
import UIKit
import Foundation

protocol BHChannelHeaderViewDelegate: AnyObject {
    func headerView(_ view: BHChannelHeaderView, didSelectUser user: BHUser)
}

class BHChannelHeaderView: UITableViewHeaderFooterView {
        
    class var reusableIndentifer: String { return String(describing: self) }
    
    @IBOutlet weak var podcastsTitle: UIView!
    @IBOutlet weak var podcastsTitleLabel: UILabel!
    @IBOutlet weak var podcastsView: BHUsersCarouselView!
    @IBOutlet weak var episodesTitle: UIView!
    @IBOutlet weak var episodesTitleLabel: UILabel!

    weak var delegate: BHChannelHeaderViewDelegate?
    
    var podcasts: [BHUser] = []

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityLabel = nil
    }
    
    // MARK: - Public
    
    func reloadData() {
        podcastsView.users = podcasts
    }

    func setup() {
        
        contentView.backgroundColor = .primaryBackground()

        podcastsView.delegate = self
        podcastsView.context = "Channel podcast"

        podcastsTitleLabel.textColor = .primary()
        podcastsTitleLabel.font = .sectionTitle()

        episodesTitleLabel.textColor = .primary()
        episodesTitleLabel.font = .sectionTitle()

        reloadData()
    }
    
    func calculateHeight(_ searchActive: Bool = false) -> CGFloat {
        var totalHeight: CGFloat = 0

        if hasPodcasts() {
            totalHeight += podcastsView.calculateHeight() + (podcastsTitle.frame.size.height > 0 ? podcastsTitle.frame.size.height : Constants.panelHeight) + (episodesTitle.frame.size.height > 0 ? episodesTitle.frame.size.height : Constants.panelHeight)
        }

        return totalHeight
    }
    
    // MARK: - Private

    fileprivate func hasPodcasts() -> Bool {
        return podcasts.count > 0
    }
}

// MARK: - BHUsersCarouselViewDelegate

extension BHChannelHeaderView: BHUsersCarouselViewDelegate {

    func usersCarouselView(_ view: BHUsersCarouselView, didSelectUser user: BHUser) {
        delegate?.headerView(self, didSelectUser: user)
    }
}
