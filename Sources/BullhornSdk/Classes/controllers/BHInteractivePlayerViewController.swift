
import UIKit
import Foundation

class BHInteractivePlayerViewController: BHPlayerBaseViewController {
    
    class var storyboardIndentifer: String { return String(describing: self) }

    enum Tabs: Int {
        case details = 0
        case transcript
    }
    
    @IBOutlet weak var videoStackView: UIStackView!
    @IBOutlet weak var interactiveStackView: UIStackView!
    @IBOutlet weak var fakeVideoView: UIView!
    @IBOutlet weak var fakeInteractiveView: UIView!
    @IBOutlet weak var fakeCollapseButton: UIView!
    @IBOutlet weak var topInteractiveView: UIView!

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var interactiveView: BHInteractiveView!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var tabbedView: BHTabbedView!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var overlayTopOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var overlayBottomOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!

    fileprivate var detailsHeaderView: BHDetailsHeaderView?

    fileprivate let hideOverlayInterval: Double = 5.0
    fileprivate var overlayTimer: Timer?

    fileprivate var selectedTab: Tabs = .details
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BHLog.p("\(#function) - type: \(type)")
        
        view.backgroundColor = .primaryBackground()

        playButton.tintColor = .playerOnDisplayBackground()
        backwardButton.tintColor = .playerOnDisplayBackground()
        forwardButton.tintColor = .playerOnDisplayBackground()
        playbackSpeedButton.tintColor = .playerOnDisplayBackground()
        playbackSpeedButton.setTitleColor(.playerOnDisplayBackground(), for: .normal)
        sleepTimerButton.tintColor = .playerOnDisplayBackground()

        showOverlay(true)

        interactiveView.type = type
        interactiveView.delegate = self
        interactiveView.reloadData()

        selectedTab = BHHybridPlayer.shared.isTranscriptActive ? .transcript : .details

        tabbedView.tabs = [
            BHTabItemView(title: "Details"),
            BHTabItemView(title: "Transcript")
        ]
        tabbedView.delegate = self
        tabbedView.moveToTab(at: selectedTab.rawValue)
        tabbedView.isHidden = false
        
        isExpanded = false
        
        collapseButton.setTitle("", for: .normal)
        collapseButton.tintColor = .tertiary()

        let bundle = Bundle.module
        let headerNib = UINib(nibName: "BHDetailsHeaderView", bundle: bundle)
        let descriptionCellNib = UINib(nibName: "BHPostDescriptionCell", bundle: bundle)
        let transcriptCellNib = UINib(nibName: "BHPostTranscriptCell", bundle: bundle)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: BHDetailsHeaderView.reusableIndentifer)
        tableView.register(descriptionCellNib, forCellReuseIdentifier: BHPostDescriptionCell.reusableIndentifer)
        tableView.register(transcriptCellNib, forCellReuseIdentifier: BHPostTranscriptCell.reusableIndentifer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground()

        detailsHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BHDetailsHeaderView.reusableIndentifer) as? BHDetailsHeaderView
        detailsHeaderView?.delegate = self

        let tapContentViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapContentView(_:)))
        contentView.addGestureRecognizer(tapContentViewGestureRecognizer)

        let tapOverlayViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOverlayView(_:)))
        overlayView.addGestureRecognizer(tapOverlayViewGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        BHOrientationManager.shared.landscapeSupported = true
        onRotated()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showOverlay(true)
        invalidateOverlayTimer()
        BHOrientationManager.shared.landscapeSupported = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
     
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override func updateAfterExpand() {
        super.updateAfterExpand()

        detailsView.isHidden = isExpanded
        tabbedView.isHidden = isExpanded
        updateCollapseButton()
        updateLayers()
    }
        
    // MARK: - Actions

    @IBAction func onCollapseButton() {
        self.isExpanded = !isExpanded
        
        if !self.isExpanded {
            tableView.reloadData()
        }
        
        let position = BHHybridPlayer.shared.lastSentPosition
        updateLayout(isExpanded, position: position)
    }

    @objc func didTapContentView(_ sender: UITapGestureRecognizer) {
        showOverlay(false)
        startOverlayTimer()
    }
    
    @objc func didTapOverlayView(_ sender: UITapGestureRecognizer) {
        showOverlay(true)
        invalidateOverlayTimer()
    }
    
    @objc func onRotated() {
        if UIDevice.current.orientation.isFlat { return }
        
        if UIDevice.current.orientation.isLandscape {
            videoStackView.axis = .horizontal
            interactiveStackView.axis = .horizontal
            isPortrait = false
            tabbedView.isHidden = true
            topVideoView.isHidden = true
            topInteractiveView.isHidden = true
            collapseButton.isHidden = true
            fakeCollapseButton.isHidden = true
            detailsView.isHidden = true
            view.backgroundColor = .playerDisplayBackground()
            overlayTopOffsetConstraint.constant = 10
            overlayBottomOffsetConstraint.constant = 0
        } else if UIDevice.current.orientation.isPortrait {
            videoStackView.axis = .vertical
            interactiveStackView.axis = .vertical
            isPortrait = true
            tabbedView.isHidden = isExpanded
            topVideoView.isHidden = false
            topInteractiveView.isHidden = false
            collapseButton.isHidden = false
            fakeCollapseButton.isHidden = false
            detailsView.isHidden = isExpanded
            view.backgroundColor = .primaryBackground()
            overlayTopOffsetConstraint.constant = 36
            overlayBottomOffsetConstraint.constant = 16
        }
        
        updateLayers()
    }

    // MARK: - Private
    
    fileprivate func updateCollapseButton() {
        let config = UIImage.SymbolConfiguration(weight: .heavy)
        
        if isExpanded {
            collapseButton.setImage(UIImage(systemName: "chevron.compact.up")?.withConfiguration(config), for: .normal)
        } else {
            collapseButton.setImage(UIImage(systemName: "chevron.compact.down")?.withConfiguration(config), for: .normal)
        }
    }
    
    fileprivate func showOverlay(_ hidden: Bool = true) {
        overlayView.isHidden = hidden
    }
        
    // MARK: - Override
    
    override func onStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        super.onStateChanged(state, stateFlags: stateFlags)
    }
        
    override func resetUI() {
        super.resetUI()
        
        hasTile = false
        interactiveView.reset()
    }
    
    override func updateLayers() {
        super.updateLayers()

        if BHHybridPlayer.shared.isEnded() {
            videoView.isHidden = true
            fakeVideoView.isHidden = true
            interactiveView.isHidden = true
            fakeInteractiveView.isHidden = true
        } else {
            videoView.isHidden = !hasVideo
            interactiveView.isHidden = !hasTile

            let showVideo = hasVideo && (isExpanded || !isPortrait || !hasTile)
            fakeVideoView.isHidden = !showVideo

            let showInteractive = hasTile && (isExpanded || !isPortrait || !hasVideo)
            fakeInteractiveView.isHidden = !showInteractive
        }
    }
    
    override func onTranscriptChanged() {
        super.onTranscriptChanged()

        if selectedTab == .transcript {
            tableView.reloadData()
        }
    }
    
    override func refreshTranscriptForPosition(_ position: Double = 0) {
        super.refreshTranscriptForPosition(position)
        
        if !UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled { return }

        if !BHHybridPlayer.shared.isTranscriptActive { return }

        if let index = BHHybridPlayer.shared.transcript?.segmentIndex(for: position), index >= 0 {
            let indexPath = IndexPath(row: index, section: 0)
                
            var indexPathsToReload = selectedIndexPaths
            indexPathsToReload.insert(indexPath)

            selectedIndexPaths.removeAll()
            selectedIndexPaths.insert(indexPath)

            tableView.reloadRows(at: Array(indexPathsToReload), with: .none)
        } else {
            selectedIndexPaths.removeAll()
            tableView.reloadData()
        }
    }
    
    // MARK: - Overlay timer
    
    fileprivate func startOverlayTimer() {

        invalidateOverlayTimer()

        let timer = Timer.init(timeInterval: hideOverlayInterval, target: self, selector: #selector(overlayTimerHandler(_:)), userInfo: nil, repeats: true)
        timer.tolerance = hideOverlayInterval
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
        overlayTimer = timer
    }
    
    fileprivate func invalidateOverlayTimer() {

        guard let timer = overlayTimer else { return }

        timer.invalidate()
        overlayTimer = nil
    }

    @objc fileprivate func overlayTimerHandler(_ timer: Timer) {

        guard timer.isValid else { return }

        overlayView.isHidden = true
    }
}

