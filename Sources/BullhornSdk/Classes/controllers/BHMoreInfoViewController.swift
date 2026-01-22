
import UIKit
import Foundation

// MARK: - Info Links

public enum BHInfoLinkType {
    case termsOfUse
    case privacyPolicy
    case privacyChoices
    case contactUs
    case support
}

public struct BHInfoLink {
    let type: BHInfoLinkType
    let title: String
    let url: String
    
    public init(type: BHInfoLinkType, title: String, url: String) {
        self.type = type
        self.title = title
        self.url = url
    }
}

// MARK: - BHMoreInfoViewController

class BHMoreInfoViewController: BHPlayerContainingViewController {
    
    fileprivate static let WebSegueIdentifier = "MoreInfo.WebSegueIdentifier"
    fileprivate static let ReportSegueIdentifier = "MoreInfo.ReportSegueIdentifier"
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    private var models = [Section]()
    private var selectedLink: BHInfoLink?

    private let infoLinks = BullhornSdk.shared.infoLinks

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItems()

        let bundle = Bundle.module
        let settingsCellNib = UINib(nibName: "BHSettingCell", bundle: bundle)

        tableView.register(settingsCellNib, forHeaderFooterViewReuseIdentifier: BHSettingCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorColor = .divider().withAlphaComponent(0.5)

        stackView.backgroundColor = .primaryBackground()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openMoreInfo)
        BHTracker.shared.trackEvent(with: request)
    }
        
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = "More Info"
        navigationItem.largeTitleDisplayMode = .never

        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }

    func configure() {
        
        models.removeAll()
        
        models.append(Section(title: "Information", options: [
            .staticCell(model: SettingsOption(title: "Terms of Use", accessibilityText: "External link", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.selectedLink = self.infoLinks.first(where: { $0.type == .termsOfUse })
                self.performSegue(withIdentifier: BHMoreInfoViewController.WebSegueIdentifier, sender: self)
            }, disclosure: true)),
            .staticCell(model: SettingsOption(title: "Privacy Policy", accessibilityText: "External link", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.selectedLink = self.infoLinks.first(where: { $0.type == .privacyPolicy })
                self.performSegue(withIdentifier: BHMoreInfoViewController.WebSegueIdentifier, sender: self)
            }, disclosure: true)),
            .staticCell(model: SettingsOption(title: "Your Privacy Choices", accessibilityText: "External link", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.selectedLink = self.infoLinks.first(where: { $0.type == .privacyChoices })
                self.performSegue(withIdentifier: BHMoreInfoViewController.WebSegueIdentifier, sender: self)
            }, disclosure: true)),
        ]))
        
        models.append(Section(title: "Support", options: [
            .staticCell(model: SettingsOption(title: "Contact Us", accessibilityText: "External link", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.selectedLink = self.infoLinks.first(where: { $0.type == .contactUs })
                self.performSegue(withIdentifier: BHMoreInfoViewController.WebSegueIdentifier, sender: self)
            }, disclosure: true)),
            .staticCell(model: SettingsOption(title: "Report a problem", accessibilityText: "External link", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.selectedLink = self.infoLinks.first(where: { $0.type == .support })
                self.performSegue(withIdentifier: BHMoreInfoViewController.WebSegueIdentifier, sender: self)
            }, disclosure: true)),
        ]))
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHMoreInfoViewController.WebSegueIdentifier, let vc = segue.destination as? BHWebViewController {
            vc.infoLink = selectedLink
        }
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHMoreInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = .fxPrimaryBackground()
        header.textLabel?.textColor = .primary()
        header.textLabel?.font = UIFont.fontWithName(.robotoBold , size: 18)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].options[indexPath.row]
            
        switch model.self {
        case .staticCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingCell.reusableIndentifer, for: indexPath) as? BHSettingCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
            
        default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]

        switch type.self {
        case .staticCell(let model):
            model.handler()
        default:
            break
        }
    }
}


