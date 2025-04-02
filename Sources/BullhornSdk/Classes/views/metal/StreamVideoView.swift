import UIKit
import Metal
import MetalKit

final class StreamVideoView: UIView {

    var width: Double = 1 {
        didSet { updateView() }
    }

    var height: Double = 1 {
        didSet { updateView() }
    }
    
    private var mtkView: MTKView?
    
    // MARK: - Initialization
    
    init() {
        super.init(frame: .zero)

//        self.mtkView = reactNativeManager?.sessionChannel.streamingClient?.streamPlayer?.getVideoLayer()

        self.backgroundColor = .clear
        self.sizeToFit()

        configureVideoLayer()
        updateView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .clear
        self.sizeToFit()

        configureVideoLayer()
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func configureVideoLayer() {
        if let validMTKView = mtkView {
            self.addSubview(validMTKView)
        }
    }
        
    // MARK: - Private
    
    private func updateView() {

        let videoFrame = CGRect(origin: .zero, size: CGSize(width: width, height: height))

        self.frame = videoFrame
        self.mtkView?.frame = videoFrame
        
        layoutSubviews()
    }
}

// MARK: - MTVideoViewDelegate

extension StreamVideoView: MTVideoViewDelegate {

    func videoView(_ videoView: MTVideoView, didChangeVisibility hasVideo: Bool) {
        self.isHidden = !hasVideo
    }

    func videoView(_ videoView: MTVideoView, didChangeVideoSize size: CGSize) {}
}
