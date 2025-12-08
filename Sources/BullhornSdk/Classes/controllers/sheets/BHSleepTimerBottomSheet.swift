import UIKit
import Foundation

final class BHSleepTimerBottomSheet: BHBottomSheetController {
    
    private var sleepTimerLabel: UILabel!
    private var sleepTimerPanel: BHSleepTimerPanel!
    
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
                
        sleepTimerLabel = UILabel()
        sleepTimerLabel.contentMode = .center
        sleepTimerLabel.textAlignment = .center
        sleepTimerLabel.font = .secondaryText()
        sleepTimerLabel.textColor = .primary();
        stackView.addArrangedSubview(sleepTimerLabel)

        sleepTimerPanel = BHSleepTimerPanel()
        sleepTimerPanel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(sleepTimerPanel)
                    
        NSLayoutConstraint.activate([
            sleepTimerPanel.heightAnchor.constraint(equalToConstant: Constants.panelHeight + 2 * Constants.paddingVertical),
            sleepTimerPanel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
            sleepTimerPanel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
        ])
        
        updateSleepTimer()
    }
    
    fileprivate func updateSleepTimer() {
        let sleepTimerTime = BHHybridPlayer.shared.getSleepTimerInterval()
        let sleepTimerString = sleepTimerTime > 0 ? "+\(sleepTimerTime.stringFormatted())" : BHPlayerSleepTime.off.getTitle()
        sleepTimerLabel.text = sleepTimerString
        sleepTimerLabel.isHidden = BHHybridPlayer.shared.sleepTimerInterval <= 0
        sleepTimerPanel.selectedValue = BHHybridPlayer.shared.sleepTimerInterval
    }
}

extension BHSleepTimerBottomSheet: BHHybridPlayerListener {
    
    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }

    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }

    func hybridPlayer(_ player: BHHybridPlayer, sleepTimerUpdated sleepTimer: Double) {
        DispatchQueue.main.async { self.updateSleepTimer() }
    }
}


