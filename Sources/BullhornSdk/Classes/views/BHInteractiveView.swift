
import Foundation
import UIKit
import SDWebImage

protocol BHInteractiveViewDelegate: AnyObject {
    func interactiveView(_ view: BHInteractiveView, hasTile: Bool)
}

class BHInteractiveView: UIView {
    
    weak var delegate: BHInteractiveViewDelegate?

    var type: PlayerType = .interactive {
        didSet {
            setupTiles()
        }
    }

    var tiles: [BHBulletinTile] = []

    private let pagerView: BHPagerView = {
        let pagerView = BHPagerView()
        pagerView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        pagerView.itemSize = BHPagerView.automaticSize
        pagerView.automaticSlidingInterval = 10.0
        pagerView.isInfinite = true
        pagerView.removesInfiniteLoopForSingleItem = true
        pagerView.interitemSpacing = 2 * Constants.paddingHorizontal
        return pagerView
    }()
        
    private let pageControl: BHPageControl = {
        let pageControl = BHPageControl()
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        pageControl.setStrokeColor(.playerOnDisplayBackground(), for: .normal)
        pageControl.setStrokeColor(.playerOnDisplayBackground(), for: .selected)
        pageControl.setFillColor(.playerDisplayBackground(), for: .normal)
        pageControl.setFillColor(.playerOnDisplayBackground(), for: .selected)
        pageControl.hidesForSinglePage = true
        return pageControl
    }()
    
    private var bulletinEvent: BHBulletinEvent?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        BHHybridPlayer.shared.addListener(self)
        BHLivePlayer.shared.addListener(self)

        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        BHHybridPlayer.shared.addListener(self)
        BHLivePlayer.shared.addListener(self)

        setupUI()
    }
    
    deinit {
//        BHHybridPlayer.shared.removeListener(self)
//        BHLivePlayer.shared.removeListener(self)
    }
    
    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        
        pagerView.reloadData()
    }
    
    // MARK: - Public
    
    func scrollToTop() {
        pagerView.selectItem(at: 0, animated: true)
    }
    
    // MARK: - Private
    
    fileprivate func setupUI() {
        
        pagerView.delegate = self
        pagerView.dataSource = self
        
        addSubview(pagerView)
        addSubview(pageControl)
        
        pagerView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
                
        NSLayoutConstraint.activate([
            pagerView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: Constants.paddingHorizontal),
            pagerView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -Constants.paddingHorizontal),
            pagerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Constants.paddingVertical / 2),
            pagerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Constants.paddingVertical / 2),
            pageControl.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            pageControl.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            pageControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    fileprivate func setupTiles() {
        if type == .waitingRoom {
            tiles = BHBulletinManager.shared.bulletin?.preShowEvents?.compactMap({ $0.bulletinTile }) ?? []
        } else {
            if let event = BHHybridPlayer.shared.bulletin?.getTimelineEvent(0) {
                tiles.append(event.bulletinTile)
            }
        }
        reloadData()
    }
    
    func reloadData() {
//        BHLog.p("\(#function) - tiles number: \(tiles.count)")

        isHidden = tiles.count == 0
        
        delegate?.interactiveView(self, hasTile: tiles.count > 0)
        
        pageControl.numberOfPages = tiles.count
        pagerView.reloadData()
    }
    
    func reset() {
        BHLog.p("\(#function)")
        
        tiles.removeAll()
        reloadData()
    }
}

// MARK: - BHPagerViewDataSource

extension BHInteractiveView: BHPagerViewDataSource {
    
    public func numberOfItems(in pagerView: BHPagerView) -> Int {
        return tiles.count
    }
    
