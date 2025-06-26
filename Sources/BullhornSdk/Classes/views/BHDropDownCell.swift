
import UIKit
import Foundation

public class BHDropDownCell: UITableViewCell {
    
    static let reuseIdentifier = "BHDropDownCellReuseIdentifier"
    
    var selectItemClosure: ((BHDropDownItem)->())?

    var item: BHDropDownItem? {
        didSet {
            configureCell()
        }
    }
        
    public override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell() {
        guard let validItem = item else { return }
        
        self.selectionStyle = .gray
        self.textLabel?.font = .secondaryButton()
        self.textLabel?.adjustsFontForContentSizeCategory = true
        self.textLabel?.textColor = .primary()
        self.backgroundColor = .cardBackground()
        if validItem.extra {
            self.textLabel?.text = "\(validItem.value) (\(validItem.title))"
        } else {
            self.textLabel?.text = "\(validItem.value)"
        }
        
        selectionStyle = .none
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectCell))
        contentView.addGestureRecognizer(tapGesture)

    }
    
    @objc private func selectCell() {
        guard let validItem = item else { return }
        selectItemClosure?(validItem)
    }
}

