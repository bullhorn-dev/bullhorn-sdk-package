
import UIKit
import Foundation

protocol BHLiveCarouselViewDelegate: AnyObject {
    func liveCarouselView(_ view: BHLiveCarouselView, didMoveToPage index: Int)
    func liveCarouselView(_ view: BHLiveCarouselView, didSelectPost post: BHPost)
}

class BHLiveCarouselView: UIView, BHPagerViewDelegate, BHPagerViewDataSource {
        
    // MARK: - Properties

    public weak var delegate: BHLiveCarouselViewDelegate?

    public var posts: [BHPost] {
        didSet {
            self.pagerView.reloadData()
        }
    }

    fileprivate var currentPage: Int = 0

    private lazy var pagerView: BHPagerView = {
        let view = BHPagerView(frame: .zero)
        view.register(BHLivePostCarouselCell.self, forCellWithReuseIdentifier: BHLivePostCarouselCell.reusableIndentifer)
        view.itemSize = BHPagerView.automaticSize
//        view.automaticSlidingInterval = 15.0
//        view.isInfinite = true
        view.scrollDirection = .horizontal
//        view.removesInfiniteLoopForSingleItem = true
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
        
        pagerView.itemSize = CGSize(width: pagerView.frame.width - 2 * Constants.paddingHorizontal, height: Constants.postsCarouselHeight)
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
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: BHLivePostCarouselCell.reusableIndentifer, at: index) as! BHLivePostCarouselCell
        cell.post = posts[index]

        return cell
    }
        
    // MARK: - BHPagerView Delegate
    
    func pagerView(_ pagerView: BHPagerView, shouldSelectItemAt index: Int) -> Bool {
        return true
    }
            
    func pagerView(_ pagerView: BHPagerView, didSelectItemAt index: Int) {

        let post = posts[index]

        delegate?.liveCarouselView(self, didSelectPost: post)

        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }

    // MARK: - Actions

    public func moveToPage(at index: Int, animated: Bool = true) {
        pagerView.scrollToItem(at: index, animated: animated)
    }
}

