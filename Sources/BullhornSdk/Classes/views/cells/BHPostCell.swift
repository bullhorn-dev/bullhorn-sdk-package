
import UIKit
import Foundation

/// Thin table-cell wrapper around `BHPostContentView`. All content and logic
/// live in the shared content view; this only embeds it and forwards properties.
class BHPostCell: UITableViewCell {

    class var reusableIndentifer: String { return String(describing: self) }

    let content = BHPostContentView()

    // MARK: - Forwarded configuration

    var post: BHPost? {
        get { content.post }
        set { content.post = newValue }
    }

    var playlist: [BHPost]? {
        get { content.playlist }
        set { content.playlist = newValue }
    }

    var context: String {
        get { content.context }
        set { content.context = newValue }
    }

    var autoplayContext: BHAutoplayContext? {
        get { content.autoplayContext }
        set { content.autoplayContext = newValue }
    }

    var shareBtnTapClosure: ((URL)->())? {
        get { content.shareBtnTapClosure }
        set { content.shareBtnTapClosure = newValue }
    }

    var likeBtnTapClosure: ((Bool)->())? {
        get { content.likeBtnTapClosure }
        set { content.likeBtnTapClosure = newValue }
    }

    var transcriptBtnTapClosure: ((String)->())? {
        get { content.transcriptBtnTapClosure }
        set { content.transcriptBtnTapClosure = newValue }
    }

    var errorClosure: ((String)->())? {
        get { content.errorClosure }
        set { content.errorClosure = newValue }
    }

    /// exposed for share popover `sourceView`
    var shareButton: UIButton { content.shareButton }

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .primaryBackground()

        content.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentView.topAnchor),
            content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        content.prepareForReuse()
    }
}
