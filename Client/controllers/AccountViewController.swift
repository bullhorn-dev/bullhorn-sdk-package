
import UIKit
import BullhornSdk

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


class AccountViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var models = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItems()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
    }
    
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Account", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }

    fileprivate func configure() {
        models.removeAll()
        models.append(Section(title: "Account Management", options: [
            .staticCell(model: SettingsOption(title: "Log out", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.logout()
            }, disclosure: false)),
            .staticCell(model: SettingsOption(title: "To delete your account, please click here", icon: nil, iconBackgroundColor: .accent(), handler: {
                self.deleteAccount()
            }, disclosure: false)),
        ]))
    }

    fileprivate func logout() {
        if AuthService.shared.hasAuth {
            AuthService.shared.logout() { success in
                if success {
                    BullhornSdk.shared.logout()
                    AuthService.shared.store(foxAuth: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    fileprivate func deleteAccount() {
        if AuthService.shared.hasAuth {
            AuthService.shared.delete() { success in
                if success {
                    BullhornSdk.shared.logout()
                    AuthService.shared.store(foxAuth: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.identifier, for: indexPath) as? SettingTableViewCell else {
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
        case .staticCell(let model):
            model.handler()
        default:
            break
        }
    }
}

