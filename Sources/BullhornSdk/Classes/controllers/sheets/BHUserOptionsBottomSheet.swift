import UIKit
import Foundation

final class BHUserOptionsBottomSheet: BHBottomSheetController {

    private var shareItem: BHOptionsItem!
    private var unfollowItem: BHOptionsItem!

    var user: BHUser?

    var unfollowPressedClosure: ((BHUser)->())?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        super.loadView()

        // share
        
        shareItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Share", icon: "arrowshape.turn.up.right")
        let shareItemTap = UITapGestureRecognizer(target: self, action: #selector(onShareItem(_:)))
        shareItem.addGestureRecognizer(shareItemTap)

        // unfollow
        
        unfollowItem = BHOptionsItem(withType: .destructive, valueType: .text, title: "Unfollow", icon: "trash")
        let unfollowItemTap = UITapGestureRecognizer(target: self, action: #selector(onUnfollowItem(_:)))
        unfollowItem.addGestureRecognizer(unfollowItemTap)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verticalStackView)

        verticalStackView.addArrangedSubview(shareItem)
        verticalStackView.addArrangedSubview(unfollowItem)

        NSLayoutConstraint.activate([
            shareItem.heightAnchor.constraint(equalToConstant: 50),
            shareItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            shareItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            
            unfollowItem.heightAnchor.constraint(equalToConstant: 50),
            unfollowItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            unfollowItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),

            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            verticalStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc func onShareItem(_ sender: UITapGestureRecognizer) {
        guard let url = self.user?.shareLink else { return }

        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sharePodcast, context: url.absoluteString, podcastId: user?.id, podcastTitle: user?.username)
        BHTracker.shared.trackEvent(with: request)

        self.presentShareDialog(with: [url], configureBlock: { controller in
            controller.popoverPresentationController?.sourceView = self.shareItem
        })
    }
    
    @objc func onUnfollowItem(_ sender: UITapGestureRecognizer) {
        guard let validUser = self.user else { return }
        unfollowPressedClosure?(validUser)
        dismiss(animated: true)
    }
}


