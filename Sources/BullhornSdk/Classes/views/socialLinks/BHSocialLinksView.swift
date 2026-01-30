
import Foundation
import UIKit

struct BHSocialLinkItem {
    let title: String
    let url: URL?
    let image: String
}

protocol BHSocialLinksViewDelegate: AnyObject {
    func socialLinksView(_ view: BHSocialLinksView, didSelectLink url: URL?)
}

class BHSocialLinksView: UIView {
    
    weak var delegate: BHSocialLinksViewDelegate?
    
    public var links: [BHSocialLinkItem] {
        didSet {
            self.collectionView.reloadData()
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .zero
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .primaryBackground()
        collectionView.register(BHSocialLinkCollectionViewCell.self, forCellWithReuseIdentifier: BHSocialLinkCollectionViewCell.reusableIndentifer)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints =  false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: 0, right: Constants.paddingHorizontal)
        return collectionView
    }()
        
    // MARK: - Lifecycle

    init(with links: [BHSocialLinkItem] = []) {
        self.links = links
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.links = []
        super.init(coder: coder)
        
        self.setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.reloadData()
    }
        
    func calculateHeight() -> CGFloat {
        return frame.size.height > 0 ? frame.size.height : 44.0
    }
    
    // MARK: UI Setup

    private func setupUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: self.leftAnchor),
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.rightAnchor.constraint(equalTo: self.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: calculateHeight())
        ])
        
        collectionView.isAccessibilityElement = false
    }
}

// MARK: - UICollectionView

extension BHSocialLinksView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let link = links[indexPath.row]
        let width = Double(link.title.count) * 8.0 + 30 + 24

        return CGSize(width: width, height: frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.paddingVertical / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout ollectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return links.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHSocialLinkCollectionViewCell.reusableIndentifer, for: indexPath) as! BHSocialLinkCollectionViewCell
        cell.link = links[indexPath.row]
        
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = "Open \(links[indexPath.row].title)"
        cell.accessibilityValue = "External link"
        cell.accessibilityTraits = .button

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let link = links[indexPath.row]
        self.delegate?.socialLinksView(self, didSelectLink: link.url)
    }
}

