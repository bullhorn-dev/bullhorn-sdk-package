
import Foundation
import UIKit

protocol BHPollVariantCellDelegate: AnyObject {
    func pollVariantDidChange(_ cell: BHPollVariantCell, variant: BHBulletinPollVariant)
}

class BHPollVariantCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    weak var delegate: BHPollVariantCellDelegate?

    var pollVariant: BHBulletinPollVariant? {
        didSet {
            variantLabel.text = pollVariant?.value
        }
    }
    
    var totalAnswers: Int = 0 {
        didSet {
            if let answersCount = pollVariant?.answersCount, totalAnswers > 0 {
                let percent = Double(answersCount) / Double(totalAnswers) * 100
                percentLabel.text = "\(Int(percent))%"
            } else {
                percentLabel.text = "0%"
            }
        }
    }
    
    var isWinner: Bool = false {
        didSet {
            reloadUI()
        }
    }
    
    var isVoted: Bool = false {
        didSet {
            reloadUI()
        }
    }
    
    @IBOutlet weak var variantLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var winnerCheckmark: UIImageView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var leftViewWidth: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: BHActivityIndicatorView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onPollVariant(_:)))
        contentView.addGestureRecognizer(tap)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
    }
    
    // MARK: - Private
    
    fileprivate func setupViews() {
        
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = .accent()
        activityIndicator.isHidden = true

        stackView.backgroundColor = .tertiary()
        stackView.layer.cornerRadius = 4
        stackView.clipsToBounds = true
        stackView.backgroundColor = .playerOnDisplayBackground()

        leftView.layer.cornerRadius = 4
        leftView.backgroundColor = isWinner ? .accent() : .tertiary()
        rightView.backgroundColor = .playerOnDisplayBackground()

        variantLabel.textColor = .playerDisplayBackground()
        
        percentLabel.textColor = .playerDisplayBackground()
        percentLabel.textAlignment = .right
        percentLabel.numberOfLines = 1
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
        
        updateConstraint()
    }
    
    fileprivate func updateConstraint() {
        let fullWidth: Double = contentView.frame.size.width
        var leftWidth: Double = 0
        
        if let answersCount = pollVariant?.answersCount, totalAnswers > 0, isVoted {
            let percent = Double(answersCount) / Double(totalAnswers)
            leftWidth = percent * fullWidth
        }
        
        leftViewWidth.constant = leftWidth
    }
    
    fileprivate func reloadUI() {
        guard let variant = pollVariant else { return }
        
        if isVoted {
            percentLabel.isHidden = false
            winnerCheckmark.isHidden = !variant.userVoted
        } else {
            percentLabel.isHidden = true
            winnerCheckmark.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc func onPollVariant(_ sender: UITapGestureRecognizer?) {
        guard let validPollVariant = pollVariant else { return }
        
        if isVoted {
            BHLog.p("This poll variant has already voted")
            return
        }

        BHLog.p("\(#function) - id: \(validPollVariant.id), value: \(validPollVariant.value)")
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        BHBulletinManager.shared.choosePollVariant(validPollVariant.id) { response in
            switch response {
            case .success(variant: let variant):
                self.delegate?.pollVariantDidChange(self, variant: variant)
            case .failure(error: let e):
                BHLog.w("Choose poll variant failed \(e.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        }
    }
}

