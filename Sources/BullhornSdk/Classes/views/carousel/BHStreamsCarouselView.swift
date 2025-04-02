
import UIKit
import Foundation

protocol BHStreamsCarouselViewDelegate: AnyObject {
    func usersCarouselView(_ view: BHStreamsCarouselView, didSelectStream stream: BHStream)
}

class BHStreamsCarouselView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    weak var delegate: BHStreamsCarouselViewDelegate?

    var streams: [BHStream] {
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
        collectionView.register(BHStreamCarouselCell.self, forCellWithReuseIdentifier: BHStreamCarouselCell.reusableIndentifer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints =  false
        return collectionView
    }()

    // MARK: - Lifecycle

    init(streams: [BHStream] = []) {
        
        self.streams = streams
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {

        self.streams = []
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
        collectionView.backgroundColor = .cardBackground()
        
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            collectionView.heightAnchor.constraint(equalTo: heightAnchor),
            collectionView.centerXAnchor.constraint(equalTo: centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Public
    
    func calculateHeight() -> CGFloat {
        return BHStreamCarouselCell.cellHeight
    }
    
    // MARK: - Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return streams.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHStreamCarouselCell.reusableIndentifer, for: indexPath) as! BHStreamCarouselCell
        
        if indexPath.item == 0 {
            cell.titleText = "Next"
        } else {
            cell.titleText = "Later"
        }

        cell.stream = streams[indexPath.item]

        return cell
    }
        
    // MARK: - Layout Delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: BHStreamCarouselCell.cellWidth, height: BHStreamCarouselCell.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.paddingHorizontal
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let stream = streams[indexPath.row]
        delegate?.usersCarouselView(self, didSelectStream: stream)
    }
      
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}

