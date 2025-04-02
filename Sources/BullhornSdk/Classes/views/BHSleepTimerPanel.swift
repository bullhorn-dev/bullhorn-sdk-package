import UIKit
import Foundation

class BHSleepTimerPanel: UIView {
    
    private var off = BHPlayerSettingsButton(type: .system)
    private var fiveMin = BHPlayerSettingsButton(type: .system)
    private var fifteenMin = BHPlayerSettingsButton(type: .system)
    private var thirtyMin = BHPlayerSettingsButton(type: .system)
    private var oneHour = BHPlayerSettingsButton(type: .system)
    private var twoHours = BHPlayerSettingsButton(type: .system)
    
    private var stackView: UIStackView!
    private var contentView = UIView()
    
    private var topBorder = CALayer()
    private var bottomBorder = CALayer()
    
    var selectedValue: Double = 0 {
        didSet {
            guard let value = BHPlayerSleepTime(rawValue: selectedValue) else { return }
            
            unselectAll()

            switch value {
            case .off:        off.select()
            case .fiveMin:    fiveMin.select()
            case .fifteenMin: fifteenMin.select()
            case .thirtyMin:  thirtyMin.select()
            case .oneHour:    oneHour.select()
            case .twoHours:   twoHours.select()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        off.addTarget(self, action: #selector(onOff), for: .touchUpInside)
        off.setTitle(BHPlayerSleepTime.off.getTitle(), for: .normal)

        fiveMin.addTarget(self, action: #selector(onFiveMin), for: .touchUpInside)
        fiveMin.setTitle(BHPlayerSleepTime.fiveMin.getTitle(), for: .normal)

        fifteenMin.addTarget(self, action: #selector(onFifteenMin), for: .touchUpInside)
        fifteenMin.setTitle(BHPlayerSleepTime.fifteenMin.getTitle(), for: .normal)

        thirtyMin.addTarget(self, action: #selector(onThirtyMin), for: .touchUpInside)
        thirtyMin.setTitle(BHPlayerSleepTime.thirtyMin.getTitle(), for: .normal)

        oneHour.addTarget(self, action: #selector(onOneHour), for: .touchUpInside)
        oneHour.setTitle(BHPlayerSleepTime.oneHour.getTitle(), for: .normal)

        twoHours.addTarget(self, action: #selector(onTwoHours), for: .touchUpInside)
        twoHours.setTitle(BHPlayerSleepTime.twoHours.getTitle(), for: .normal)

        stackView = UIStackView(arrangedSubviews: [off, fiveMin, fifteenMin, thirtyMin, oneHour, twoHours])
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
        off.translatesAutoresizingMaskIntoConstraints = false
        fiveMin.translatesAutoresizingMaskIntoConstraints = false
        fifteenMin.translatesAutoresizingMaskIntoConstraints = false
        thirtyMin.translatesAutoresizingMaskIntoConstraints = false
        oneHour.translatesAutoresizingMaskIntoConstraints = false
        twoHours.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.paddingHorizontal),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.paddingHorizontal),
            stackView.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            
            off.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            off.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            fiveMin.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            fiveMin.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            fifteenMin.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            fifteenMin.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            thirtyMin.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            thirtyMin.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            oneHour.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            oneHour.widthAnchor.constraint(equalToConstant: Constants.panelHeight),

            twoHours.heightAnchor.constraint(equalToConstant: Constants.panelHeight),
            twoHours.widthAnchor.constraint(equalToConstant: Constants.panelHeight),
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
        off.deselect()
        fiveMin.deselect()
        fifteenMin.deselect()
        thirtyMin.deselect()
        oneHour.deselect()
        twoHours.deselect()
    }
                
    // MARK: - Actions
    
    @objc private func onOff() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.off.rawValue)
        unselectAll()
        off.select()
    }

    @objc private func onFiveMin() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.fiveMin.rawValue)
        unselectAll()
        fiveMin.select()
    }

    @objc private func onFifteenMin() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.fifteenMin.rawValue)
        unselectAll()
        fifteenMin.select()
    }

    @objc private func onThirtyMin() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.thirtyMin.rawValue)
        unselectAll()
        thirtyMin.select()
    }

    @objc private func onOneHour() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.oneHour.rawValue)
        unselectAll()
        oneHour.select()
    }

    @objc private func onTwoHours() {
        BHHybridPlayer.shared.updateSleepTimer(BHPlayerSleepTime.twoHours.rawValue)
        unselectAll()
        twoHours.select()
    }
}
