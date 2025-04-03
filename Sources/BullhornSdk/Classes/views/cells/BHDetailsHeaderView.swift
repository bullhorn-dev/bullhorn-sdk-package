
import Foundation
import UIKit

protocol BHDetailsHeaderViewDelegate: AnyObject {
    func detailsHeaderViewDidSelectUser(_ view: BHDetailsHeaderView)
}

class BHDetailsHeaderView: UITableViewHeaderFooterView {
    
    class var reusableIndentifer: String { return String(describing: self) }

    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var userIcon: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var waitingRoomStackView: UIStackView!
    @IBOutlet weak var waitingRoomLabel: UILabel!
    @IBOutlet weak var ringButton: UIButton!

    weak var delegate: BHDetailsHeaderViewDelegate?

    var post: BHPost?

    fileprivate lazy var dateFormatter: DateFormatter = DateFormatter()
    
    fileprivate var placeholderImage: UIImage?

    // MARK: - Lifecycle

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
        
    // MARK: - Public
    
    func reloadData() {
        guard let validPost = post else { return }

        let duration: Double = Double(validPost.recording?.duration ?? 0)

        userIcon.sd_setImage(with: validPost.user.coverUrl, placeholderImage: placeholderImage)
        userLabel.text = validPost.user.fullName
        titleLabel.text = validPost.title
        durationLabel.text = duration.stringFormatted()
        
        ringButton.isHidden = true

        if let validDate = validPost.publishedAtDate {
            durationLabel.text = dateFormatter.prettyDayFormatString(from: validDate)
            durationLabel.isHidden = false
        } else {
            durationLabel.text = ""
            durationLabel.isHidden = true
        }
        
        if validPost.isLiveNow() {
            if validPost.liveStatus.isScheduled() {
                waitingRoomStackView.isHidden = false
                
                if validPost.liveScheduledInPast() {
                    waitingRoomLabel.text = "Live is coming soon"
                    dateLabel.isHidden = true
                } else if let scheduledDate = validPost.scheduledAtDate {
                    waitingRoomLabel.text = "Going live in"
                    dateLabel.text = dateFormatter.prettyFutureDayFormatString(from: scheduledDate)
                    dateLabel.isHidden = false
                }
            } else {
                waitingRoomStackView.isHidden = true
            }
        } else {
            waitingRoomStackView.isHidden = true
        }
    }

    func setup() {
        
        contentView.backgroundColor = .primaryBackground()
        
        userIcon.layer.cornerRadius = 4
        userIcon.layer.borderColor = UIColor.tertiary().cgColor
        userIcon.layer.borderWidth = 1
        userIcon.backgroundColor = .tertiary()
        userIcon.clipsToBounds = true
        
        userLabel.textColor = .primary()
        dateLabel.textColor = .secondary()
        titleLabel.textColor = .primary()
        durationLabel.textColor = .secondary()
        waitingRoomLabel.textColor = .primary()
        
        ringButton.setTitle("", for: .normal)
        ringButton.backgroundColor = .clear
        ringButton.tintColor = .primary()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onUserAction(_:)))
        userStackView.addGestureRecognizer(tap)

        reloadData()
    }
    
    func calculateHeight() -> CGFloat {
        let spacing: CGFloat = 8
        var totalHeight: CGFloat = 2 * Constants.paddingVertical
        
        totalHeight += userIcon.frame.size.height + spacing
        totalHeight += heightForView(text: titleLabel.text ?? "", font: titleLabel.font, width: frame.size.width - 2 * Constants.paddingHorizontal) + spacing

        if hasRecording() {
            totalHeight += durationLabel.frame.size.height + spacing
        }

        if hasWaitingRoom() {
            totalHeight += waitingRoomStackView.frame.size.height + spacing
        }
        
        return totalHeight
    }
    
    // MARK: - Private
    
    fileprivate func initialize() {
        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
    }
    
    fileprivate func hasWaitingRoom() -> Bool {
        guard let validPost = post else { return false }
        return validPost.isLiveNow() && validPost.liveStatus.isScheduled()
    }
    
    fileprivate func hasRecording() -> Bool {
        return post?.hasRecording() ?? false
    }
    
    fileprivate func heightForView(text: String, font: UIFont, width: CGFloat) -> CGFloat {

        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()

        return label.frame.height
    }
    
    // MARK: - Actions
    
    @IBAction func onRingButton() {
        BHLog.p("\(#function)")
    }
    
    @objc fileprivate func onUserAction(_ sender: UITapGestureRecognizer) {
        BHLog.p("\(#function)")
        delegate?.detailsHeaderViewDidSelectUser(self)
    }
}
