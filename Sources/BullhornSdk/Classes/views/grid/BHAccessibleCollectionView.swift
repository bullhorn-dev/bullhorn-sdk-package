
import Foundation
import UIKit

class BHAccessibleCollectionView: UICollectionView {

    override func accessibilityElementCount() -> Int {

        guard let dataSource = dataSource else {
            return 0
        }

        let numberOfSections = dataSource.numberOfSections?(in: self) ?? 1
        var count = 0

        for section in 0..<numberOfSections {
            count += dataSource.collectionView(self, numberOfItemsInSection: section)
        }

        return count
    }
}
