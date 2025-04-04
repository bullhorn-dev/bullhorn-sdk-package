
import UIKit
import Foundation

class BHPlayerViewController: BHPlayerBaseViewController {
    
    class var storyboardIndentifer: String { return String(describing: self) }
    
    @IBOutlet private(set) weak var nameView: UIView!
    @IBOutlet private(set) weak var nameLabel: UILabel!
    @IBOutlet private(set) weak var titleView: UIView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var controlsView: UIView!
    @IBOutlet private(set) weak var bottomView: UIView!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        BHLog.p("\(#function) - type: \(type)")

        nameView.backgroundColor = .primaryBackground()
        titleView.backgroundColor = .primaryBackground()
        controlsView.backgroundColor = .primaryBackground()
        titleLabel.textColor = .primary()
        nameLabel.textColor = .primary()
        playButton.tintColor = .primary()
        backwardButton.tintColor = .primary()
        forwardButton.tintColor = .primary()
        previousButton.tintColor = .primary()
        nextButton.tintColor = .primary()
        bottomView.backgroundColor = .primaryBackground()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - Overrides
    
    override func onStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        super.onStateChanged(state, stateFlags: stateFlags)
        
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }

        nameLabel.text = playerItem.post.userName
        titleLabel.text = playerItem.post.title
    }
    
    override func resetUI() {
        super.resetUI()

        nameLabel.text = ""
        titleLabel.text = ""
    }
    
    override func updateVideoLayer(_ isVideoAvailable: Bool) {
        super.updateVideoLayer(false) // tmp fix
    }
    
    override func updateLayers() {
        super.updateLayers()

        if BHHybridPlayer.shared.isEnded() {
            videoView.isHidden = true
        } else {
            videoView.isHidden = !hasVideo
        }
    }
}

