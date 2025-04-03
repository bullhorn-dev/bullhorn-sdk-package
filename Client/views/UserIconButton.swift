
import Foundation
import UIKit

class UserIconButton: UIButton {
    
    let normalBgColor = UIColor.secondaryBackground()
    let selectedBgColor = UIColor.tertiary()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 8
        layer.borderColor = UIColor.tertiary().cgColor
        layer.borderWidth = 0.5
    }
    
    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? selectedBgColor : normalBgColor
    }
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        setTitle("", for: .normal)
    }
}
