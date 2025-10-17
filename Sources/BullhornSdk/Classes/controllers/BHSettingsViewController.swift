
import UIKit
import Foundation

class BHSettingsViewController: BHPlayerContainingViewController {
    
    fileprivate static let NotificationsSegueIdentifier = "Settings.NotificationsSegueIdentifier"
    fileprivate static let DownloadsSegueIdentifier = "Settings.DownloadsSegueIdentifier"

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    private var models = [Section]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItems()

        let bundle = Bundle.module
        let settingsCellNib = UINib(nibName: "BHSettingCell", bundle: bundle)
        let settingsToggleCellNib = UINib(nibName: "BHSettingToggleCell", bundle: bundle)

        tableView.register(settingsCellNib, forHeaderFooterViewReuseIdentifier: BHSettingCell.reusableIndentifer)
        tableView.register(settingsToggleCellNib, forHeaderFooterViewReuseIdentifier: BHSettingToggleCell.reusableIndentifer)
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
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openSettings)
        BHTracker.shared.trackEvent(with: request)
    }
        
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        navigationItem.title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }

    func configure() {
        
        let isPushNotificationsEnabled = UserDefaults.standard.isPushNotificationsEnabled

        models.removeAll()

        models.append(Section(title: "Display", options: [
            .staticCell(model: SettingsOption(title: "Appearance", accessibilityText: nil, icon: nil, iconBackgroundColor: .accent(), handler: {
                NotificationCenter.default.post(name: BullhornSdk.OpenAppearanceNotification, object: self, userInfo: nil)
            }, disclosure: true)),
        ]))

        models.append(Section(title: "Preferences", options: [
            .toggleCell(model: SettingsToggleOption(title: "Enable Push Notifications", isActive: isPushNotificationsEnabled, handler: {
                let isEnable = !isPushNotificationsEnabled
                UserDefaults.standard.isPushNotificationsEnabled = isEnable

                if isEnable {
                    BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
                } else {
                    BHNotificationsManager.shared.forgetPushToken() { _ in }
                }
                
                self.configure()
                self.tableView.reloadData()
            })),
            .staticCell(model: SettingsOption(title: "Notifications Settings", accessibilityText: nil, icon: nil, iconBackgroundColor: .accent(), handler: {
                self.performSegue(withIdentifier: BHSettingsViewController.NotificationsSegueIdentifier, sender: self)
            }, disclosure: true)),
            .staticCell(model: SettingsOption(title: "Downloads Settings", accessibilityText: nil, icon: nil, iconBackgroundColor: .accent(), handler: {
                self.performSegue(withIdentifier: BHSettingsViewController.DownloadsSegueIdentifier, sender: self)
            }, disclosure: true)),
        ]))
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
            
        case .toggleCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingToggleCell.reusableIndentifer, for: indexPath) as? BHSettingToggleCell else {
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
        case .toggleCell(let model):
            model.handler()
        default:
            break
        }
    }
}



