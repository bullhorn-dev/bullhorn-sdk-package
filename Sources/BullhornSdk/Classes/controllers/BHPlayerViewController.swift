
import UIKit
import Foundation

class BHPlayerViewController: BHPlayerBaseViewController {
    
    class var storyboardIndentifer: String { return String(describing: self) }
    
    @IBOutlet private(set) weak var contentStackView: UIStackView!
    @IBOutlet private(set) weak var topNavigationView: UIView!
    @IBOutlet private(set) weak var bottomNavigationView: UIView!
    @IBOutlet private(set) weak var nameView: UIView!
    @IBOutlet private(set) weak var titleView: UIView!
    @IBOutlet private(set) weak var controlsView: UIView!
    @IBOutlet private(set) weak var bottomView: UIView!
    @IBOutlet private(set) weak var transcriptButton: UIButton!
    @IBOutlet private(set) weak var transcriptView: UIView!
    @IBOutlet private(set) weak var transcriptTableView: UITableView!
    @IBOutlet private(set) weak var youtubeButton: UIButton!

    @IBOutlet var nameLabels: [UILabel]!
    @IBOutlet var titleLabels: [UILabel]!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BHLog.p("\(#function) - type: \(type)")
        
        nameView.backgroundColor = .primaryBackground()
        titleView.backgroundColor = .primaryBackground()
        controlsView.backgroundColor = .primaryBackground()
        titleLabels.forEach({ $0.textColor = .primary() })
        nameLabels.forEach({ $0.textColor = .primary() })
        playButtons.forEach({ $0.tintColor = .primary() })
        backwardButtons.forEach({ $0.tintColor = .primary() })
        forwardButtons.forEach({ $0.tintColor = .primary() })
        playbackSpeedButtons.forEach({ $0.tintColor = .primary() })
        playbackSpeedButtons.forEach({ $0.setTitleColor(.primary(), for: .normal) })
        sleepTimerButtons.forEach({ $0.tintColor = .primary() })
        bottomView.backgroundColor = .primaryBackground()

        nameLabels.forEach({ $0.font = .primaryButton() })
        titleLabels.forEach({ $0.font = .secondaryButton() })

        transcriptView.isHidden = true ///BHHybridPlayer.shared.isTranscriptActive
        transcriptButton.isHidden = true ///post?.hasTranscript == false
 
        youtubeButton.setTitle("YouTube", for: .normal)
        youtubeButton.backgroundColor = .clear
        youtubeButton.configuration?.baseForegroundColor = .primary()
        youtubeButton.titleLabel?.font = .fontWithName(.robotoRegular, size: 14)
        youtubeButton.setTitleColor(.playerOnDisplayBackground(), for: .normal)
        youtubeButton.isHidden = !hasYouTubeSocialLink()

        let bundle = Bundle.module
        let transcriptCellNib = UINib(nibName: "BHPlayerTranscriptCell", bundle: bundle)
        transcriptTableView.register(transcriptCellNib, forCellReuseIdentifier: BHPlayerTranscriptCell.reusableIndentifer)
        transcriptTableView.delegate = self
        transcriptTableView.dataSource = self
        transcriptTableView.reloadData()
        
        contentStackView.bringSubviewToFront(topNavigationView)
        contentStackView.bringSubviewToFront(bottomNavigationView)

