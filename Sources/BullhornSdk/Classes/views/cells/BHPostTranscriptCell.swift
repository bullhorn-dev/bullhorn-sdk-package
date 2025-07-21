
import UIKit
import Foundation

class BHPostTranscriptCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var textLbl: UILabel!

    var postId: String?

    var segment: BHSegment? {
        didSet {
            update()
        }
    }

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.backgroundColor = .primaryBackground()
        
        timeLbl.textColor = .accent()
        timeLbl.font = .fontWithName(.robotoRegular, size: 14)
        timeLbl.adjustsFontForContentSizeCategory = true
        timeLbl.backgroundColor = .fxPrimaryBackground()
        timeLbl.layer.masksToBounds = true
        timeLbl.layer.cornerRadius = 6

        textLbl.textColor = .primary()
        textLbl.font = .fontWithName(.robotoRegular, size: 14)
        textLbl.adjustsFontForContentSizeCategory = true
    }
    
    // MARK: - Private
    
    fileprivate func update() {
        
        timeLbl.text = segment?.start.stringFormatted()
        textLbl.text = segment?.text
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        BHHybridPlayer.shared.addListener(self)
    }
}

extension BHPostTranscriptCell: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        guard let playerPost = player.post else { return }
        guard let validPostId = postId else { return }
            
        if playerPost.id == validPostId {
            guard let validSegment = segment else { return }

            if position >= validSegment.start && position < validSegment.end {
                DispatchQueue.main.async {
                    self.contentView.backgroundColor = .fxPrimaryBackground()
                }
            } else {
                DispatchQueue.main.async {
                    self.contentView.backgroundColor = .primaryBackground()
                }
            }
        }
    }

    func hybridPlayer(_ player: BHHybridPlayer, playerItem item: BHPlayerItem, playbackCompleted completed: Bool) {
        DispatchQueue.main.async {
            self.contentView.backgroundColor = .primaryBackground()
        }
    }
}

