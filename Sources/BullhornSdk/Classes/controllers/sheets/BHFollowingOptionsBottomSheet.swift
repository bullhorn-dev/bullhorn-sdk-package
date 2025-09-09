import UIKit
import Foundation

final class BHFollowingOptionsBottomSheet: BHBottomSheetController {

    private var unfollowItem: BHOptionsItem!
    private var notificationsItem: BHOptionsItem!
    private var downloadsItem: BHOptionsItem!

    var user: BHUser?

    var unfollowPressedClosure: ((BHUser)->())?
    var notificationsPressedClosure: ((BHUser)->())?
    var downloadsPressedClosure: ((BHUser)->())?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        super.loadView()

        /// notifications
        notificationsItem = BHOptionsItem(withType: .normal, valueType: .toggle, title: "New Episode Alerts", icon: nil)
        notificationsItem.setToggleValue(user?.receiveNotifications ?? false)
        let notificationsItemTap = UITapGestureRecognizer(target: self, action: #selector(onNotificationsItem(_:)))
        notificationsItem.addGestureRecognizer(notificationsItemTap)

        /// downloads
        downloadsItem = BHOptionsItem(withType: .normal, valueType: .toggle, title: "Auto Download Episodes", icon: nil)
        downloadsItem.setToggleValue(user?.autoDownload ?? false)
        let downloadsItemTap = UITapGestureRecognizer(target: self, action: #selector(onDownloadsItem(_:)))
        downloadsItem.addGestureRecognizer(downloadsItemTap)

        /// unfollow
        unfollowItem = BHOptionsItem(withType: .destructive, valueType: .text, title: "Unfollow", icon: nil)
        let unfollowItemTap = UITapGestureRecognizer(target: self, action: #selector(onUnfollowItem(_:)))
        unfollowItem.addGestureRecognizer(unfollowItemTap)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verticalStackView)
        
        if UserDefaults.standard.isPushNotificationsFeatureEnabled {
            verticalStackView.addArrangedSubview(notificationsItem)
            
            NSLayoutConstraint.activate([
                notificationsItem.heightAnchor.constraint(equalToConstant: 50),
                notificationsItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                notificationsItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            ])
        }

        if UserDefaults.standard.isAutoDownloadsFeatureEnabled {
            verticalStackView.addArrangedSubview(downloadsItem)
            
            NSLayoutConstraint.activate([
                downloadsItem.heightAnchor.constraint(equalToConstant: 50),
                downloadsItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                downloadsItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            ])
        }

        verticalStackView.addArrangedSubview(unfollowItem)

        NSLayoutConstraint.activate([
            unfollowItem.heightAnchor.constraint(equalToConstant: 50),
            unfollowItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            unfollowItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),

            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            verticalStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
        
    @objc func onNotificationsItem(_ sender: UITapGestureRecognizer) {
        guard let validUser = self.user else { return }
        notificationsItem.setToggleValue(!validUser.receiveNotifications)
        notificationsPressedClosure?(validUser)
    }
    
    @objc func onDownloadsItem(_ sender: UITapGestureRecognizer) {
        guard let validUser = self.user else { return }
        downloadsItem.setToggleValue(!validUser.autoDownload)
        downloadsPressedClosure?(validUser)
    }
    
    @objc func onUnfollowItem(_ sender: UITapGestureRecognizer) {
        guard let validUser = self.user else { return }
        unfollowPressedClosure?(validUser)
        dismiss(animated: true)
    }
}



