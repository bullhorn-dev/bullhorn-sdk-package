
import UIKit
import Foundation

extension UIRefreshControl {

    func resetUIState() {

        if isRefreshing {
            beginRefreshing()
        }
        else {
            beginRefreshing()
            endRefreshing()
        }
    }
}