// MARK: - BHTabbedViewDelegate

extension BHInteractivePlayerViewController: BHTabbedViewDelegate {
    
    func tabbedView(_ tabbedView: BHTabbedView, didMoveToTab index: Int) {
        let isChanged = index != selectedTab.rawValue
        selectedTab = Tabs(rawValue: index) ?? .details
        isExpanded = false
        BHHybridPlayer.shared.isTranscriptActive = selectedTab == .transcript
        if isChanged { tableView.reloadData() }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHInteractivePlayerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTab {
        case .details:
            tableView.restore()
            return 1
        case .transcript:
            if BHHybridPlayer.shared.transcriptSegments.count == 0 && !activityIndicator.isAnimating {
                let bundle = Bundle.module
                let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)

                tableView.setEmptyMessage("Transcript is not available", image: image)
            } else {
                tableView.restore()
            }
            return BHHybridPlayer.shared.transcriptSegments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .details:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostDescriptionCell.reusableIndentifer, for: indexPath) as! BHPostDescriptionCell
            cell.text = post?.description
            return cell
        case .transcript:
            let cell = tableView.dequeueReusableCell(withIdentifier: BHPostTranscriptCell.reusableIndentifer, for: indexPath) as! BHPostTranscriptCell
            cell.isSelected = selectedIndexPaths.contains(indexPath)
            cell.postId = post?.id
            cell.segment = BHHybridPlayer.shared.transcriptSegments[indexPath.row]
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch selectedTab {
        case .details:
            detailsHeaderView?.post = post
            detailsHeaderView?.setup()
            return detailsHeaderView
        case .transcript:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch selectedTab {
        case .transcript:
            return 1
        case .details:
            return detailsHeaderView?.calculateHeight() ?? 100
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch selectedTab {
        case .transcript:
            if UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled {
                guard let validPost = post else { return }
                let position = BHHybridPlayer.shared.transcriptSegments[indexPath.row].start
                
                if BHHybridPlayer.shared.isPostActive(validPost.id) {
                    BHHybridPlayer.shared.seek(to: position, resume: true)
                }
            }
        default:
            return
        }
    }
}

// MARK: - BHInteractiveViewDelegate

extension BHInteractivePlayerViewController: BHInteractiveViewDelegate {
    
    func interactiveView(_ view: BHInteractiveView, hasTile: Bool) {
        if !self.hasTile && hasTile {
            if !self.isExpanded {
                self.onCollapseButton()
            }
        }
        self.hasTile = hasTile
    }
}

// MARK: - BHDetailsHeaderViewDelegate

extension BHInteractivePlayerViewController: BHDetailsHeaderViewDelegate {
    
    func detailsHeaderViewDidSelectUser(_ view: BHDetailsHeaderView) {
        self.dismiss(animated: true) {
            guard let user = self.post?.user else { return }
            self.openUser(user)
        }
    }
}
