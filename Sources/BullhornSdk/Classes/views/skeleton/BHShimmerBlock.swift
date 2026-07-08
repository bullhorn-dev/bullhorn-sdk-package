
import Foundation
import UIKit

// MARK: - BHShimmerBlock

/// A single shimmering placeholder block with no external dependencies.
/// Compose several of these to build a skeleton layout. Colors default to the
/// SDK palette but should be tuned per theme if the contrast looks off.
final class BHShimmerBlock: UIView {

    private let gradient = CAGradientLayer()
    private static let animationKey = "bh.shimmer"

    /// Base (resting) block color.
    var baseColor: UIColor = .tertiary() { didSet { applyColors() } }
    /// Color of the moving highlight band.
    var highlightColor: UIColor = .cardBackground() { didSet { applyColors() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        clipsToBounds = true

        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.locations = [0.0, 0.5, 1.0]
        applyColors()
        layer.addSublayer(gradient)
    }

    private func applyColors() {
        gradient.colors = [baseColor.cgColor, highlightColor.cgColor, baseColor.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    func startAnimating() {
        stopAnimating()
        /// respect Reduce Motion: keep a static placeholder instead of a sweep
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1.0, -0.5, 0.0]
        anim.toValue = [1.0, 1.5, 2.0]
        anim.duration = 1.2
        anim.repeatCount = .infinity
        anim.isRemovedOnCompletion = false
        gradient.add(anim, forKey: Self.animationKey)
    }

    func stopAnimating() {
        gradient.removeAnimation(forKey: Self.animationKey)
    }
}
