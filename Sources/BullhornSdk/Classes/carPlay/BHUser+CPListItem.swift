
import Foundation
import CarPlay
import SDWebImage

extension BHUser {
    
    func toCPListItem(with bundle: Bundle) -> CPListItem {
        
        let placeholderImage = UIImage(named: "ic_avatar_placeholder.png", in: bundle, with: nil)
        
        let item = CPListItem(text: fullName, detailText: categoryName, image: placeholderImage, accessoryImage: nil, accessoryType: .none)
        
        SDWebImageManager.shared.loadImage(with: coverUrl) { _, _, _ in
            //
        } completed: { img, data, error, _, finished, _ in
            if finished && error == nil {
                item.setImage(img)
            }
        }
        
        return item
    }
}


extension UICategoryModel {
    
    func toCPListItem() -> CPListItem {
        
        return CPListItem(text: category.name ?? "Undefined", detailText: nil, image: nil, accessoryImage: nil, accessoryType: .disclosureIndicator)
    }
}
