
import UIKit
import Foundation

protocol BHGridControllerDelegate: AnyObject {
    func gridController(_ controller: BHGridCollectionController, didSelectUser user: BHUser)
}

class BHGridCollectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: BHGridControllerDelegate?

    var uiModels: [UIUsersModel] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var showNewEpisodesBadge: Bool = false

    var didLayoutAction: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let bundle = Bundle.module
        let headerNib = UINib(nibName: "BHSectionHeaderView", bundle: bundle)
        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer)
        collectionView.register(BHUserCarouselCell.self, forCellWithReuseIdentifier: BHUserCarouselCell.reusableIndentifer)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .primaryBackground()
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        didLayoutAction?()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: UICollectionViewDataSource, UICollectionViewDelegate

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return uiModels.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uiModels[section].users.count
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BHSectionHeaderView.reusableIndentifer, for: indexPath)

            guard let usersHeaderView = headerView as? BHSectionHeaderView else { return headerView }
            usersHeaderView.titleLabel.text = uiModels[indexPath.section].title
            usersHeaderView.accessibilityLabel = uiModels[indexPath.section].title
            usersHeaderView.isAccessibilityElement = true

            return usersHeaderView
        default:
            return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHUserCarouselCell.reusableIndentifer, for: indexPath) as! BHUserCarouselCell
        
        cell.showCategory = false
        cell.showBadge = showNewEpisodesBadge
        cell.user = uiModels[indexPath.section].users[indexPath.item]
    
        return cell
    }
        
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = uiModels[indexPath.section].users[indexPath.row]
        delegate?.gridController(self, didSelectUser: user)
    }
      
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let width = (screenWidth - 2 * (Constants.paddingHorizontal + Constants.itemSpacing)) / 3
        let height = width + 35
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: 0, right: Constants.paddingHorizontal)
    }
}
