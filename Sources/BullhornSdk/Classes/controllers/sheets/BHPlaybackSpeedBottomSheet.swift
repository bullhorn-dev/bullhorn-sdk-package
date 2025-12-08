import UIKit
import Foundation

final class BHPlaybackSpeedBottomSheet: BHBottomSheetController {
    
    private var playbackSpeedPanel: BHPlaybackSpeedPanel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func loadView() {
        super.loadView()
        
        // playback speed (recording)
        
        playbackSpeedPanel = BHPlaybackSpeedPanel()
        playbackSpeedPanel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(playbackSpeedPanel)
            
        NSLayoutConstraint.activate([
            playbackSpeedPanel.heightAnchor.constraint(equalToConstant: Constants.panelHeight + 2 * Constants.paddingVertical),
            playbackSpeedPanel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            playbackSpeedPanel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
        
        updateSettings()
    }
    
    func updateSettings() {
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }
        
        playbackSpeedPanel.selectedValue = playerItem.playbackSettings.playbackSpeed
    }
}
