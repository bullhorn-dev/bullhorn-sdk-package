
import UIKit
import Foundation

// MARK: - BHMoreInfoViewController

class BHCategoriesViewController: BHPlayerContainingViewController {
    
    fileprivate static let CategorySegueIdentifier = "Categories.CategorySegueIdentifier"
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    private var selectedCategoryModel: UICategoryModel?

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

        BHNetworkManager.shared.splitUsersForCarPlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openCategories)
        BHTracker.shared.trackEvent(with: request)
    }
        
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = "Categories"
        navigationItem.largeTitleDisplayMode = .never

        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHCategoriesViewController.CategorySegueIdentifier, let vc = segue.destination as? BHCategoryViewController {
            vc.categoryModel = selectedCategoryModel
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHCategoriesViewController: UITableViewDelegate, UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BHNetworkManager.shared.carPlaySplittedUsers.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uiModel = BHNetworkManager.shared.carPlaySplittedUsers[indexPath.row]
        let model = SettingsOption(title: uiModel.category.name ?? "Undefined", accessibilityText: uiModel.category.name, icon: nil, iconBackgroundColor: .accent(), handler: {}, disclosure: true)
            
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingCell.reusableIndentifer, for: indexPath) as? BHSettingCell else {
                return UITableViewCell()
            }
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let categoryModel = BHNetworkManager.shared.carPlaySplittedUsers[indexPath.row]

        selectedCategoryModel = categoryModel
        performSegue(withIdentifier: BHCategoriesViewController.CategorySegueIdentifier, sender: self)
    }
}



