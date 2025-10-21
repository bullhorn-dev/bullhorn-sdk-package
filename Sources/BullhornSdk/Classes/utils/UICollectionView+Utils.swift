
import Foundation
import UIKit

extension UICollectionView {

    func setEmptyMessage(_ message: String, image: UIImage?, topOffset: CGFloat = 0) {

        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .tertiary()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = .fontWithName(.robotoRegular, size: 16)
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel;
    }
    
    func setEmptyMessage(_ message: String, onRefresh: @escaping () -> Void, topOffset: CGFloat = 0) {

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 120))
        label.text = message
        label.textColor = .tertiary()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .fontWithName(.robotoRegular, size: 16)
        label.sizeToFit()

        let config = UIImage.SymbolConfiguration(scale: .medium)
        let button = UIButton(type: .system, primaryAction: UIAction(title: "", handler: { _ in
            onRefresh()
        }))
        button.setImage(UIImage(systemName: "arrow.clockwise")?.withConfiguration(config), for: .normal)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .fontWithName(.robotoMedium, size: 20)
        button.setTitleColor(.secondary(), for: .normal)
        button.tintColor = .secondary()

        let stackView = UIStackView(arrangedSubviews: [label, button])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Constants.paddingVertical
            
        self.backgroundView = stackView
            
        button.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
            
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44),
            button.widthAnchor.constraint(equalToConstant: 44),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: topOffset)
        ])
    }

    func restore() {
        self.backgroundView = nil
    }
}

