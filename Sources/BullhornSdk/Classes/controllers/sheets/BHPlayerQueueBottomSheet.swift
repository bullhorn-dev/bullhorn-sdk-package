
import UIKit
import Foundation

class BHPlayerQueueBottomSheet: BHBottomSheetController {
    
    var tableView: UITableView!
    
    var heightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /// track event
        let request = BHTrackEventRequest.createRequest(category: .interactive, action: .ui, banner: .openQueue)
        BHTracker.shared.trackEvent(with: request)
    }
    
    override func loadView() {
        super.loadView()

        let bundle = Bundle.module
        let queueCellNib = UINib(nibName: "BHPlaybackQueueCell", bundle: bundle)

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(queueCellNib, forCellReuseIdentifier: BHPlaybackQueueCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .divider()
        tableView.allowsSelectionDuringEditing = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(tableView)
        
        let maxTableViewHeight: CGFloat = min(CGFloat(BHHybridPlayer.shared.playbackQueue.count * 72), 2 * UIScreen.main.bounds.height / 3)
        heightConstraint = NSLayoutConstraint(item: tableView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: maxTableViewHeight)
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        BHHybridPlayer.shared.addListener(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BHHybridPlayer.shared.removeListener(self)
    }
    
    // MARK: - Private
    
    fileprivate func updateContent() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: { [self] in
            let maxTableViewHeight: CGFloat = min(CGFloat(BHHybridPlayer.shared.playbackQueue.count * 72), 2 * UIScreen.main.bounds.height / 3)
            self.heightConstraint.constant = maxTableViewHeight
            self.tableView.reloadData()
        })
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHPlayerQueueBottomSheet: UITableViewDataSource, UITableViewDelegate {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHHybridPlayer.shared.playbackQueue.count == 0 {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_downloads_placeholder.png", in: bundle, with: nil)

            tableView.setEmptyMessage("No episodes in playback queue yet", image: image)
        } else {
            tableView.restore()
        }

        return BHHybridPlayer.shared.playbackQueue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BHPlaybackQueueCell", for: indexPath) as! BHPlaybackQueueCell
        let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
        cell.isActive = BHHybridPlayer.shared.isInPlayer(item.post.id)
        cell.item = item

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
        
        BHHybridPlayer.shared.playRequest(with: item.post, playlist: [])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.row == 0 { return UISwipeActionsConfiguration(actions: []) }
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, complete in
            let item = BHHybridPlayer.shared.playbackQueue[indexPath.row]
            
            BHHybridPlayer.shared.removeFromPlaybackQueue(item.id)
            self.updateContent()
            
            complete(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.image?.withTintColor(.onAccent())
        delete.backgroundColor = .accent()

        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.showsReorderControl = self.tableView(tableView, canMoveRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath destinationIndexPath: IndexPath) -> IndexPath {
        if destinationIndexPath.row == 0 {
            return IndexPath(row: 1, section: 0)
        }
        return destinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if destinationIndexPath.row == 0 { return }
        
        let movedItem = BHHybridPlayer.shared.playbackQueue.remove(at: sourceIndexPath.row)
        BHHybridPlayer.shared.playbackQueue.insert(movedItem, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
}

// MARK: - BHHybridPlayerListener

extension BHPlayerQueueBottomSheet: BHHybridPlayerListener {

    func hybridPlayer(_ player: BHHybridPlayer, stateUpdated state: PlayerState, stateFlags: PlayerStateFlags) {
        DispatchQueue.main.async {
            self.updateContent()
        }
    }
    
    func hybridPlayer(_ player: BHHybridPlayer, initializedWith playerItem: BHPlayerItem) {
        DispatchQueue.main.async {
            self.updateContent()
        }
    }

}

