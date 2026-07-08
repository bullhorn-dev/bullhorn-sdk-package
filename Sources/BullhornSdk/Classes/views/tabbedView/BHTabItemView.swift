
import Foundation
import UIKit

class BHTabItemView: UIView, BHTabItemProtocol {

    var title: String

    private let labelHeight: CGFloat = 32.0

    lazy var titleLabel: BHPaddingLabel = {
        let label = BHPaddingLabel()
        label.font = .fontWithName(.robotoRegular, size: 17)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = .primary()
        label.text = title
        label.layer.masksToBounds = true
        label.backgroundColor = .secondaryBackground()
        label.textEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    init(title: String) {
        self.title = title
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.layer.cornerRadius = labelHeight / 2
    }

    // MARK: - BHTabItemProtocol

    func onSelected() {
        titleLabel.textColor = .navigationText()
        titleLabel.font = .fontWithName(.robotoMedium, size: 17)
        titleLabel.backgroundColor = .selectedBackground()
    }

    func onNotSelected() {
        titleLabel.textColor = .primary()
        titleLabel.font = .fontWithName(.robotoRegular, size: 17)
        titleLabel.backgroundColor = .secondaryBackground()
    }

    // MARK: - UI Setup

    private func setupUI() {
        self.backgroundColor = .primaryBackground()
        self.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])

        titleLabel.layer.cornerRadius = labelHeight / 2
    }
}

