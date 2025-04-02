
import Foundation
import CarPlay
import SDWebImage

extension BHPost {
    
    func toCPListItem(with bundle: Bundle) -> CPListItem {
        
        let placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        let accessoryType: CPListItemAccessoryType = (isDownloaded || isRadioStream()) ? .cloud : .none
        let accessoryImage = isDownloaded ? UIImage(systemName: "arrow.down.circle.fill") : (isRadioStream() ? UIImage(systemName: "radio") : nil)
        
        let item = CPListItem(text: title, detailText: user.fullName, image: placeholderImage, accessoryImage: accessoryImage, accessoryType: accessoryType)
        
        SDWebImageManager.shared.loadImage(with: user.coverUrl) { _, _, _ in
            //
        } completed: { img, data, error, _, finished, _ in
            if finished && error == nil {
                item.setImage(img)
            }
        }
        
        return item
    }
}