        let tapContentViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapRegularView(_:)))
        imageLayerView.addGestureRecognizer(tapContentViewGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        updateTranscriptControls()
        youtubeButton.isHidden = !hasYouTubeSocialLink()        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - Overrides
    
    override func onStateChanged(_ state: PlayerState, stateFlags: PlayerStateFlags) {
        super.onStateChanged(state, stateFlags: stateFlags)
        
        guard let playerItem = BHHybridPlayer.shared.playerItem else { return }

        nameLabels.forEach({ $0.text = playerItem.post.userName })
        titleLabels.forEach({ $0.text = playerItem.post.title })
    }
        
    override func resetUI() {
        super.resetUI()

        nameLabels.forEach({ $0.attributedText = NSAttributedString(string: "") })
        titleLabels.forEach({ $0.attributedText = NSAttributedString(string: "") })
    }
    
    override func updateVideoLayer(_ isVideoAvailable: Bool) {
        super.updateVideoLayer(isVideoAvailable)
    }
    
    override func updateLayers() {
        super.updateLayers()

        if BHHybridPlayer.shared.isEnded() {
            videoView.isHidden = true
        } else {
            videoView.isHidden = !hasVideo
        }
    }
    
    override func onTranscriptChanged() {
        super.onTranscriptChanged()

        transcriptTableView.reloadData()
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
            
            transcriptTableView.reloadRows(at: Array(indexPathsToReload), with: .none)
            
            if !transcriptTableView.isDragging && !transcriptTableView.isDecelerating {
                transcriptTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        } else {
            selectedIndexPaths.removeAll()
            transcriptTableView.reloadData()
        }
    }
    
    override func updateSettingsControls() {
        super.updateSettingsControls()
        
        let sleepTimerEnabled = BHHybridPlayer.shared.getSleepTimerInterval() > 0
        sleepTimerButtons.forEach({ $0.tintColor = sleepTimerEnabled ? isFullscreen ? .playerOnDisplayBackground() : .primary() : .secondary() })
    }
    
    override func setupAccessibility() {
        super.setupAccessibility()
        
        youtubeButton.isAccessibilityElement = true
        youtubeButton.accessibilityTraits = .button
        youtubeButton.accessibilityLabel = "YouTube"
        youtubeButton.accessibilityValue = "external link"
    }
    
    override func onUserInterfaceRotated() {
        super.onUserInterfaceRotated()
        
        let sleepTimerEnabled = BHHybridPlayer.shared.getSleepTimerInterval() > 0
        
        if isFullscreen {
            nameView.isHidden = true
            titleView.isHidden = true
            controlsView.isHidden = true
            topNavigationView.isHidden = true
            bottomNavigationView.isHidden = true
            bottomView.isHidden = true
            titleLabels.forEach({ $0.textColor = .playerOnDisplayBackground() })
            nameLabels.forEach({ $0.textColor = .playerOnDisplayBackground() })
            playButtons.forEach({ $0.tintColor = .playerOnDisplayBackground() })
            forwardButtons.forEach({ $0.tintColor = .playerOnDisplayBackground() })
            backwardButtons.forEach({ $0.tintColor = .playerOnDisplayBackground() })
            playbackSpeedButtons.forEach({ $0.tintColor = .playerOnDisplayBackground() })
            playbackSpeedButtons.forEach({ $0.setTitleColor(.playerOnDisplayBackground(), for: .normal) })
            sleepTimerButtons.forEach({ $0.tintColor = sleepTimerEnabled ? .playerOnDisplayBackground() : .secondary() })
            positionLabels.forEach({ $0.textColor = .playerOnDisplayBackground() })
            durationLabels.forEach({ $0.textColor = .playerOnDisplayBackground() })

        } else {
            nameView.isHidden = false
            titleView.isHidden = false
            controlsView.isHidden = false
            topNavigationView.isHidden = false
            bottomNavigationView.isHidden = false
            bottomView.isHidden = false
            titleLabels.forEach({ $0.textColor = .primary() })
            nameLabels.forEach({ $0.textColor = .primary() })
            playButtons.forEach({ $0.tintColor = .primary() })
            forwardButtons.forEach({ $0.tintColor = .primary() })
            backwardButtons.forEach({ $0.tintColor = .primary() })
            playbackSpeedButtons.forEach({ $0.tintColor = .primary() })
            playbackSpeedButtons.forEach({ $0.setTitleColor(.primary(), for: .normal) })
            sleepTimerButtons.forEach({ $0.tintColor = sleepTimerEnabled ? .primary() : .secondary() })
            positionLabels.forEach({ $0.textColor = .primary() })
            durationLabels.forEach({ $0.textColor = .primary() })
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onTranscriptButton() {
        let isActive = BHHybridPlayer.shared.isTranscriptActive
        
        BHHybridPlayer.shared.isTranscriptActive = !isActive
        updateTranscriptControls()
        
        let position = BHHybridPlayer.shared.mediaPlayer?.currentTime() ?? -1
        refreshTranscriptForPosition(position)
    }

    @IBAction func onYouTubeButton() {
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .player, action: .ui, banner: .openYouTube, podcastId: playerItem?.post.userId, podcastTitle: playerItem?.post.userName, episodeId: playerItem?.post.postId, episodeTitle: playerItem?.post.title)
        BHTracker.shared.trackEvent(with: request)
        
        guard let urlString = post?.socialLinks?.youtube?.absoluteString else { return }
        let position = BHHybridPlayer.shared.currentPosition()
        var url: URL?
        
        if position > 0 {
            url = URL(string: "\(urlString)&t=\(Int(position))")
        } else {
            url = URL(string: urlString)
        }

        if let validUrl = url {
            BHHybridPlayer.shared.pause()
            openExternalLink(validUrl)
        }
    }

    fileprivate func updateTranscriptControls() {
        let font = UIFont.fontWithName(.robotoRegular, size: 20)
        let mediumConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize, weight: .medium, scale: .medium)
        
        if BHHybridPlayer.shared.isTranscriptActive {
            transcriptButton.setImage(UIImage(systemName: "doc.plaintext.fill")?.withConfiguration(mediumConfig), for: .normal)
            transcriptButton.accessibilityLabel = "Hide episode transcript"
            transcriptView.isHidden = false
            imageView.isHidden = true
        } else {
            transcriptButton.setImage(UIImage(systemName: "doc.plaintext")?.withConfiguration(mediumConfig), for: .normal)
            transcriptButton.accessibilityLabel = "Show episode transcript"
            transcriptView.isHidden = true
            imageView.isHidden = hasVideo || hasTile
        }
        
        transcriptButton.setTitle("", for: .normal)
        transcriptButton.backgroundColor = .clear
    }
    
    fileprivate func hasYouTubeSocialLink() -> Bool {
        return post?.socialLinks != nil && post?.socialLinks?.hasYouTube() == true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BHPlayerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BHHybridPlayer.shared.transcriptSegments.count == 0 && !activityIndicator.isAnimating {
            let bundle = Bundle.module
            let image = UIImage(named: "ic_list_placeholder.png", in: bundle, with: nil)
            tableView.setEmptyMessage("Transcript is not available", image: image)
        } else {
            tableView.restore()
        }
        
        return BHHybridPlayer.shared.transcriptSegments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BHPlayerTranscriptCell.reusableIndentifer, for: indexPath) as! BHPlayerTranscriptCell
        let segment = BHHybridPlayer.shared.transcriptSegments[indexPath.row]

        cell.isSelected = selectedIndexPaths.contains(indexPath)
        cell.postId = post?.id
        cell.segment = segment
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UserDefaults.standard.isInteractiveTranscriptsFeatureEnabled {
            guard let validPost = post else { return }
            let position = BHHybridPlayer.shared.transcriptSegments[indexPath.row].start
            
            if BHHybridPlayer.shared.isPostActive(validPost.id) {
                BHHybridPlayer.shared.seek(to: position, resume: true)
            }
        }
    }
}

