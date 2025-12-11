
import UIKit
import Foundation

// MARK: - BHDropDownTextFieldDelegate

public protocol BHDropDownTextFieldDelegate {
    func menuDidAnimate(up: Bool)
    func optionSelected(option: String)
    func textChanged(text: String?)
    func onMenuRequested()
}

// MARK: - BHDropDownItem

public struct BHDropDownItem {
    let value: String
    let title: String
    let extra: Bool
    
    public init(value: String, title: String, extra: Bool) {
        self.value = value
        self.title = title
        self.extra = extra
    }
}

// MARK: - BHDropDownTextField

public class BHDropDownTextField: UIView {
    
    public var delegate: BHDropDownTextFieldDelegate?

    public var text: String? {
        return textField.text
    }

    public var options = [BHDropDownItem]() {
        didSet {
            calculateHeight()
            setupViews()
        }
    }

    private var isDroppedDown = false
    private var initialHeight: CGFloat = 0
    private let rowHeight: CGFloat = 40
    
    private let arrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage.BHDropDown.down.image, for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .primary()
        button.accessibilityLabel = "Show problem reasons list"
        button.accessibilityTraits = .button
        return button
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(BHDropDownCell.self, forCellReuseIdentifier: BHDropDownCell.reuseIdentifier)
        tableView.bounces = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.separatorColor = .divider()
        return tableView
    }()
    
    let animationView = UIView()
    
    public lazy var textField: BHInputTextField = {
        let textField = BHInputTextField(frame: .zero)
        textField.textColor = .primary()
        textField.tintColor = .accent()
        textField.autocapitalizationType = .sentences
        textField.returnKeyType = .done
        textField.keyboardType = .alphabet
        return textField
    }()
    
    // MARK: - Lifecycle

    public init(frame: CGRect, title: String, options: [BHDropDownItem]) {
        self.options = options
        super.init(frame: frame)
        self.textField.placeholder = title
        calculateHeight()
        setupViews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    func closeOptions() {
        if isDroppedDown {
            menuAnimate(up: true)
        }
    }

    // MARK: - Private
    
    @objc private func animateMenu(_ sender: Any) {
        delegate?.onMenuRequested()
//        menuAnimate(up: isDroppedDown)
    }

    private func calculateHeight() {
        self.initialHeight = self.bounds.height
        let rowCount = self.options.count
        let newHeight = self.initialHeight + (CGFloat(rowCount) * rowHeight)
        self.frame.size = CGSize(width: self.frame.width, height: newHeight)
    }
    
    private func setupViews() {
        removeSubviews()
        addDropDownButton()
        addTextField()
        addTableView()
    }
    
    private func removeSubviews() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }
    
    private func addTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.centerYAnchor.constraint(equalTo: topAnchor, constant: initialHeight / 2),
            textField.trailingAnchor.constraint(equalTo: arrowButton.leadingAnchor)
        ])
        textField.font = .secondaryButton()
        textField.backgroundColor = .clear
        textField.textInsets = .init(top: 12, left: 8, bottom: 12, right: 8)
        textField.addTarget(self, action: #selector(textFieldDidChange(_ :)), for: .editingChanged)
        textField.delegate = self
        textField.adjustsFontForContentSizeCategory = true

        textField.backgroundColor = .cardBackground()
        textField.layer.borderColor = UIColor.divider().cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 4
        
        self.backgroundColor = .clear
    }
        
    private func addDropDownButton() {
        arrowButton.addTarget(self, action: #selector(animateMenu(_:)), for: .touchUpInside)
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrowButton)
        NSLayoutConstraint.activate([
            arrowButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            arrowButton.heightAnchor.constraint(equalToConstant: 44),
            arrowButton.widthAnchor.constraint(equalToConstant: 44),
            arrowButton.centerYAnchor.constraint(equalTo: topAnchor, constant: initialHeight / 2)
        ])
    }
    
    private func addTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        bringSubviewToFront(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor, constant: 44),
            tableView.heightAnchor.constraint(equalToConstant: rowHeight * CGFloat(options.count))
        ])
        tableView.isHidden = true
    }
    
    private func addAnimationView() {
        addSubview(animationView)
        animationView.frame = CGRect(x: 0.0, y: initialHeight, width: bounds.width, height: bounds.height - initialHeight)
        sendSubviewToBack(animationView)
        animationView.layer.shadowColor = UIColor.shadow().withAlphaComponent(0.5).cgColor
        animationView.layer.shadowOpacity = 0.5
        animationView.layer.shadowOffset = .zero
        animationView.layer.shadowRadius = 4
        animationView.backgroundColor = .secondaryBackground()
        animationView.isHidden = true
    }
    
    private func menuAnimate(up: Bool) {
        let downFrame = animationView.frame
        let upFrame = CGRect(x: 0, y: self.initialHeight, width: self.bounds.width, height: 0)
        animationView.frame = up ? downFrame : upFrame
        animationView.isHidden = false
        tableView.isHidden = true

        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.animationView.frame = up ? upFrame : downFrame
        }, completion: { (bool) in
            self.isDroppedDown = !self.isDroppedDown
            self.animationView.isHidden = up
            self.animationView.frame = downFrame

            self.arrowButton.accessibilityLabel = up ? "Open problem options list" : "Close problem options list"

            self.arrowButton.setImage(up ? UIImage.BHDropDown.down.image : UIImage.BHDropDown.up.image, for: .normal)
            self.tableView.isHidden = up
            self.delegate?.menuDidAnimate(up: up)
        })
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if isDroppedDown {
            closeOptions()
        }
        delegate?.textChanged(text: textField.text)
    }
}

// MARK: - UITextFieldDelegate

extension BHDropDownTextField: UITextFieldDelegate {

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        delegate?.optionSelected(option: text)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }
}

extension BHDropDownTextField: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHDropDownCell.reuseIdentifier) as? BHDropDownCell ?? BHDropDownCell()
        cell.item = options[indexPath.row]
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = options[indexPath.row].title
        cell.selectItemClosure = { [weak self] item in
            BHLog.p("Select drop down item: \(item.value)")
            self?.textField.text = item.value
            self?.delegate?.optionSelected(option: item.value)
//            self?.animateMenu(self)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / CGFloat(options.count)
    }
}

// MARK: - Drop Down Image extension

extension UIImage {
    
    enum BHDropDown {
        case down
        case up
        
        var name: String {
            switch self {
            case .down: return "chevron.down"
            case .up: return "chevron.up"
            }
        }
            
        var image: UIImage {
            let config = UIImage.SymbolConfiguration(weight: .light)
            return UIImage(systemName: name, withConfiguration: config)!
        }
    }
}

