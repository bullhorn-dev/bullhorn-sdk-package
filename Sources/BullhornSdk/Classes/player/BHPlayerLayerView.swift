import UIKit
import AVFoundation
import SDWebImage

/// Video surface with a built-in cover image.
///
/// Behaviour:
///  - Audio episode  (isVideo = false): cover always visible, AVPlayerLayer hidden.
///  - Video episode  (isVideo = true):  cover shown until AVPlayerLayer.readyForDisplay,
///                                      then crossfades to video.
final class BHPlayerLayerView: UIView {

    // MARK: - Layer

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var avPlayerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    // MARK: - Public

    var videoGravity: AVLayerVideoGravity {
        get { avPlayerLayer.videoGravity }
        set { avPlayerLayer.videoGravity = newValue }
    }

    /// Set once at init time; drives cover-vs-video logic.
    let isVideo: Bool

    /// Duration of the crossfade from cover to first video frame.
    var transitionDuration: TimeInterval = 0.25

    // MARK: - Private

    private let coverView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .black
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var isObservingLayer = false

    // MARK: - Init

    init(isVideo: Bool = false,
         videoGravity: AVLayerVideoGravity = .resizeAspect) {
        self.isVideo = isVideo
        super.init(frame: .zero)
        avPlayerLayer.videoGravity = videoGravity
        setup()
    }

    required init?(coder: NSCoder) {
        self.isVideo = false
        super.init(coder: coder)
        setup()
    }

    deinit {
        removeLayerObserver()
    }

    // MARK: - Public API

    func setCover(url: URL?) {
        coverView.sd_setImage(with: url)
    }

    func setCover(image: UIImage?) {
        coverView.image = image
    }

    /// Attach an AVPlayer so video frames start rendering.
    func connect(to player: AVPlayer) {
        avPlayerLayer.player = player

        if isVideo {
            // Reset: show cover while waiting for first frame.
            showCover(animated: false)
            addLayerObserver()
        }
    }

    /// Detach the player (e.g. before going to background).
    func disconnect() {
        removeLayerObserver()
        avPlayerLayer.player = nil

        if isVideo {
            // Show cover immediately — video surface is gone.
            showCover(animated: false)
        }
    }
    
    func reset() {
        guard isVideo else { return }
        removeLayerObserver()
        showCover(animated: false)
        addLayerObserver()
    }

    // MARK: - Private setup

    private func setup() {
        backgroundColor = .clear

        addSubview(coverView)
        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: topAnchor),
            coverView.bottomAnchor.constraint(equalTo: bottomAnchor),
            coverView.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        coverView.alpha = 1
    }

    // MARK: - Cover visibility

    private func showCover(animated: Bool) {
        if animated {
            UIView.animate(withDuration: transitionDuration) {
                self.coverView.alpha = 1
            }
        } else {
            coverView.alpha = 1
        }
    }

    private func hideCover(animated: Bool) {
        guard isVideo else { return }   // never hide cover for audio

        if animated {
            UIView.animate(withDuration: transitionDuration) {
                self.coverView.alpha = 0
            }
        } else {
            coverView.alpha = 0
        }
    }

    // MARK: - KVO

    private func addLayerObserver() {
        guard !isObservingLayer else { return }
        avPlayerLayer.addObserver(self,
                                  forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay),
            options: [.new], context: nil)
        isObservingLayer = true
    }

    private func removeLayerObserver() {
        guard isObservingLayer else { return }
        avPlayerLayer.removeObserver(self,
                                     forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay))
        isObservingLayer = false
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(AVPlayerLayer.isReadyForDisplay) else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if avPlayerLayer.isReadyForDisplay {
            DispatchQueue.main.async { self.hideCover(animated: true) }
        }
    }
}
