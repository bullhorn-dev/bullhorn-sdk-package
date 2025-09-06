import UIKit
import Foundation

class BHPlaybackSpeedPanel: UIView {
    
    private var zeroTwoFive = BHPlayerSettingsButton(type: .system)
    private var zeroFiveZero = BHPlayerSettingsButton(type: .system)
    private var normal = BHPlayerSettingsButton(type: .system)
    private var oneTwoFive = BHPlayerSettingsButton(type: .system)
    private var oneFiveZero = BHPlayerSettingsButton(type: .system)
    private var twoZero = BHPlayerSettingsButton(type: .system)
    
    private var stackView: UIStackView!
    private var contentView = UIView()
    
    private var topBorder = CALayer()
    private var bottomBorder = CALayer()
    
    var selectedValue: Float = BHPlayerPlaybackSpeed.normal.rawValue {
        didSet {
            guard let val = BHPlayerPlaybackSpeed(rawValue: selectedValue) else { return }
            
            unselectAll()

            switch val {
            case .zeroTwoFive:  zeroTwoFive.select()
            case .zeroFiveZero: zeroFiveZero.select()
            case .normal:       normal.select()
            case .oneTwoFive:   oneTwoFive.select()
            case .oneFiveZero:  oneFiveZero.select()
            case .twoZero:      twoZero.select()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        zeroTwoFive.addTarget(self, action: #selector(onZeroTwoFive), for: .touchUpInside)
        zeroTwoFive.setTitle(BHPlayerPlaybackSpeed.zeroTwoFive.getTitle(), for: .normal)
        zeroTwoFive.accessibilityLabel = "Set playback speed to 0.25x"

        zeroFiveZero.addTarget(self, action: #selector(onZeroFiveZero), for: .touchUpInside)
        zeroFiveZero.setTitle(BHPlayerPlaybackSpeed.zeroFiveZero.getTitle(), for: .normal)
        zeroFiveZero.accessibilityLabel = "Set playback speed to 0.5x"

        normal.addTarget(self, action: #selector(onNormal), for: .touchUpInside)
        normal.setTitle(BHPlayerPlaybackSpeed.normal.getTitle(), for: .normal)
        normal.accessibilityLabel = "Set playback speed to 1x"

        oneTwoFive.addTarget(self, action: #selector(onOneTwoFive), for: .touchUpInside)
        oneTwoFive.setTitle(BHPlayerPlaybackSpeed.oneTwoFive.getTitle(), for: .normal)
        oneTwoFive.accessibilityLabel = "Set playback speed to 1.25x"

        oneFiveZero.addTarget(self, action: #selector(onOneFiveZero), for: .touchUpInside)
        oneFiveZero.setTitle(BHPlayerPlaybackSpeed.oneFiveZero.getTitle(), for: .normal)
        oneFiveZero.accessibilityLabel = "Set playback speed to 0.5x"

        twoZero.addTarget(self, action: #selector(onTwoZero), for: .touchUpInside)
        twoZero.setTitle(BHPlayerPlaybackSpeed.twoZero.getTitle(), for: .normal)
        twoZero.accessibilityLabel = "Set playback speed to 2x"

        stackView = UIStackView(arrangedSubviews: [zeroTwoFive, zeroFiveZero, normal, oneTwoFive, oneFiveZero, twoZero])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.backgroundColor = .clear
        
        contentView.addSubview(stackView)
        contentView.contentMode = .center
        contentView.backgroundColor = .clear

        topBorder.backgroundColor = UIColor.tertiary().cgColor
        bottomBorder.backgroundColor = UIColor.tertiary().cgColor
       
        contentView.layer.addSublayer(topBorder)
        contentView.layer.addSublayer(bottomBorder)

        addSubview(contentView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        zeroTwoFive.translatesAutoresizingMaskIntoConstraints = false
        zeroFiveZero.translatesAutoresizingMaskIntoConstraints = false
        normal.translatesAutoresizingMaskIntoConstraints = false
        oneTwoFive.translatesAutoresizingMaskIntoConstraints = false
        oneFiveZero.translatesAutoresizingMaskIntoConstraints = false
        twoZero.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.paddingHorizontal),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.paddingHorizontal),
            stackView.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            
            zeroTwoFive.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            zeroTwoFive.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            zeroFiveZero.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            zeroFiveZero.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            normal.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            normal.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneTwoFive.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneTwoFive.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneFiveZero.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneFiveZero.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

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
        bottomBorder.frame = CGRect(x: 0, y: contentView.frame.size.height - Constants.dividerHeight, width: contentView.frame.size.width, height: Constants.dividerHeight)
    }
    
    func unselectAll() {
        zeroTwoFive.deselect()
        zeroFiveZero.deselect()
        normal.deselect()
        oneTwoFive.deselect()
        oneFiveZero.deselect()
        twoZero.deselect()
    }
                
    // MARK: - Actions
    
    @objc private func onZeroTwoFive() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.zeroTwoFive.rawValue)
        unselectAll()
        zeroTwoFive.select()
    }

    @objc private func onZeroFiveZero() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.zeroFiveZero.rawValue)
        unselectAll()
        zeroFiveZero.select()
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

    @objc private func onTwoZero() {
        BHHybridPlayer.shared.updatePlaybackSpeed(BHPlayerPlaybackSpeed.twoZero.rawValue)
        unselectAll()
        twoZero.select()
    }
}
