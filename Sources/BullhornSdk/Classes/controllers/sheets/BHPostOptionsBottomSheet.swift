import UIKit
import Foundation

final class BHPostOptionsBottomSheet: BHBottomSheetController {

    private var shareItem: BHOptionsItem!
    private var reportItem: BHOptionsItem!
    private var downloadItem: BHOptionsItem!

    var post: BHPost?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        super.loadView()

        guard let validPost = self.post else { return }

        /// share
        shareItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Share", icon: "arrowshape.turn.up.right")
        let shareItemTap = UITapGestureRecognizer(target: self, action: #selector(onShareItem(_:)))
        shareItem.addGestureRecognizer(shareItemTap)
        
        /// download
        var downloadTitle = "Download"
        var downloadIcon = "arrow.down.to.line"
        var type: BHOptionsItem.ItemType = .normal

        if let item = BHDownloadsManager.shared.item(for: validPost.id), item.status != .progress {
            downloadTitle = "Remove from Downloads"
            downloadIcon = "trash"
            type = .destructive
        }

        downloadItem = BHOptionsItem(withType: type, valueType: .text, title: downloadTitle, icon: downloadIcon)
        let downloadItemTap = UITapGestureRecognizer(target: self, action: #selector(onDownloadItem(_:)))
        downloadItem.addGestureRecognizer(downloadItemTap)

        /// report
        reportItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Report", icon: "exclamationmark.octagon")
        let reportItemTap = UITapGestureRecognizer(target: self, action: #selector(onReportItem(_:)))
        reportItem.addGestureRecognizer(reportItemTap)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verticalStackView)

        verticalStackView.addArrangedSubview(shareItem)
        if validPost.hasRecording() && !validPost.isLiveStream() {
            verticalStackView.addArrangedSubview(downloadItem)
            
            NSLayoutConstraint.activate([
                downloadItem.heightAnchor.constraint(equalToConstant: 50),
                downloadItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                downloadItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            ])
        }
        verticalStackView.addArrangedSubview(reportItem)

        NSLayoutConstraint.activate([
            shareItem.heightAnchor.constraint(equalToConstant: 50),
            shareItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            shareItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            reportItem.heightAnchor.constraint(equalToConstant: 50),
            reportItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            reportItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),

            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            verticalStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc func onShareItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validPost = self.post else { return }

            if BHReachabilityManager.shared.isConnected() {
                BHPostsManager.shared.getPost(validPost.id, context: nil) { result in
                    switch result {
                    case .success(post: let post):
                        DispatchQueue.main.async {
                            let vc = UIActivityViewController(activityItems: [post.shareLink], applicationActivities: nil)
                            vc.popoverPresentationController?.sourceView = self.view
                                    
                            self.present(vc, animated: true, completion: nil)
                        }
                    case .failure(error: _):
                        DispatchQueue.main.async {
                            self.showError("Failed to share episode. This episode is no longer available.")
                        }
                    }
                }
                
                /// track stats
                let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .shareEpisode, context: validPost.shareLink.absoluteString, podcastId: validPost.user.id, podcastTitle: validPost.user.fullName, episodeId: validPost.id, episodeTitle: validPost.title)
                BHTracker.shared.trackEvent(with: request)

            } else {
                self.showError("Failed to share episode. The Internet connection is lost.")
            }
        })
    }
    
    @objc func onDownloadItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validPost = self.post else { return }

            if let item = BHDownloadsManager.shared.item(for: validPost.id), item.status != .progress {
                let alert = UIAlertController.init(title: "Remove this download?", message: "This episode will be removed from device memory and your downloads list. Do you want to remove it?", preferredStyle: .alert)

                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction.init(title: "Remove", style: .destructive) { _ in
                    BHDownloadsManager.shared.removeFromDownloads(validPost)
                    self.dismiss(animated: true)
                })

                UIApplication.topViewController()?.present(alert, animated: true)
            } else {
                BHDownloadsManager.shared.download(validPost, reason: .manually)
                self.dismiss(animated: true)
            }
        })
    }
    
    @objc func onReportItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validPost = self.post else { return }
            
            let bundle = Bundle.module
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)

            if let viewController = storyboard.instantiateViewController(withIdentifier: BHReportProblemViewController.storyboardIndentifer) as? BHReportProblemViewController {
                
                viewController.reportReason = ReportReason.experiencingABug.rawValue
                viewController.reportName = validPost.user.fullName
                viewController.reportDetails = validPost.shareLink.absoluteString

                UIApplication.topNavigationController()?.pushViewController(viewController, animated: true)
            }
            
            self.dismiss(animated: true)
        })
    }
}

