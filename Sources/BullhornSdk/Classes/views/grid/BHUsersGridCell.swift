
import UIKit
import Foundation

class BHUsersGridCell: UITableViewCell {
    
    class var reusableIndentifer: String { return String(describing: self) }

    var collectionViewController: BHGridCollectionController!

    override func awakeFromNib() {
        super.awakeFromNib()
        initCollectionView()
    }
    
    private func initCollectionView() {
        
        let bundle = Bundle.module
        collectionViewController = BHGridCollectionController(nibName: String(describing: BHGridCollectionController.self), bundle: bundle)
        
        collectionViewController.didLayoutAction = updateRowHeight
        
        contentView.backgroundColor = .primaryBackground()
        contentView.addSubview(collectionViewController.view)
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            collectionViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            collectionViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func updateRowHeight() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView?.updateRowHeightsWithoutReloadingRows()
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return collectionViewController.collectionView.contentSize
    }
}
