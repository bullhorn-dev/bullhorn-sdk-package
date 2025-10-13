
import UIKit
import Foundation

protocol BHUsersCarouselViewDelegate: AnyObject {
    func usersCarouselView(_ view: BHUsersCarouselView, didSelectUser user: BHUser)
}

class BHUsersCarouselView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    weak var delegate: BHUsersCarouselViewDelegate?

    var users: [BHUser] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.register(BHUserCarouselCell.self, forCellWithReuseIdentifier: BHUserCarouselCell.reusableIndentifer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints =  false
        return collectionView
    }()

    // MARK: - Lifecycle

    init(users: [BHUser] = []) {
        
        self.users = users
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {

        self.users = []
        super.init(coder: coder)

        self.setupUI()
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.reloadData()
    }
    
    // MARK: - UI Setup

    func setupUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(collectionView)
        collectionView.backgroundColor = .primaryBackground()
        
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            collectionView.centerXAnchor.constraint(equalTo: centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: centerYAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: calculateHeight())
        ])
    }
    
    func calculateHeight() -> CGFloat {
        return frame.size.height > 0 ? frame.size.height : Constants.usersCarouselHeight
    }
    
    // MARK: - Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHUserCarouselCell.reusableIndentifer, for: indexPath) as! BHUserCarouselCell
        cell.user = users[indexPath.item]
        return cell
    }
        
    // MARK: - Layout Delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.userProfileIconSize, height: Constants.usersCarouselHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: 0, right: Constants.paddingHorizontal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        delegate?.usersCarouselView(self, didSelectUser: user)
    }
      
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
