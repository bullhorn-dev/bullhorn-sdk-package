
import Foundation
import UIKit

class BHCircularProgressView: UIView {
    
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    
    var lineWidth: CGFloat = 2.0 {
       didSet {
           backgroundLayer.lineWidth = lineWidth
           progressLayer.lineWidth = lineWidth
       }
    }
    
    var animationDuration: CGFloat = 1.0 {
       didSet {
           backgroundLayer.lineWidth = lineWidth
           progressLayer.lineWidth = lineWidth
       }
    }

    var trackColor: UIColor = .shadow().withAlphaComponent(0.25) {
       didSet {
           backgroundLayer.strokeColor = trackColor.cgColor
       }
    }

    var circleColor: UIColor = .onAccent() {
       didSet {
           progressLayer.strokeColor = circleColor.cgColor
       }
    }

    var progress: CGFloat = 0 {
       didSet {
           progressLayer.strokeEnd = progress
       }
    }
    
    // MARK: Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let circularPath = UIBezierPath(arcCenter: .zero, radius: self.frame.width / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)

        backgroundLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        
        backgroundLayer.frame = CGRect(x: frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height)
        progressLayer.frame = CGRect(x: frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height)
    }
    
    // MARK: - Private
    
    private func setup() {

        let circularPath = UIBezierPath(arcCenter: .zero, radius: self.frame.width / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)

        backgroundLayer.path = circularPath.cgPath
        backgroundLayer.strokeColor = trackColor.cgColor
        backgroundLayer.lineCap = CAShapeLayerLineCap.round
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = lineWidth

        layer.addSublayer(backgroundLayer)

        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = circleColor.cgColor
        progressLayer.lineCap = CAShapeLayerLineCap.round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeEnd = 0
        backgroundLayer.transform = CATransform3DMakeRotation(-(CGFloat.pi / 2), 0, 0, 1)
        progressLayer.transform = CATransform3DMakeRotation(-(CGFloat.pi / 2), 0, 0, 1)

        layer.addSublayer(progressLayer)
    }
    
    // MARK: - Public

    func setProgress(_ value: Float, animated: Bool, completion: (() -> Void)? = nil) {

        layoutIfNeeded()

        let value = CGFloat(min(value, 1.0))
        let oldValue = progressLayer.presentation()?.strokeEnd ?? progress

        progress = value
        progressLayer.strokeEnd = progress
        CATransaction.begin()

        let path = #keyPath(CAShapeLayer.strokeEnd)
        let fill = CABasicAnimation(keyPath: path)

        fill.fromValue = oldValue
        fill.toValue = value
        fill.duration = animationDuration
        CATransaction.setCompletionBlock(completion)
        progressLayer.add(fill, forKey: "fill")

        CATransaction.commit()
    }
}
