
import UIKit
import BullhornSdk

struct ThemeOption {
    let title : String
    let selected : Bool
    let handler : (() -> Void)
}

class AppearanceViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var models = [ThemeOption]()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configure()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()        
    }
    
    fileprivate func configureNavigationItems() {
        
        navigationItem.title = NSLocalizedString("Appearance", comment: "")
        navigationItem.largeTitleDisplayMode = .never
    }
    
    fileprivate func configure() {
        
        let rawValue = UserDefaults.standard.string(forKey: ThemesManager.themeStateKey) ?? Appearance.system.rawValue
        let currentTheme = Appearance(rawValue: rawValue)

        models.removeAll()
        models.append(contentsOf: [
            ThemeOption(title: "System", selected: currentTheme == Appearance.system, handler: {
                ThemesManager.shared.updateTheme(theme: .system)
                self.configure()
                self.tableView.reloadData()
            }),
            ThemeOption(title: "Light", selected: currentTheme == Appearance.light, handler: {
                ThemesManager.shared.updateTheme(theme: .light)
                self.configure()
                self.tableView.reloadData()
            }),
            ThemeOption(title: "Dark", selected: currentTheme == Appearance.dark, handler: {
                ThemesManager.shared.updateTheme(theme: .dark)
                self.configure()
                self.tableView.reloadData()
            })
        ])
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AppearanceViewController: UITableViewDelegate, UITableViewDataSource {
            
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
            
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThemeTableViewCell.identifier, for: indexPath) as? ThemeTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = models[indexPath.row]
        model.handler()
    }
}
