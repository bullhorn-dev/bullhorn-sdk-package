
import UIKit
import Foundation

protocol BHSearchResultsUpdating: AnyObject {
    func updateSearchResults(for searchController: BHSearchController)
}

protocol BHSearchControllerDelegate: AnyObject {
    
    func willPresentSearchController(_ searchController: BHSearchController)
    func willDismissSearchController(_ searchController: BHSearchController)
}

class BHSearchController: NSObject {

    weak var searchResultsUpdater: BHSearchResultsUpdating?
    weak var delegate: BHSearchControllerDelegate?

    fileprivate(set) var searchBar: UISearchBar!
    fileprivate(set) var isActive = false
    fileprivate var navigationController: UINavigationController?
    
    var searchText: String { get { return searchBar.text ?? "" } }

    @available(*, unavailable)
    convenience override init() {
        fatalError("\(String(describing: BHSearchController.self)).\(#function) is not allowed")
    }

    init(with bar: UISearchBar) {
        super.init()
        
        searchBar = bar
        
        configure()
    }
    
    fileprivate func configure() {
        searchBar.delegate = self
    }
}

extension BHSearchController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResultsUpdater?.updateSearchResults(for: self)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

        searchBar.resignFirstResponder()

        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: false)
        
        isActive = false
        
        delegate?.willDismissSearchController(self)
        searchBar.resignFirstResponder()
        
        searchResultsUpdater?.updateSearchResults(for: self)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchResultsUpdater?.updateSearchResults(for: self)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

        searchBar.setShowsCancelButton(false, animated: false)
        searchBar.resignFirstResponder()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        isActive = true
        delegate?.willPresentSearchController(self)
        searchBar.setShowsCancelButton(true, animated: true)

        return true
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        
        return true
    }
}
