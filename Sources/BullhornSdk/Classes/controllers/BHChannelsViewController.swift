
import UIKit
import Foundation

// MARK: - BHMoreInfoViewController

class BHChannelsViewController: BHPlayerContainingViewController {
    
    fileprivate static let ChannelSegueIdentifier = "Channels.ChannelSegueIdentifier"
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    
    private var selectedChannel: UIUsersModel?

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
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openChannels)
        BHTracker.shared.trackEvent(with: request)
    }
        
    // MARK: - Private
    
    fileprivate func configureNavigationItems() {
        navigationItem.title = "Verticals"
        navigationItem.largeTitleDisplayMode = .never

        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.accessibilityLabel = "Back"
        navigationItem.backBarButtonItem = backButton
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == BHChannelsViewController.ChannelSegueIdentifier, let vc = segue.destination as? BHChannelViewController {
            vc.channel = selectedChannel
        }
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BHChannelsViewController: UITableViewDelegate, UITableViewDataSource {
        
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
        let channel = BHNetworkManager.shared.carPlaySplittedUsers[indexPath.row]
        let model = SettingsOption(title: channel.title, accessibilityText: channel.title, icon: nil, iconBackgroundColor: .accent(), handler: {}, disclosure: true)
            
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BHSettingCell.reusableIndentifer, for: indexPath) as? BHSettingCell else {
                return UITableViewCell()
            }
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = BHNetworkManager.shared.carPlaySplittedUsers[indexPath.row]

        selectedChannel = channel
        performSegue(withIdentifier: BHChannelsViewController.ChannelSegueIdentifier, sender: self)
    }
}



