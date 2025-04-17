
import Foundation
import UIKit

protocol BHChannelsViewDelegate: AnyObject {
    func channelsView(_ view: BHChannelsView, didMoveToChannel index: Int)
}

class BHChannelsView: UIView {
    
    weak var delegate: BHChannelsViewDelegate?
    
    public var channels: [BHChannel] {
        didSet {
            self.collectionView.reloadData()
        }
    }

    private var currentlySelectedIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .zero
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .primaryBackground()
        collectionView.register(BHChannelCollectionViewCell.self, forCellWithReuseIdentifier: BHChannelCollectionViewCell.reusableIndentifer)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints =  false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Constants.paddingHorizontal, bottom: 0, right: Constants.paddingHorizontal)
        return collectionView
    }()
        
    // MARK: - Lifecycle

    init(with channels: [BHChannel] = []) {
        self.channels = channels
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.channels = []
        super.init(coder: coder)
        
        self.setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.reloadData()
    }
    
    // MARK: - Action

    func moveToChannel(at index: Int) {
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .left, animated: true)

        UserDefaults.standard.selectedChannelId = channels[index].id
        self.currentlySelectedIndex = index
        
        collectionView.reloadData()
    }
    
    func calculateHeight() -> CGFloat {
        return frame.size.height > 0 ? frame.size.height : 56.0
    }
    
    // MARK: UI Setup

    private func setupUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: self.leftAnchor),
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.rightAnchor.constraint(equalTo: self.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionView

extension BHChannelsView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let channel = channels[indexPath.row]
        let width = Double(channel.title.count) * 8.0 + 2 * Constants.paddingHorizontal

        return CGSize(width: width, height: frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.paddingVertical / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout ollectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BHChannelCollectionViewCell.reusableIndentifer, for: indexPath) as! BHChannelCollectionViewCell
        cell.channel = channels[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.moveToChannel(at: indexPath.item)
        self.delegate?.channelsView(self, didMoveToChannel: indexPath.item)
    }
}
