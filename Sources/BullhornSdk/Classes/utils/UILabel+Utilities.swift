import UIKit
import Foundation

extension UILabel {

    func addCharacterSpacing(kernValue: Double = 3) {

        if let labelText = text, labelText.isEmpty == false {
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(.kern,
                                          value: kernValue,
                                          range: NSRange (location: 0, length: attributedString.length - 1))
            attributedText = attributedString
        }
    }

    /// Calculates the required height for the label given its current text, font, width, and scaling properties.

    func requiredHeight(_ width: CGFloat, numberOfLines: Int = 0) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = numberOfLines
        label.lineBreakMode = lineBreakMode
        label.font = font
        label.text = text
        label.attributedText = attributedText
        label.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        label.minimumScaleFactor = minimumScaleFactor

        label.sizeToFit()

        return ceil(label.frame.height)
    }
}
