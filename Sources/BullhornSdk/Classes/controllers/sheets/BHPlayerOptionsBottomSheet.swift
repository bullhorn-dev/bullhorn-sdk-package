import UIKit
import Foundation

final class BHPlayerOptionsBottomSheet: BHBottomSheetController {
    
    var type: PlayerType = .recording
    
    private var playbackSpeedItem: BHOptionsItem!
    private var playbackSpeedPanel: BHPlaybackSpeedPanel!
    private var sleepTimerItem: BHOptionsItem!
    private var sleepTimerPanel: BHSleepTimerPanel!
    private var playNextItem: BHOptionsItem!
    private var shareItem: BHOptionsItem!
    
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
        
        // playback speed (recording)
        
        playbackSpeedPanel = BHPlaybackSpeedPanel()
        playbackSpeedPanel.isHidden = true
        
        playbackSpeedItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Playback Speed", icon: "speedometer")
        let playbackSpeedItemTap = UITapGestureRecognizer(target: self, action: #selector(onPlaybackSpeedItem(_:)))
        playbackSpeedItem.addGestureRecognizer(playbackSpeedItemTap)
        
        // sleep timer (recording)
        
        sleepTimerPanel = BHSleepTimerPanel()
        sleepTimerPanel.isHidden = true
        
        sleepTimerItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Sleep Timer", icon: "timer")
        let sleepTimerItemTap = UITapGestureRecognizer(target: self, action: #selector(onSleepTimerItem(_:)))
        sleepTimerItem.addGestureRecognizer(sleepTimerItemTap)

        // play next (recording)
        
        playNextItem = BHOptionsItem(withType: .normal, valueType: .image, title: "Play Next", icon: "forward.end")
        let playNextItemTap = UITapGestureRecognizer(target: self, action: #selector(onPlayNextItem(_:)))
        playNextItem.addGestureRecognizer(playNextItemTap)
        
        // share (recording, live, waiting room)
        
        shareItem = BHOptionsItem(withType: .normal, valueType: .text, title: "Share", icon: "arrowshape.turn.up.right")
        let shareItemTap = UITapGestureRecognizer(target: self, action: #selector(onShareItem(_:)))
        shareItem.addGestureRecognizer(shareItemTap)
        
        if type == .waitingRoom {
            let verticalStackView = UIStackView(arrangedSubviews: [
                shareItem
            ])
            verticalStackView.axis = .vertical
            
            view.addSubview(verticalStackView)
            
            verticalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                shareItem.heightAnchor.constraint(equalToConstant: 50),
                shareItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                shareItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
                verticalStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])
        } else {
            let verticalStackView = UIStackView(arrangedSubviews: [
                playbackSpeedItem,
                playbackSpeedPanel,
                sleepTimerItem,
                sleepTimerPanel,
                playNextItem,
                shareItem
            ])
            verticalStackView.axis = .vertical
            
            view.addSubview(verticalStackView)
            
            verticalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                playbackSpeedItem.heightAnchor.constraint(equalToConstant: 50),
                playbackSpeedItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                playbackSpeedItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                playbackSpeedPanel.heightAnchor.constraint(equalToConstant: Constants.panelHeight + 2 * Constants.paddingVertical),
                playbackSpeedPanel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                playbackSpeedPanel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                sleepTimerItem.heightAnchor.constraint(equalToConstant: 50),
                sleepTimerItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                sleepTimerItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                sleepTimerPanel.heightAnchor.constraint(equalToConstant: Constants.panelHeight + 2 * Constants.paddingVertical),
                sleepTimerPanel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                sleepTimerPanel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                                                
                playNextItem.heightAnchor.constraint(equalToConstant: 50),
                playNextItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                playNextItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                shareItem.heightAnchor.constraint(equalToConstant: 50),
                shareItem.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                shareItem.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                
                verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
                verticalStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])
        }
        
        updateSettings()
    }
    
    func updateSettings() {
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }
        
        playbackSpeedItem.setValue(playerItem.playbackSettings.playbackSpeedString())
        playbackSpeedPanel.selectedValue = playerItem.playbackSettings.playbackSpeed
        
        updateSleepTimer()
        
        playNextItem.setValueImage(UserDefaults.standard.playNextEnabled ? "checkmark" : nil)
    }
    
    fileprivate func updateSleepTimer() {
        let sleepTimerTime = BHHybridPlayer.shared.getSleepTimerInterval()
        let sleepTimerString = sleepTimerTime > 0 ? "+\(sleepTimerTime.stringFormatted())" : BHPlayerSleepTime.off.getTitle()
        self.sleepTimerItem.setValue(sleepTimerString)
        sleepTimerPanel.selectedValue = BHHybridPlayer.shared.sleepTimerInterval
    }
    
    // MARK: - Actions
    
    @objc func onPlaybackSpeedItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            self.playbackSpeedPanel.isHidden = !self.playbackSpeedPanel.isHidden
            self.playbackSpeedPanel.alpha = self.playbackSpeedPanel.isHidden ? 0 : 1
        })
    }

    @objc func onSleepTimerItem(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            self.sleepTimerPanel.isHidden = !self.sleepTimerPanel.isHidden
            self.sleepTimerPanel.alpha = self.sleepTimerPanel.isHidden ? 0 : 1
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
}

extension BHPlayerOptionsBottomSheet: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }

    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }

    func hybridPlayer(_ player: BHHybridPlayer, playbackSettingsUpdated settings: BHPlayerItem.PlaybackSettings) {
        DispatchQueue.main.async {
            self.playbackSpeedItem.setValue(settings.playbackSpeedString())
        }
    }

    func hybridPlayer(_ player: BHHybridPlayer, sleepTimerUpdated sleepTimer: Double) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }
}

