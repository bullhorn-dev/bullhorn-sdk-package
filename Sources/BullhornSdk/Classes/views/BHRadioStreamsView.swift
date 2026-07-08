import UIKit
import Foundation
import SDWebImage

class BHRadioStreamsView: UIView {
    
    var showLaterStreams: Bool = false {
        didSet {
            guard oldValue != showLaterStreams else { return }
            setup()
        }
    }
        
    var radio: BHRadio? {
        didSet {
            reloadData()
        }
    }
    
    private let shadowView: UIView = {
        let view = UIView()
        let shadowColor = UIColor.shadow().withAlphaComponent(0.5)
        view.layer.cornerRadius = 8
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 4
        view.clipsToBounds = false
        view.backgroundColor = .cardBackground()
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.layer.borderColor = UIColor.tertiary().cgColor
        imageView.layer.borderWidth = 1
        imageView.clipsToBounds = true
        return imageView
    }()

    public let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "News Radio"
        label.font = .primaryButton()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .primary()
        label.numberOfLines = 1
        return label
    }()
    
    public let laterStreamsView: BHStreamsCarouselView = {
        let view = BHStreamsCarouselView()
        
        return view
    }()
    
    public let playButton: BHPlayButton = {
        let button = BHPlayButton(frame: CGRect(x: 0, y: 0, width: 120, height: 48))
        button.title = "Live Now!"
        return button
    }()
    
    private var isConfigured = false
    private var placeholderImage: UIImage?
    
    private var laterStreamsHeightConstraint: NSLayoutConstraint?

    private var activeConstraints: [NSLayoutConstraint] = []

    private let spacingHeight: CGFloat = 10.0
    private let imageHeight: CGFloat = Constants.radioAspectRatio * (UIScreen.main.bounds.width - 4 * Constants.paddingHorizontal)
    private let titleLblHeight: CGFloat = 24.0
    private let playBtnHeight: CGFloat = 48.0

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    // MARK: - Public
    
    func calculateHeight() -> CGFloat {
        var totalHeight: CGFloat = 4 * Constants.paddingVertical + imageHeight + titleLblHeight + playBtnHeight + 2 * spacingHeight
        
        if showLaterStreams {
            totalHeight += laterStreamsView.calculateHeight() + spacingHeight
        }
        
        return totalHeight
    }

    // MARK: - Private
    
    private func setup() {

        if isConfigured {
            NSLayoutConstraint.deactivate(activeConstraints)
            activeConstraints.removeAll()
            subviews.forEach { $0.removeFromSuperview() }
            BHRadioStreamsManager.shared.removeListener(self)
        }

        backgroundColor = .primaryBackground()

        let bundle = Bundle.module
        placeholderImage = UIImage(named: "ic_radio_placeholder.png", in: bundle, with: nil)

        let arranged = showLaterStreams
            ? [imageView, titleLabel, laterStreamsView, playButton]
            : [imageView, titleLabel, playButton]
        let vStackView = UIStackView(arrangedSubviews: arranged)
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        vStackView.distribution = .fill
        vStackView.spacing = spacingHeight

        shadowView.addSubview(vStackView)
        addSubview(shadowView)

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        laterStreamsView.translatesAutoresizingMaskIntoConstraints = false
        vStackView.translatesAutoresizingMaskIntoConstraints = false

        let shadowBottom = shadowView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.paddingVertical)
        shadowBottom.priority = UILayoutPriority(999)

        var constraints: [NSLayoutConstraint] = [
            shadowView.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.paddingVertical),
            shadowView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: Constants.paddingHorizontal),
            shadowView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Constants.paddingHorizontal),
            shadowBottom,
            vStackView.topAnchor.constraint(equalTo: shadowView.topAnchor, constant: Constants.paddingVertical),
            vStackView.leftAnchor.constraint(equalTo: shadowView.leftAnchor, constant: Constants.paddingHorizontal),
            vStackView.rightAnchor.constraint(equalTo: shadowView.rightAnchor, constant: -Constants.paddingHorizontal),
            vStackView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor, constant: -Constants.paddingVertical),
            imageView.leftAnchor.constraint(equalTo: vStackView.leftAnchor, constant: 0),
            imageView.rightAnchor.constraint(equalTo: vStackView.rightAnchor, constant: 0),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight),
            playButton.leftAnchor.constraint(equalTo: vStackView.leftAnchor, constant: 0),
            playButton.rightAnchor.constraint(equalTo: vStackView.rightAnchor, constant: 0),
            playButton.heightAnchor.constraint(equalToConstant: playBtnHeight),
            titleLabel.heightAnchor.constraint(equalToConstant: titleLblHeight),
        ]

        if showLaterStreams {
            let laterHeight = laterStreamsView.heightAnchor.constraint(equalToConstant: laterStreamsView.calculateHeight())
            laterStreamsHeightConstraint = laterHeight
            constraints.append(laterHeight)
        }

        activeConstraints = constraints
        NSLayoutConstraint.activate(constraints)

        BHRadioStreamsManager.shared.addListener(self)

        imageView.sd_setImage(with: nil, placeholderImage: placeholderImage)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .tertiary()

        playButton.isEnabled = false

        isConfigured = true
        layoutSubviews()
    }
    
    fileprivate func reloadData() {

        guard let radio = radio else { return }
        guard let liveStream = radio.streams.first else { return }

        playButton.post = radio.asPost()
        playButton.isEnabled = true
        
        laterStreamsView.streams = radio.laterStreams
        // Keep the baked height in sync with the now-populated carousel so the
        // content height matches the header height from calculateHeight().
        laterStreamsHeightConstraint?.constant = laterStreamsView.calculateHeight()
        
        imageView.sd_setImage(with: liveStream.coverUrl, placeholderImage: self.placeholderImage)
        titleLabel.text = liveStream.title
                
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityLabel = liveStream.title

        playButton.isAccessibilityElement = true
        playButton.context = "Live Now Radio"
    }
}

// MARK: - BHRadioStreamsManagerDelegate

extension BHRadioStreamsView: BHRadioStreamsListener {

    func radioStreamsManager(_ manager: BHRadioStreamsManager, radioDidChange radio: BHRadio) {
        DispatchQueue.main.async {
            self.radio = radio
        }
    }
}


