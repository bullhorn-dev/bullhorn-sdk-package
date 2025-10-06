import UIKit
import Foundation

final class BHUserOptionsBottomSheet: BHBottomSheetController {

    private var shareItem: BHOptionsItem!
    private var reportItem: BHOptionsItem!

    var user: BHUser?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        super.loadView()

        /// share
        shareItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Share", icon: "arrowshape.turn.up.right")
        let shareItemTap = UITapGestureRecognizer(target: self, action: #selector(onShareItem(_:)))
        shareItem.addGestureRecognizer(shareItemTap)

        /// report
        reportItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Report", icon: "exclamationmark.octagon")
        let reportItemTap = UITapGestureRecognizer(target: self, action: #selector(onReportItem(_:)))
        reportItem.addGestureRecognizer(reportItemTap)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(verticalStackView)

        verticalStackView.addArrangedSubview(shareItem)
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
            guard let url = self.user?.shareLink else { return }
            
            /// track stats
            let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .sharePodcast, context: url.absoluteString, podcastId: user?.id, podcastTitle: user?.fullName)
            BHTracker.shared.trackEvent(with: request)
            
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = self.view
                    
            self.present(vc, animated: true, completion: nil)
        })
    }
    
    @objc func onReportItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validUser = self.user else { return }
            
            let bundle = Bundle.module
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)

            if let viewController = storyboard.instantiateViewController(withIdentifier: BHReportProblemViewController.storyboardIndentifer) as? BHReportProblemViewController {
                
                viewController.reportReason = ReportReason.experiencingABug.rawValue
                viewController.reportName = validUser.fullName

                UIApplication.topNavigationController()?.pushViewController(viewController, animated: true)
            }
            
            self.dismiss(animated: true)
        })
    }
}


