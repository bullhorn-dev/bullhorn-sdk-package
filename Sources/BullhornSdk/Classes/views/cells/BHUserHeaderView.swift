
import Foundation
import UIKit
internal import Cosmos

protocol BHUserHeaderViewDelegate: AnyObject {
    func userHeaderViewOnCollapseButtonPressed(_ view: BHUserHeaderView)
    func userHeaderViewOnShareButtonPressed(_ view: BHUserHeaderView, shareLink: URL)
    func userHeaderViewOnLinkButtonPressed(_ view: BHUserHeaderView, websiteLink: URL)
}

class BHUserHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var bioView: UIView!
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bioLabel: BHHyperlinkLabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var searchBarView: BHSearchBarView!
    
    fileprivate var isCollapsed: Bool = BHUserHeaderView.shouldCollapse()
    fileprivate var numberOfLines: Int = 4
    fileprivate var uncollapsedWidth: Int = 300
    
    weak var delegate: BHUserHeaderViewDelegate?

    var userManager: BHUserManager?

    fileprivate var placeholderImage: UIImage?

    static func shouldCollapse() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shareButton.layer.cornerRadius = shareButton.frame.size.height / 2
        collapseButton.layer.cornerRadius = collapseButton.frame.size.height / 2
    }
    
    // MARK: - Public
    
    func reloadData() {
        titleLabel.text = userManager?.user?.fullName
        userIcon.sd_setImage(with: userManager?.user?.coverUrl, placeholderImage: placeholderImage)
        ratingView.rating = userManager?.user?.ratingValue ?? 0
        ratingLabel.text = "\(userManager?.user?.ratingsCount ?? 0) Reviews"
        categoryLabel.text = userManager?.user?.categoryName
        
        setupBio(with: didTap)
        
        if BHUserHeaderView.shouldCollapse() {
            if let bio = userManager?.user?.bio {
                collapseButton.isHidden = bio.count < uncollapsedWidth
            } else {
                collapseButton.isHidden = true
            }
            updateCollapseButton()
        } else {
            collapseButton.isHidden = true
        }
    }
    
    func calculateHeight(_ searchActive: Bool = false) -> CGFloat {
        if searchActive {
            return searchBarView.frame.size.height
        } else {
            let linkViewHeight = hasWebsite() ? linkView.frame.size.height + Constants.paddingVertical : 0
            let spacing: CGFloat = 12
            let bio = bioLabel.attributedText?.string ?? ""
            let bioWidth = bio.count < uncollapsedWidth ? frame.size.width - 2 * Constants.paddingHorizontal : frame.size.width - collapseButton.frame.size.width - 2 * Constants.paddingHorizontal

            return 3 * spacing + userView.frame.size.height + heightForView(text: bio, font: bioLabel.font, width: bioWidth) + linkViewHeight + searchBarView.frame.size.height
        }
    }

    func setup(_ searchActive: Bool = false) {
        
        contentView.backgroundColor = .primaryBackground()
        
        updateCollapseButton()

        userIcon.layer.cornerRadius = 8
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true

        shareButton.setTitle("", for: .normal)
        shareButton.backgroundColor = .secondaryBackground()
        shareButton.tintColor = .primary()

        collapseButton.setTitle("", for: .normal)
        collapseButton.backgroundColor = .secondaryBackground()
        collapseButton.tintColor = .primary()

        ratingView.settings.updateOnTouch = false
        ratingView.settings.fillMode = .half
        ratingView.settings.starSize = 16
        ratingView.settings.starMargin = 0
        ratingView.settings.filledColor = .secondary()
        ratingView.settings.emptyBorderColor = .secondary()
        ratingView.settings.filledBorderColor = .secondary()
        ratingView.settings.emptyColor = .primaryBackground()
        ratingView.backgroundColor = .primaryBackground()
        
        ratingLabel.textColor = .secondary()
        categoryLabel.textColor = .secondary()
        
        userView.isHidden = searchActive
        bioView.isHidden = searchActive
        linkView.isHidden = searchActive || !hasWebsite()
        
        searchBarView.searchBar.placeholder = "Search..."
        searchBarView.mode = searchActive ? .dark : .light

        reloadData()
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle(for: Self.self)
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func hasWebsite() -> Bool {
        return userManager?.user?.website != nil
    }

    fileprivate func heightForView(text: String, font: UIFont, width: CGFloat) -> CGFloat {

        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = numberOfLines
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()

        return label.frame.height
    }
    
    fileprivate func updateCollapseButton() {
        if isCollapsed {
            collapseButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            numberOfLines = 5
        } else {
            collapseButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            numberOfLines = 0
        }
    }
    
    fileprivate func setupBio(with tapHandler: @escaping (URL) -> Void) {
        
        let attributedString = NSMutableAttributedString(string: userManager?.user?.bio ?? "")
        let terms: [(URL, NSRange)] = userManager?.user?.bio?.extractURLs() ?? []
        var termsDictionary: [String : (URL, NSRange)] = [:]
        
        for term in terms {
            termsDictionary[term.0.absoluteString] = (url: term.0, range: term.1)
        }

        termsDictionary.enumerated().forEach { index, value in
            let linkAttribute: NSAttributedString.Key = .hyperlink
            let attributes: [NSAttributedString.Key: Any] = [
                linkAttribute: value.1
            ]
            let urlAttributedString = NSAttributedString(string: value.0, attributes: attributes)
            let range = value.1.1
            if (range.location + range.length) < attributedString.length {
                attributedString.replaceCharacters(in: range, with: urlAttributedString)
            }
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        
        bioLabel.attributedText = attributedString
        bioLabel.didTapOnURL = tapHandler
        bioLabel.textAlignment = .left
    }
    
    // MARK: - Actions

    private func didTap(_ url: URL) {
        delegate?.userHeaderViewOnLinkButtonPressed(self, websiteLink: url)
    }
    
    // MARK: - Actions

    @IBAction func onLinkButton(_ sender: UIButton) {
        guard let website = userManager?.user?.website else { return }

        delegate?.userHeaderViewOnLinkButtonPressed(self, websiteLink: website)
    }

    @IBAction func onShareButton(_ sender: UIButton) {
        guard let user = userManager?.user else { return }
        guard let shareLink = userManager?.user?.shareLink else { return }

        delegate?.userHeaderViewOnShareButtonPressed(self, shareLink: shareLink)

        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sharePodcast, context: shareLink.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
        BHTracker.shared.trackEvent(with: request)
    }

    @IBAction func onCollapseButton(_ sender: UIButton) {
        isCollapsed = !isCollapsed
        updateCollapseButton()
        delegate?.userHeaderViewOnCollapseButtonPressed(self)
    }
}
