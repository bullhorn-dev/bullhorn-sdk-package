import UIKit

class DropDownCell: UITableViewCell {
    
    static let reuseIdentifier = "DropDownCellReuseIdentifier"
    
    var selectItemClosure: ((DropDownItem)->())?

    var item: DropDownItem? {
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
        self.textLabel?.text = "\(validItem.value) (\(validItem.title))"
        
        selectionStyle = .none
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectCell))
        contentView.addGestureRecognizer(tapGesture)

    }
    
    @objc private func selectCell() {
        guard let validItem = item else { return }
        selectItemClosure?(validItem)
    }
}

