
import UIKit
import Foundation

class BHPostCollectionCell: UICollectionViewCell {

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
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

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetWidth = (superview as? UICollectionView)?.bounds.width ?? layoutAttributes.size.width
        let fitting = contentView.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        layoutAttributes.size = CGSize(width: targetWidth, height: fitting.height)
        return layoutAttributes
    }
}

