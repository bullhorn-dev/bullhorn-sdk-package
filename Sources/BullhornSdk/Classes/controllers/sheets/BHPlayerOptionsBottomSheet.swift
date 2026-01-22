import UIKit
import Foundation

final class BHPlayerOptionsBottomSheet: BHBottomSheetController {
    
    var type: PlayerType = .recording
    
    private var downloadItem: BHOptionsItem!
    private var playNextItem: BHOptionsItem!
    private var shareItem: BHOptionsItem!
    private var reportItem: BHOptionsItem!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BHHybridPlayer.shared.addListener(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BHHybridPlayer.shared.removeListener(self)
    }

    override func loadView() {
        super.loadView()
        
        guard let validPost = BHHybridPlayer.shared.post else { return }
        
        /// play next (recording)
        playNextItem = BHOptionsItem(withType: .normal, valueType: .image, title: "Play Next", icon: "forward.end")
        let playNextItemTap = UITapGestureRecognizer(target: self, action: #selector(onPlayNextItem(_:)))
        playNextItem.addGestureRecognizer(playNextItemTap)

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
        
        /// share (recording, live, waiting room)
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

        if validPost.hasRecording() && !validPost.isLiveStream() {
            verticalStackView.addArrangedSubview(playNextItem)
            verticalStackView.addArrangedSubview(downloadItem)
            
            NSLayoutConstraint.activate([
                downloadItem.heightAnchor.constraint(equalToConstant: 50),
                downloadItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                downloadItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                playNextItem.heightAnchor.constraint(equalToConstant: 50),
                playNextItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                playNextItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
            ])
        }
        
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
        
        updateSettings()
    }
    
    func updateSettings() {
        playNextItem.setValueImage(UserDefaults.standard.playNextEnabled ? "checkmark" : nil)
    }
    
    // MARK: - Actions
    
    @objc func onDownloadItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validPost = BHHybridPlayer.shared.post else { return }

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
        
    @objc func onPlayNextItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            BHHybridPlayer.shared.updatePlayNextSetting(!UserDefaults.standard.playNextEnabled)
            self.updateSettings()
        })
    }
    
    @objc func onShareItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            
            var post: BHPost?
            
            if type == .recording {
                post = BHHybridPlayer.shared.post
            } else {
                post = BHLivePlayer.shared.post
            }
            
            guard let validPost = post else { return }
            
            let vc = UIActivityViewController(activityItems: [validPost.shareLink], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = self.view
            
            self.present(vc, animated: true, completion: nil)
        })
    }
    
    @objc func onReportItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            guard let validPost = BHHybridPlayer.shared.post else { return }
            
            let bundle = Bundle.module
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)

            if let vc = storyboard.instantiateViewController(withIdentifier: BHWebViewController.storyboardIndentifer) as? BHWebViewController {
                vc.infoLink = BullhornSdk.shared.infoLinks.first(where: { $0.type == .support })
                UIApplication.topNavigationController()?.dismiss(animated: false) {
                    UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                }
            }
            
            self.dismiss(animated: true)
        })
    }
}

extension BHPlayerOptionsBottomSheet: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}

    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {}

    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings) {
        DispatchQueue.main.async {
            self.updateSettings()
        }
    }
}

