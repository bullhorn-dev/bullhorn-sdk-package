
import UIKit
import Foundation
import SDWebImage

struct Section {
    let title : String
    let options : [SettingsOptionType]
}

enum SettingsOptionType {
    case staticCell(model: SettingsOption)
    case detailsCell(model: SettingsDetailsOption)
    case accountCell(model: SettingsAccountOption)
}

struct SettingsOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
    let disclosure: Bool
}

struct SettingsDetailsOption {
    let title: String
    let subtitle: String?
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
    let disclosure: Bool
}

struct SettingsAccountOption {
    let title : String
    let subtitle: String?
    let initials : String?
    let iconBackgroundColor : UIColor
    let handler : (() -> Void)
}

class BHProfileViewController: BHPlayerContainingViewController {
    
    fileprivate static let DownloadsSegueIdentifier = "Profile.DownloadsSegueIdentifier"
    fileprivate static let FavoritesSegueIdentifier = "Profile.FavoritesSegueIdentifier"

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var models = [Section]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle.module
        let settingsCellNib = UINib(nibName: "BHSettingCell", bundle: bundle)
        let detailsCellNib = UINib(nibName: "BHSettingDetailsCell", bundle: bundle)
        let accountCellNib = UINib(nibName: "BHAccountCell", bundle: bundle)

        tableView.register(settingsCellNib, forHeaderFooterViewReuseIdentifier: BHSettingCell.reusableIndentifer)
        tableView.register(detailsCellNib, forHeaderFooterViewReuseIdentifier: BHSettingDetailsCell.reusableIndentifer)
        tableView.register(accountCellNib, forHeaderFooterViewReuseIdentifier: BHAccountCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorColor = .divider().withAlphaComponent(0.5)

        stackView.backgroundColor = .primaryBackground()

        updateVersion()

        let versionTap = UITapGestureRecognizer(target: self, action: #selector(self.onVersionTapped(_:)))
        versionTap.numberOfTapsRequired = 3
        versionLabel.isUserInteractionEnabled = true
        versionLabel.addGestureRecognizer(versionTap)

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(_:)), name: BullhornSdk.OnExternalAccountChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
    }
        
    // MARK: - Private

    func configure() {
        
        models.removeAll()
                
        if BullhornSdk.shared.externalUser?.level == .fox, let user = BullhornSdk.shared.externalUser {
            models.append(Section(title: "Account", options: [
                .accountCell(model: SettingsAccountOption(title: "You're logged in as", subtitle: user.fullName ?? "Anonymous", initials: user.initials, iconBackgroundColor: .secondaryBackground(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenAccountNotification, object: self, userInfo: nil)
                })),
            ]))
        } else {
            models.append(Section(title: "Account", options: [
                .staticCell(model: SettingsOption(title: "Log In", icon: nil, iconBackgroundColor: .accent(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenLoginNotification, object: self, userInfo: nil)
                }, disclosure: true)),
                .detailsCell(model: SettingsDetailsOption(title: "Create a free account", subtitle: "Create your free account to like episodes and join in on the fun.", icon: nil, iconBackgroundColor: .accent(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenSignUpNotification, object: self, userInfo: nil)
                }, disclosure: true)),
            ]))
        }
        
        if BullhornSdk.shared.externalUser?.level == .fox {
            models.append(Section(title: "Collections", options: [
                .staticCell(model: SettingsOption(title: "Downloaded Episodes", icon: nil, iconBackgroundColor: .accent(), handler: {
                    self.performSegue(withIdentifier: BHProfileViewController.DownloadsSegueIdentifier, sender: self)
                }, disclosure: true)),
                .staticCell(model: SettingsOption(title: "Liked Episodes", icon: nil, iconBackgroundColor: .accent(), handler: {
                    self.performSegue(withIdentifier: BHProfileViewController.FavoritesSegueIdentifier, sender: self)
                }, disclosure: true)),
            ]))
        } else {
            models.append(Section(title: "Collections", options: [
                .staticCell(model: SettingsOption(title: "Downloaded Episodes", icon: nil, iconBackgroundColor: .accent(), handler: {
                    self.performSegue(withIdentifier: BHProfileViewController.DownloadsSegueIdentifier, sender: self)
                }, disclosure: true)),
            ]))
        }
        
        if UserDefaults.standard.isDevModeEnabled {
            models.append(Section(title: "App Preferences", options: [
                .staticCell(model: SettingsOption(title: "Appearance", icon: nil, iconBackgroundColor: .accent(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenAppearanceNotification, object: self, userInfo: nil)
                }, disclosure: true)),
                .staticCell(model: SettingsOption(title: "Developer mode options", icon: nil, iconBackgroundColor: .accent(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenDevModeNotification, object: self, userInfo: nil)
                }, disclosure: true)),
            ]))
        } else {
            models.append(Section(title: "App Preferences", options: [
                .staticCell(model: SettingsOption(title: "Appearance", icon: nil, iconBackgroundColor: .accent(), handler: {
                    NotificationCenter.default.post(name: BullhornSdk.OpenAppearanceNotification, object: self, userInfo: nil)
                }, disclosure: true)),
            ]))
        }
    }
                
    fileprivate func updateVersion() {
        
        let baseText = "version "
        let versionText = BullhornSdk.shared.appConfig.appVersion(useBuildNumber: true)
        let devModeText = UserDefaults.standard.isDevModeEnabled ? " DEV" : ""
        
        let font = UIFont.fontWithName(.robotoMedium , size: 15)
        let attributedString = NSMutableAttributedString(string: baseText + versionText + devModeText)
        
        attributedString.addAttribute(.font, value: font, range: NSRange(location: baseText.count, length: versionText.count))
        
        versionLabel.attributedText = attributedString
    }
    
    @objc fileprivate func onVersionTapped(_ sender: UITapGestureRecognizer) {
        let isDevModeEnabled = UserDefaults.standard.isDevModeEnabled
        
        UserDefaults.standard.isDevModeEnabled = !isDevModeEnabled
        
        debugPrint("Set Dev Mode enabled = \(!isDevModeEnabled)")
        
        configure()
        updateVersion()
        tableView.reloadData()
    }

    // MARK: - Notifications
    
    @objc fileprivate func onAccountChangedNotification(_ notification: Notification) {
        debugPrint("Account changed notification")

        configure()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = .secondaryBackground()
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
            
        case .detailsCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingDetailsCell.reusableIndentifer, for: indexPath) as? BHSettingDetailsCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell

        case .accountCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHAccountCell.reusableIndentifer, for: indexPath) as? BHAccountCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]

        switch type.self {
        case .staticCell(let model):
            model.handler()
        case .detailsCell(let model):
            model.handler()
        case .accountCell(let model):
            model.handler()
        }
    }
}

