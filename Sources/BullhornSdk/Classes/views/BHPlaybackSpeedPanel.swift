import UIKit
import Foundation

class BHPlaybackSpeedPanel: UIView {
    
    private var zeroSevenFive = BHPlayerSettingsButton(type: .system)
    private var normal = BHPlayerSettingsButton(type: .system)
    private var oneTwoFive = BHPlayerSettingsButton(type: .system)
    private var oneFiveZero = BHPlayerSettingsButton(type: .system)
    private var oneSevenFive = BHPlayerSettingsButton(type: .system)
    private var twoZero = BHPlayerSettingsButton(type: .system)
    
    private var stackView: UIStackView!
    private var contentView = UIView()
    
    private var topBorder = CALayer()
    
    var selectedValue: Float = BHPlayerPlaybackSpeed.normal.rawValue {
        didSet {
            guard let val = BHPlayerPlaybackSpeed(rawValue: selectedValue) else { return }
            
            unselectAll()

            switch val {
            case .zeroSevenFive:  zeroSevenFive.select()
            case .normal:       normal.select()
            case .oneTwoFive:   oneTwoFive.select()
            case .oneFiveZero:  oneFiveZero.select()
            case .oneSevenFive: oneSevenFive.select()
            case .twoZero:      twoZero.select()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        zeroSevenFive.addTarget(self, action: #selector(onZeroSevenFive), for: .touchUpInside)
        zeroSevenFive.setTitle(buttonTitle(.zeroSevenFive), for: .normal)
        zeroSevenFive.accessibilityLabel = "Playback speed"
        zeroSevenFive.accessibilityValue = buttonTitle(.zeroSevenFive)

        normal.addTarget(self, action: #selector(onNormal), for: .touchUpInside)
        normal.setTitle(buttonTitle(.normal), for: .normal)
        normal.accessibilityLabel = "Playback speed"
        normal.accessibilityValue = buttonTitle(.normal)

        oneTwoFive.addTarget(self, action: #selector(onOneTwoFive), for: .touchUpInside)
        oneTwoFive.setTitle(buttonTitle(.oneTwoFive), for: .normal)
        oneTwoFive.accessibilityLabel = "Playback speed"
        oneTwoFive.accessibilityValue = buttonTitle(.oneTwoFive)

        oneFiveZero.addTarget(self, action: #selector(onOneFiveZero), for: .touchUpInside)
        oneFiveZero.setTitle(buttonTitle(.oneFiveZero), for: .normal)
        oneFiveZero.accessibilityLabel = "Playback speed"
        oneFiveZero.accessibilityValue = buttonTitle(.oneFiveZero)

        oneSevenFive.addTarget(self, action: #selector(onOneSevenFive), for: .touchUpInside)
        oneSevenFive.setTitle(buttonTitle(.oneSevenFive), for: .normal)
        oneSevenFive.accessibilityLabel = "Playback speed"
        oneSevenFive.accessibilityValue = buttonTitle(.oneSevenFive)

        twoZero.addTarget(self, action: #selector(onTwoZero), for: .touchUpInside)
        twoZero.setTitle(buttonTitle(.twoZero), for: .normal)
        twoZero.accessibilityLabel = "Playback speed"
        twoZero.accessibilityValue = buttonTitle(.twoZero)

        stackView = UIStackView(arrangedSubviews: [zeroSevenFive, normal, oneTwoFive, oneFiveZero, oneSevenFive, twoZero])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.backgroundColor = .clear
        
        contentView.addSubview(stackView)
        contentView.contentMode = .center
        contentView.backgroundColor = .clear

        topBorder.backgroundColor = UIColor.tertiary().cgColor
        contentView.layer.addSublayer(topBorder)

        addSubview(contentView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        zeroSevenFive.translatesAutoresizingMaskIntoConstraints = false
        normal.translatesAutoresizingMaskIntoConstraints = false
        oneTwoFive.translatesAutoresizingMaskIntoConstraints = false
        oneFiveZero.translatesAutoresizingMaskIntoConstraints = false
        oneSevenFive.translatesAutoresizingMaskIntoConstraints = false
        twoZero.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.paddingHorizontal),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.paddingHorizontal),
            stackView.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            
            zeroSevenFive.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            zeroSevenFive.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            normal.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            normal.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneTwoFive.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneTwoFive.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneFiveZero.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneFiveZero.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneSevenFive.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneSevenFive.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            twoZero.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            twoZero.widthAnchor.constraint(equalToConstant: Constants.panelHeight),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        contentView.frame = self.bounds
        topBorder.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: Constants.dividerHeight)
    }
    
    func unselectAll() {
        zeroSevenFive.deselect()
        normal.deselect()
        oneTwoFive.deselect()
        oneFiveZero.deselect()
        oneSevenFive.deselect()
        twoZero.deselect()
    }
    
    fileprivate func buttonTitle(_ item: BHPlayerPlaybackSpeed) -> String {
        return item.getTitle()
    }
                
    // MARK: - Actions
    
    @objc private func onZeroSevenFive() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.zeroSevenFive.rawValue)
        unselectAll()
        zeroSevenFive.select()
    }

    @objc private func onNormal() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.normal.rawValue)
        unselectAll()
        normal.select()
    }

    @objc private func onOneTwoFive() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.oneTwoFive.rawValue)
        unselectAll()
        oneTwoFive.select()
    }

    @objc private func onOneFiveZero() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.oneFiveZero.rawValue)
        unselectAll()
        oneFiveZero.select()
    }
    
    @objc private func onOneSevenFive() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.oneSevenFive.rawValue)
        unselectAll()
        oneSevenFive.select()
    }

    @objc private func onTwoZero() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.twoZero.rawValue)
        unselectAll()
        twoZero.select()
    }
}
