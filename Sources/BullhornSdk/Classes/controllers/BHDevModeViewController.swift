
import UIKit

class BHDevModeViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var models = [Section]()

    private let networkIdDefaultValue = UserDefaults.standard.networkId
        
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configure()

        let bundle = Bundle.module
        let radioCellNib = UINib(nibName: "BHSettingSelectNetworkCell", bundle: bundle)
        let toggleCellNib = UINib(nibName: "BHSettingToggleCell", bundle: bundle)

        tableView.register(radioCellNib, forHeaderFooterViewReuseIdentifier: BHSettingSelectNetworkCell.reusableIndentifer)
        tableView.register(toggleCellNib, forHeaderFooterViewReuseIdentifier: BHSettingToggleCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorColor = .divider().withAlphaComponent(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideTopMessageView()
    }
    
    // MARK: - Private

    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Developer mode", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }
    
    fileprivate func configure() {
        
        models.removeAll()

        models.append(Section(title: "Network", options: [
            .radioCell(model: SettingsRadioOption(title: "Default", selected: !UserDefaults.standard.isCustomNetworkSelected, hasText: false, handler: {
                UserDefaults.standard.isCustomNetworkSelected = false
                self.configure()
                self.tableView.reloadData()
            })),
            .radioCell(model: SettingsRadioOption(title: "Custom", selected: UserDefaults.standard.isCustomNetworkSelected, hasText: true, handler: {
                UserDefaults.standard.isCustomNetworkSelected = true
            }))
        ]))
        
        models.append(Section(title: "Features", options: [
            .toggleCell(model: SettingsToggleOption(title: "Push notifications", isActive: UserDefaults.standard.isPushNotificationsFeatureEnabled, handler: {
                let value = UserDefaults.standard.isPushNotificationsFeatureEnabled
                UserDefaults.standard.isPushNotificationsFeatureEnabled = !value
                self.configure()
                self.tableView.reloadData()
            })),
            .toggleCell(model: SettingsToggleOption(title: "Auto downloads", isActive: UserDefaults.standard.isAutoDownloadsFeatureEnabled, handler: {
                let value = UserDefaults.standard.isAutoDownloadsFeatureEnabled
                UserDefaults.standard.isAutoDownloadsFeatureEnabled = !value
                self.configure()
                self.tableView.reloadData()
            })),
            .toggleCell(model: SettingsToggleOption(title: "Interactive transcripts", isActive: UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled, handler: {
                let value = UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled
                UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled = !value
                self.configure()
                self.tableView.reloadData()
            })),
            .toggleCell(model: SettingsToggleOption(title: "Episode's progress view", isActive: UserDefaults.standard.isEpisodeProgressViewFeatureEnabled, handler: {
                let value = UserDefaults.standard.isEpisodeProgressViewFeatureEnabled
                UserDefaults.standard.isEpisodeProgressViewFeatureEnabled = !value
                self.configure()
                self.tableView.reloadData()
            }))
        ]))
    }

    @objc func save(_ sender: Any) {
        
//        if let uuid = dropDownTextField.text, !uuid.isEmpty, let _ = UUID(uuidString: uuid), uuid != networkIdDefaultValue {
//            setNetwork(uuid)
//        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setNetwork(_ networkId: String) {
        BullhornSdk.shared.resetNetwork(with: networkId)
        UserDefaults.standard.networkId = networkId
    }
        
    @objc fileprivate func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHDevModeViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        case .toggleCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingToggleCell.reusableIndentifer, for: indexPath) as? BHSettingToggleCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .radioCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingSelectNetworkCell.reusableIndentifer, for: indexPath) as? BHSettingSelectNetworkCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].options[indexPath.row]

        switch type.self {
        case .toggleCell(let model):
            model.handler()
        case .radioCell(let model):
            model.handler()
        default: break
        }
    }
}



