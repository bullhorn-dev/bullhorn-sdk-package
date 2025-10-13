
import UIKit
import Foundation

protocol BHPostCarouselViewDelegate: AnyObject {
    func postsCarouselView(_ view: BHPostsCarouselView, didSelectPost post: BHPost)
}

class BHPostsCarouselView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    weak var delegate: BHPostCarouselViewDelegate?

    var posts: [BHPost] {
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
        collectionView.register(BHLivePostCarouselCell.self, forCellWithReuseIdentifier: BHLivePostCarouselCell.reusableIndentifer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints =  false
        return collectionView
    }()

    // MARK: - Lifecycle

    init(posts: [BHPost] = []) {
        
        self.posts = posts
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {

        self.posts = []
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
        return frame.size.height > 0 ? frame.size.height : Constants.postsCarouselHeight
    }
    
    // MARK: - Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHLivePostCarouselCell.reusableIndentifer, for: indexPath) as! BHLivePostCarouselCell
        cell.post = posts[indexPath.item]
        return cell
    }
        
    // MARK: - Layout Delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.userProfileIconSize, height: Constants.postsCarouselHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: 0, right: Constants.paddingHorizontal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        delegate?.postsCarouselView(self, didSelectPost: post)
    }
      
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
