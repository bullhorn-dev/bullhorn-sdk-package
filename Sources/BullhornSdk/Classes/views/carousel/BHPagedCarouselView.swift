
import UIKit
import Foundation

protocol BHPagedCarouselViewDelegate: AnyObject {
    func pagedCarouselView(_ view: BHPagedCarouselView, didMoveToPage index: Int)
    func pagedCarouselView(_ view: BHPagedCarouselView, didSelectPost post: BHPost)
}

class BHPagedCarouselView: UIView, BHPagerViewDelegate, BHPagerViewDataSource {
        
    // MARK: - Properties

    public weak var delegate: BHPagedCarouselViewDelegate?

    public var posts: [BHPost] {
        didSet {
            self.pagerView.reloadData()
        }
    }

    fileprivate var currentPage: Int = 0

    private lazy var pagerView: BHPagerView = {
        let view = BHPagerView(frame: .zero)
        view.register(BHPostCarouselCell.self, forCellWithReuseIdentifier: BHPostCarouselCell.reusableIndentifer)
        view.itemSize = BHPagerView.automaticSize
        view.automaticSlidingInterval = 15.0
//        view.isInfinite = true
        view.scrollDirection = .horizontal
        view.removesInfiniteLoopForSingleItem = true
        return view
    }()

    // MARK: - Initialization

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
        
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        pagerView.itemSize = CGSize(width: pagerView.frame.width * 0.9, height: Constants.postsCarouselHeight)
        pagerView.interitemSpacing = 3 * Constants.paddingHorizontal / 4
        pagerView.reloadData()
    }
    
    // MARK: - UI Setup

    func setupUI() {

        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.backgroundColor = .primaryBackground()

        addSubview(pagerView)

        translatesAutoresizingMaskIntoConstraints = false
        pagerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pagerView.widthAnchor.constraint(equalTo: widthAnchor),
            pagerView.heightAnchor.constraint(equalTo: heightAnchor),
            pagerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pagerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func calculateHeight() -> CGFloat {
        return Constants.pagedCarouselHeight
    }
    
    // MARK: - BHPagerView DataSource
        
    func numberOfItems(in pagerView: BHPagerView) -> Int {
        return posts.count
    }
    
    func pagerView(_ pagerView: BHPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: BHPostCarouselCell.reusableIndentifer, at: index) as! BHPostCarouselCell

        cell.post = posts[index]
        cell.playlist = posts

        return cell
    }
        
    // MARK: - BHPagerView Delegate
    
    func pagerView(_ pagerView: BHPagerView, shouldSelectItemAt index: Int) -> Bool {
        return true
    }
            
    func pagerView(_ pagerView: BHPagerView, didSelectItemAt index: Int) {

        let post = posts[index]

        delegate?.pagedCarouselView(self, didSelectPost: post)

        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }

    // MARK: - Actions

    public func moveToPage(at index: Int, animated: Bool = true) {
        pagerView.scrollToItem(at: index, animated: animated)
    }
}
