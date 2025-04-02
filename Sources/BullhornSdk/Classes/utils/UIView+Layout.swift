import UIKit
import Foundation

extension UIView {

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
            constraints.append(view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom))
        }

        if edges.contains(.left) {
            constraints.append(view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left))
        }

        if edges.contains(.right) {
            constraints.append(view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right))
        }

        return constraints
    }

    func constraint(for firstAttribute: NSLayoutConstraint.Attribute, firstItem: AnyObject?) -> NSLayoutConstraint? {

        let filteredConstraints = constraints.filter { $0.firstAttribute == firstAttribute && $0.firstItem === firstItem }
        return filteredConstraints.first
    }

    func constraint(for firstAttribute: NSLayoutConstraint.Attribute, firstItem: AnyObject?, secondItem: AnyObject?, secontAttribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint? {

        let filteredConstraints = constraints.filter {
            $0.firstAttribute == firstAttribute &&
            $0.firstItem === firstItem &&
            $0.secondItem === secondItem &&
            (secontAttribute != nil ? ($0.secondAttribute == (secontAttribute ?? .notAnAttribute)) : true)
        }

        return filteredConstraints.first
    }
    
    func addBottomBorder(width: Double = 0.5) {
        let bottomBorder = CALayer()
    
        bottomBorder.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        bottomBorder.backgroundColor = UIColor.divider().cgColor
        layer.addSublayer(bottomBorder)
    }
    
    var parentViewController: UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.parentViewController
        } else {
            return nil
        }
    }
}

extension UIView {
    
    enum ViewSide {
        case left, right, top, bottom
    }
    
    func addBorder(toSide side: ViewSide, withColor color: CGColor, andThickness thickness: CGFloat) {
        
        let border = CALayer()
        border.backgroundColor = color
        
        switch side {
        case .left: border.frame = CGRect(x: frame.minX, y: frame.minY, width: thickness, height: frame.height); break
        case .right: border.frame = CGRect(x: frame.maxX, y: frame.minY, width: thickness, height: frame.height); break
        case .top: border.frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: thickness); break
        case .bottom: border.frame = CGRect(x: frame.minX, y: frame.maxY, width: frame.width, height: thickness); break
        }
        
        layer.addSublayer(border)
    }
}
