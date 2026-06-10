import UIKit
import Foundation

/// Non-interactive, search-bar-styled control used in the podcast details header.
/// In normal mode it scrolls/hides together with the header. Tapping it activates
/// the real `UISearchController` that lives in the navigation bar.
///
/// Implemented as a `UIControl` (target-action) rather than a plain view with a
/// tap gesture, so the tap keeps working reliably across header reloads.
class BHSearchFieldView: UIControl {

    var onTap: (() -> Void)?

    fileprivate let containerView = UIView()
    fileprivate let iconView = UIImageView()
    fileprivate let placeholderLabel = UILabel()

    fileprivate let fieldHeight: CGFloat = 36.0
    fileprivate let horizontalInset: CGFloat = 16.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    // MARK: - Private

    fileprivate func setupUI() {

        backgroundColor = .primaryBackground()

        /// the control itself handles the touch; subviews must not swallow it
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .cardBackground()
        containerView.layer.cornerRadius = fieldHeight / 2
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.divider().cgColor
        containerView.clipsToBounds = true
        addSubview(containerView)

        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        iconView.image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        iconView.tintColor = .secondary()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)

        placeholderLabel.text = NSLocalizedString("Search podcasts or episodes", comment: "")
        placeholderLabel.textColor = .secondary()
        placeholderLabel.font = .settingsSecondaryText()
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(placeholderLabel)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    fileprivate func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: leftAnchor, constant: horizontalInset),
            containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: -horizontalInset),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: fieldHeight),

            iconView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            placeholderLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 8),
            placeholderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            placeholderLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor, constant: -12),
        ])
    }

    @objc fileprivate func handleTap() {
        onTap?()
    }

    // Keep the layer border color in sync with light/dark appearance changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            containerView.layer.borderColor = UIColor.divider().cgColor
        }
    }
}

