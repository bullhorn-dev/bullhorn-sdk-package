import UIKit
import Foundation

class BHSearchBarView: UIView {
    
    enum Mode: Int {
        case light
        case dark
    }
    
    fileprivate let barHeight: CGFloat = 36

    var mode: Mode = .light {
        didSet {
            setupUI()
        }
    }
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        return searchBar
    }()
    
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
    
    private func setupUI() {
        
        backgroundColor = mode == .light ? .primaryBackground() : .navigationBackground()
        
        searchBar.searchBarStyle = .prominent
        searchBar.barStyle = .default
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()

        searchBar.backgroundColor = mode == .light ? .primaryBackground() : .navigationBackground()
        searchBar.barTintColor = mode == .light ? .primaryBackground() : .navigationBackground()
        searchBar.tintColor = mode == .light ? .navigationBackground() : .onAccent()
        searchBar.setPlaceholderTextColor(to: .secondary())
        searchBar.setMagnifyingGlassColor(to: .secondary())
        searchBar.setClearButtonColor(to: .tertiary())
        searchBar.placeholder = "Search podcasts or episodes"
        
        searchBar.searchTextField.font = .fontWithName(.robotoRegular, size: 14)
        searchBar.searchTextField.textColor = .primary()
        searchBar.searchTextField.tintColor = .accent()
        searchBar.searchTextField.borderStyle = .roundedRect
        searchBar.searchTextField.layer.cornerRadius = barHeight / 2
        searchBar.searchTextField.layer.borderWidth = 1
        searchBar.searchTextField.layer.borderColor = UIColor.divider().cgColor
        searchBar.searchTextField.backgroundColor = .onAccent()
        searchBar.searchTextField.clipsToBounds = true
        addSubview(searchBar)
    }
    
    fileprivate func setupConstraints() {

        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.heightAnchor.constraint(equalToConstant: barHeight),
            searchBar.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8),
            searchBar.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),
            searchBar.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        searchBar.setTextFiledColor(color: .cardBackground())
        searchBar.searchTextField.layer.cornerRadius = barHeight / 2
        searchBar.searchTextField.layer.borderWidth = 1
        searchBar.searchTextField.layer.borderColor = UIColor.divider().cgColor
    }
}


extension UISearchBar {

   func setMagnifyingGlassColor(to color: UIColor) {
       let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
       let glassIconView = textFieldInsideSearchBar?.leftView as? UIImageView
       glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
       glassIconView?.tintColor = color
   }

   func setClearButtonColor(to color: UIColor) {
       let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
       let crossIconView = textFieldInsideSearchBar?.value(forKey: "clearButton") as? UIButton
       crossIconView?.setImage(crossIconView?.currentImage?.withRenderingMode(.alwaysTemplate), for: .normal)
       crossIconView?.tintColor = color
   }

   func setPlaceholderTextColor(to color: UIColor) {
       let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
       textFieldInsideSearchBar?.textColor = color
       let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
       textFieldInsideSearchBarLabel?.textColor = color
   }
    
    func setTextFiledColor(color: UIColor) {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.backgroundColor = color
    }
}
