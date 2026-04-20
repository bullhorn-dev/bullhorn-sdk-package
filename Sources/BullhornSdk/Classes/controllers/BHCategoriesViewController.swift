
import UIKit
import Foundation

// MARK: - BHMoreInfoViewController

class BHCategoriesViewController: BHPlayerContainingViewController, ActivityIndicatorSupport {
    
    fileprivate static let CategorySegueIdentifier = "Categories.CategorySegueIdentifier"
    
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var refreshControl: UIRefreshControl?

    private var selectedCategory: BHCategory?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()

        let bundle = Bundle.module
        let settingsCellNib = UINib(nibName: "BHSettingCell", bundle: bundle)

        tableView.register(settingsCellNib, forHeaderFooterViewReuseIdentifier: BHSettingCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorColor = .divider().withAlphaComponent(0.5)

        stackView.backgroundColor = .primaryBackground()

        configureNavigationItems()
        configureRefreshControl()
        
        fetch(initial: true)
        
        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openCategories)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshControl?.endRefreshing()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        refreshControl?.resetUIState()
        tableView.reloadData()
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
    
    fileprivate func configureRefreshControl() {
        let newRefreshControl = UIRefreshControl()
        newRefreshControl.addTarget(self, action: #selector(onRefreshControlAction(_:)), for: .valueChanged)
        refreshControl = newRefreshControl
        refreshControl?.tintColor = .accent()
        tableView.addSubview(newRefreshControl)
    }
    
    fileprivate func fetch(initial: Bool = false) {
        let completeBlock = {
            self.refreshControl?.endRefreshing()
            self.defaultHideActivityIndicatorView()
            self.tableView.reloadData()
        }
        
        let networkId = BHAppConfiguration.shared.networkId

        if initial {
            self.defaultShowActivityIndicatorView()
            
            BHCategoriesManager.shared.fetchStorageCategories(networkId) { response in
                switch response {
                case .success:
                    completeBlock()
                    if BHCategoriesManager.shared.categories.count > 0 {
                        self.defaultHideActivityIndicatorView()
                    }
                case .failure(error: let error):
                    let message = "Failed to fetch categories from storage. \(error.localizedDescription)"
                    BHLog.w(message)
                    self.showError(message)
                }
            }
        }

        BHCategoriesManager.shared.getCategories(networkId) { response in
            switch response {
            case .success:
                break
            case .failure(error: let error):
                if BHReachabilityManager.shared.isConnected() {
                    self.showError("Failed to fetch all categories from backend. \(error.localizedDescription)")
                } else if !initial {
                    self.showConnectionError()
                }
            }
            completeBlock()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHCategoriesViewController.CategorySegueIdentifier, let vc = segue.destination as? BHCategoryViewController {
            vc.category = selectedCategory
        }
    }
    
    // MARK: - Action handlers
    
    @objc fileprivate func onRefreshControlAction(_ sender: Any) {
        fetch(initial: false)
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
        return BHCategoriesManager.shared.categories.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = BHCategoriesManager.shared.categories[indexPath.row]
        let model = SettingsOption(title: category.name ?? "Undefined", accessibilityText: category.name, icon: nil, iconBackgroundColor: .accent(), handler: {}, disclosure: true)
            
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingCell.reusableIndentifer, for: indexPath) as? BHSettingCell else {
                return UITableViewCell()
            }
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = BHCategoriesManager.shared.categories[indexPath.row]
        performSegue(withIdentifier: BHCategoriesViewController.CategorySegueIdentifier, sender: self)
    }
}