    public func pagerView(_ pagerView: BHPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        let tile = tiles[index]
        var tileView: BHBulletinTileBaseView
        
        switch tile.tileCategory {
        case .text:
            tileView = BHBulletinTileTextView(with: tile)
        case .image:
            tileView = BHBulletinTileImageView(with: tile)
        case .ad:
            tileView = BHBulletinTileAdView(with: tile)
        case .poll:
            tileView = BHBulletinTilePollView(with: tile)
        case .banner:
            tileView = BHBulletinTileTextView(with: tile)
        }

        tileView.delegate = self
        tileView.translatesAutoresizingMaskIntoConstraints = false

        if cell.contentView.subviews.count > 0 {
            cell.contentView.subviews.forEach({ $0.removeFromSuperview()})
        }
        cell.contentView.addSubview(tileView)
        
        NSLayoutConstraint.activate([
            tileView.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor),
            tileView.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor),
            tileView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            tileView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
        ])

        return cell
    }
}
    
// MARK: - BHPagerViewDelegate

extension BHInteractiveView: BHPagerViewDelegate {
    
    func pagerView(_ pagerView: BHPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }
    
    func pagerViewWillEndDragging(_ pagerView: BHPagerView, targetIndex: Int) {
        self.pageControl.currentPage = targetIndex
    }
    
    func pagerViewDidEndScrollAnimation(_ pagerView: BHPagerView) {
        self.pageControl.currentPage = pagerView.currentIndex
    }
}

// MARK: - BHBulletinTileViewDelegate

extension BHInteractiveView: BHBulletinTileViewDelegate {

    func tilePollView(_ view: BHBulletinTileBaseView, didChangeTile tile: BHBulletinTile) {
        if let index = self.tiles.firstIndex(where: {$0.id == tile.id}) {
            self.tiles[index] = tile
        }
    }
}

// MARK: - BHHybridPlayerListener

extension BHInteractiveView: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func hybridPlayer(_ player: BHHybridPlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async {
            let timelineEvent = BHHybridPlayer.shared.bulletin?.getTimelineEvent(position)
            
            if let validEvent = timelineEvent {
                if let validPrevEvent = self.bulletinEvent {
                    if validEvent.id != validPrevEvent.id {
                        self.tiles.removeAll()
                        self.tiles.append(validEvent.bulletinTile)
                        self.bulletinEvent = validEvent
                        self.reloadData()
                    }
                } else {
                    self.tiles.removeAll()
                    self.tiles.append(validEvent.bulletinTile)
                    self.bulletinEvent = validEvent
                    self.reloadData()
                }
            } else {
                self.tiles.removeAll()
                self.bulletinEvent = nil
                self.reloadData()
            }            
        }
    }
    
    func hybridPlayerDidChangeBulletin(_ player: BHHybridPlayer) {
        guard let bulletin = player.bulletin else { return }

        DispatchQueue.main.async {
            self.tiles = bulletin.bulletinEvents?.compactMap({ $0.bulletinTile }) ?? []
            if !(player.isEnded() || player.isDestroyed()) {
                self.reloadData()
            }
        }
    }
}

// MARK: - BHLivePlayerListener

extension BHInteractiveView: BHLivePlayerListener {

    func livePlayer(_ player: BHLivePlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {}
    
    func livePlayer(_ player: BHLivePlayer, positionChanged position: Double, duration: Double) {
        DispatchQueue.main.async {
            let event = BHLivePlayer.shared.bulletin?.getTimelineEvent(position)
            
            if let validEvent = event {
                if let validPrevEvent = self.bulletinEvent, validEvent.id != validPrevEvent.id {
                    self.tiles.removeAll()
                    self.tiles.append(validEvent.bulletinTile)
                    self.bulletinEvent = validEvent
                    self.reloadData()
                }
            } else {
                self.tiles.removeAll()
                self.bulletinEvent = nil
                self.reloadData()
            }
        }
    }
    
    func livePlayer(_ player: BHLivePlayer, bulletinDidChange bulletin: BHBulletin) {
        DispatchQueue.main.async {
            self.tiles = bulletin.preShowEvents?.compactMap({ $0.bulletinTile }) ?? []
            self.reloadData()
        }
    }
}
