
import Foundation
import CarPlay
import SDWebImage

extension BHPost {
    
    func toCPListItem(with bundle: Bundle) -> CPListItem {
        
        let placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)

        let accessoryType: CPListItemAccessoryType = (isDownloaded || isRadioStream() || isLiveStream()) ? .cloud : .none
        var accessoryImage: UIImage? = nil
        
        if isDownloaded {
            accessoryImage = UIImage(systemName: "arrow.down.circle.fill")
        } else if isRadioStream() || isLiveStream() {
            accessoryImage = UIImage(systemName: "dot.radiowaves.forward")
        }
        
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
