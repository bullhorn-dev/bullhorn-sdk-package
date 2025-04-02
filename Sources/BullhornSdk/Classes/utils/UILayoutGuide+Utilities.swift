
import UIKit
import Foundation

extension UILayoutGuide {

    func addAnchorsToSelfEdges(for view: UIView, edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero) {

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(anchorsToSelfEdges(for: view, edges: edges, insets: insets))
    }

    func anchorsToSelfEdges(for view: UIView, edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {

        var constraints = [NSLayoutConstraint]()

        if edges.contains(.top) {
            constraints.append(view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top))
        }

        if edges.contains(.bottom) {
            constraints.append(view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: insets.bottom))
        }

        if edges.contains(.left) {
            constraints.append(view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left))
        }

        if edges.contains(.right) {
            constraints.append(view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: insets.right))
        }

        return constraints
    }
}
