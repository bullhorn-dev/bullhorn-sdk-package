
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

    /// Initial channel to center once the collection view has a valid layout.
    /// The header asks us to scroll during `setup()`, but at that point our
    /// bounds are still zero, so the offset would be computed against an empty
    /// contentSize (→ a small wrong offset that later "self-corrects").
    private var pendingScrollChannelId: String?
    
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
        /// Perform the deferred initial scroll now that we have a real width,
        /// so the channels strip appears already at the correct position
        /// instead of starting offset and animating into place later.
        if let channelId = pendingScrollChannelId, collectionView.bounds.width > 0 {
            pendingScrollChannelId = nil
            if let index = channels.firstIndex(where: { $0.id == channelId }) {
                scroll(to: index, animated: false)
            }
        }
    }
    
    // MARK: - Action
    
    /// Programmatic selection (e.g. restoring the persisted channel on launch).
    /// If the collection view isn't laid out yet, defer the scroll to the next
    /// `layoutSubviews` so the offset is computed against a valid contentSize.
    func moveToChannel(_ channelId: String) {
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else { return }

        if collectionView.bounds.width == 0 {
            pendingScrollChannelId = channelId
            UserDefaults.standard.selectedChannelId = channels[index].id
            currentlySelectedIndex = index
            return
        }
        scroll(to: index, animated: false)
    }

    /// User-initiated selection (tap) — animate.
    func moveToChannel(at index: Int) {
        scroll(to: index, animated: true)
    }

    private func scroll(to index: Int, animated: Bool) {
        guard index >= 0, index < channels.count else { return }

        UserDefaults.standard.selectedChannelId = channels[index].id
        currentlySelectedIndex = index

        collectionView.reloadData()
        /// ensure item attributes are computed against the current bounds
        /// before asking for a scroll offset
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
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
        
        collectionView.accessibilityTraits.insert(.tabBar)
        collectionView.isAccessibilityElement = false
    }
}

// MARK: - UICollectionView

extension BHChannelsView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let channel = channels[indexPath.row]

        let font: UIFont = .fontWithName(.robotoMedium, size: 17)
        let textWidth = (channel.title as NSString)
            .size(withAttributes: [.font: font])
            .width
        /// text + label insets (3pt each side) + horizontal chrome
        let width = ceil(textWidth) + 6.0 + 2 * Constants.paddingHorizontal

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
        
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = "\(channels[indexPath.row].title) channel"

        if indexPath.row == self.currentlySelectedIndex {
            cell.accessibilityTraits.insert(.selected)
        } else {
            cell.accessibilityTraits.remove(.selected)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.moveToChannel(at: indexPath.item)
        self.delegate?.channelsView(self, didMoveToChannel: indexPath.item)
    }
}

