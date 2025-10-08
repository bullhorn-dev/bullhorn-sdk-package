
import Foundation
import UIKit

class BHTabItemView: UIView, BHTabItemProtocol {
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
        
    var title: String
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .fontWithName(.robotoRegular, size: 15)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var borderView: UIView = {
        let view = UIView()
        view.backgroundColor = .accent()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func onSelected() {
        self.titleLabel.font = .fontWithName(.robotoMedium, size: 15)
        self.titleLabel.textColor = .accent()

        if borderView.superview == nil {
            self.addSubview(borderView)
            
            NSLayoutConstraint.activate([
                borderView.leftAnchor.constraint(equalTo: self.leftAnchor),
                borderView.rightAnchor.constraint(equalTo: self.rightAnchor),
                borderView.heightAnchor.constraint(equalToConstant: 1),
                borderView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
    
    func onNotSelected() {
        self.titleLabel.font = .fontWithName(.robotoRegular, size: 15)
        self.titleLabel.textColor = .primary()

//        self.layer.shadowOpacity = 0
        
        self.borderView.removeFromSuperview()
    }
    
    
    // MARK: - UI Setup

    private func setupUI() {
        self.backgroundColor = .primaryBackground()
        self.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
