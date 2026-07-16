
import UIKit
import Foundation

/// Flow layout that pins the items of every row to the leading edge.
///
/// `UICollectionViewFlowLayout` (especially in self-sizing mode) distributes
/// the leftover horizontal space inside a row, so a row that is not full
/// ends up shifted or centered — a single item in a section is the extreme
/// case. This subclass rebuilds the x-origins of every row so that items
/// always start at `sectionInset.left` and follow each other with the
/// inter-item spacing, regardless of how many items the row contains.
///
/// Section insets and spacing are resolved through
/// `UICollectionViewDelegateFlowLayout` when the delegate implements the
/// corresponding methods, falling back to the layout's own properties.
final class BHLeftAlignedFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        /// Copy to avoid mutating the layout's cached attributes
        let attributes = superAttributes.map { $0.copy() as! UICollectionViewLayoutAttributes }

        /// Only cells are re-aligned; headers/footers keep their frames
        let cellAttributes = attributes.filter { $0.representedElementCategory == .cell }

        /// Group cells into rows: items of the same row share the same midY.
        /// The rect always spans the full collection view width, so every
        /// cell of a row intersecting the rect vertically is present here.
        let rows = Dictionary(grouping: cellAttributes) { $0.center.y.rounded() }

        for row in rows.values {
            guard let section = row.first?.indexPath.section else { continue }

            let inset = resolvedSectionInset(for: section)
            let spacing = resolvedInteritemSpacing(for: section)

            var originX = inset.left
            for attribute in row.sorted(by: { $0.indexPath.item < $1.indexPath.item }) {
                attribute.frame.origin.x = originX
                originX += attribute.frame.width + spacing
            }
        }

        return attributes
    }

    // MARK: - Delegate-aware metrics

    private var flowDelegate: UICollectionViewDelegateFlowLayout? {
        return collectionView?.delegate as? UICollectionViewDelegateFlowLayout
    }

    private func resolvedSectionInset(for section: Int) -> UIEdgeInsets {
        guard let collectionView = collectionView,
              let inset = flowDelegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) else {
            return sectionInset
        }
        return inset
    }

    private func resolvedInteritemSpacing(for section: Int) -> CGFloat {
        guard let collectionView = collectionView,
              let spacing = flowDelegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) else {
            return minimumInteritemSpacing
        }
        return spacing
    }
}

