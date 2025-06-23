
import UIKit
import Foundation

// MARK: - BHDropDownTextFieldDelegate

public protocol BHDropDownTextFieldDelegate {
    func menuDidAnimate(up: Bool)
    func optionSelected(option: String)
    func textChanged(text: String?)
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
    
    private let arrowIndicator: UIImageView = {
        let image = UIImage.BHDropDown.down.image
        image.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    private let tapView: UIView = UIView()
    
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
    
    @objc private func animateMenu() {
        menuAnimate(up: isDroppedDown)
    }

    private func calculateHeight() {
        self.initialHeight = self.bounds.height
        let rowCount = self.options.count
        let newHeight = self.initialHeight + (CGFloat(rowCount) * rowHeight)
        self.frame.size = CGSize(width: self.frame.width, height: newHeight)
    }
    
    private func setupViews() {
        removeSubviews()
        addTapView()
        addDropDownIndicator()
        addTextField()
        addTableView()
//        addAnimationView()
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
            textField.trailingAnchor.constraint(equalTo: arrowIndicator.leadingAnchor)
        ])
        textField.font = UIFont.fontWithName(.robotoRegular, size: 15)
        textField.backgroundColor = .cardBackground()
        textField.textInsets = .init(top: 12, left: 8, bottom: 12, right: 8)
        textField.addTarget(self, action: #selector(textFieldDidChange(_ :)), for: .editingChanged)
        textField.delegate = self
        
        self.layer.borderColor = UIColor.divider().cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 4
    }
    
    private func addTapView() {
        tapView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(animateMenu))
        tapView.addGestureRecognizer(tapGesture)
        tapView.backgroundColor = .cardBackground()
        addSubview(tapView)
        NSLayoutConstraint.activate([
            tapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapView.heightAnchor.constraint(equalToConstant: 44),
            tapView.widthAnchor.constraint(equalToConstant: 44),
            tapView.centerYAnchor.constraint(equalTo: topAnchor, constant: initialHeight / 2)
        ])
    }
    
    private func addDropDownIndicator() {
        arrowIndicator.translatesAutoresizingMaskIntoConstraints = false
        arrowIndicator.tintColor = .secondary()
        arrowIndicator.backgroundColor = .cardBackground()
        tapView.addSubview(arrowIndicator)
        let triSize: CGFloat = 24.0
        NSLayoutConstraint.activate([
            arrowIndicator.trailingAnchor.constraint(equalTo: tapView.trailingAnchor, constant: -8.0),
            arrowIndicator.heightAnchor.constraint(equalToConstant: triSize),
            arrowIndicator.widthAnchor.constraint(equalToConstant: triSize),
            arrowIndicator.centerYAnchor.constraint(equalTo: topAnchor, constant: initialHeight / 2)
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

            self.arrowIndicator.image = up ? UIImage.BHDropDown.down.image : UIImage.BHDropDown.up.image
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
        cell.selectItemClosure = { [weak self] item in
            BHLog.p("Select drop down item: \(item.value)")
            self?.textField.text = item.value
            self?.delegate?.optionSelected(option: item.value)
            self?.animateMenu()
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

