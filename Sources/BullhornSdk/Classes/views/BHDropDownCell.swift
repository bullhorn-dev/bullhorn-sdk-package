
import UIKit
import Foundation

class BHDropDownCell: UITableViewCell {
    
    static let reuseIdentifier = "BHDropDownCellReuseIdentifier"
    
    var selectItemClosure: ((BHDropDownItem)->())?

    var item: BHDropDownItem? {
        didSet {
            configureCell()
        }
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell() {
        guard let validItem = item else { return }
        
        self.selectionStyle = .gray
        self.textLabel?.font = .fontWithName(.robotoRegular, size: 15)
        self.textLabel?.textColor = .primary()
        self.backgroundColor = .cardBackground()
        self.textLabel?.text = "\(validItem.value)"
        
        selectionStyle = .none
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectCell))
        contentView.addGestureRecognizer(tapGesture)

    }
    
    @objc private func selectCell() {
        guard let validItem = item else { return }
        selectItemClosure?(validItem)
    }
}

