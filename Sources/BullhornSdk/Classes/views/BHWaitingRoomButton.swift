import UIKit
import Foundation

class BHWaitingRoomButton: UIView {
    
    var post: BHPost? {
        didSet {
            updateButtonState()
        }
    }
    
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Waiting Room", for: .normal)
        button.setTitleColor(.onAccent(), for: .normal)
        button.titleLabel?.font = .fontWithName(.robotoMedium, size: 15)
        button.backgroundColor = .defaultDarkBlue()
        button.tintColor = .onAccent()
        return button
    }()
    
    private let loadIndicator: BHActivityIndicatorView = {
        let indicator = BHActivityIndicatorView(frame: .zero)
        indicator.type = .ballPulse
        indicator.color = .onAccent()
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
        button.layer.cornerRadius = button.frame.size.height / 2
    }
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        
        backgroundColor = .playerDisplayBackground()
        
        button.addTarget(self, action: #selector(onPress(_:)), for: .touchUpInside)
        
        addSubview(button)
        addSubview(loadIndicator)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: frame.size.width),
            button.heightAnchor.constraint(equalToConstant: frame.size.height),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadIndicator.widthAnchor.constraint(equalToConstant: 2 * frame.size.width / 3),
            loadIndicator.heightAnchor.constraint(equalToConstant: 2 * frame.size.height / 3),
            loadIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    fileprivate func updateButtonState() {
        
    }
        
    // MARK: - Actions
    
    @objc private func onPress(_ sender: Any) {
        guard let validPost = post else { return }

        BHLivePlayer.shared.playRequest(with: validPost)
    }
}
