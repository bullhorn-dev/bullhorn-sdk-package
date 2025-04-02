import Foundation
import CoreData

let SyncDefaultLocalPrimaryKey: String = "id"
let SyncDefaultLocalCompatiblePrimaryKey: String = "remoteID"
let SyncDefaultRemotePrimaryKey: String = "id"

extension NSEntityDescription {

    func sync_primaryKeyAttribute() -> NSAttributeDescription {
        var primaryKeyAttribute: NSAttributeDescription?

        for (key, property) in self.propertiesByName {
            if let attributeDescription = property as? NSAttributeDescription {
                if attributeDescription.isCustomPrimaryKey() {
                    primaryKeyAttribute = attributeDescription
                    break
                }

                if key == SyncDefaultLocalPrimaryKey || key == SyncDefaultLocalCompatiblePrimaryKey {
                    primaryKeyAttribute = attributeDescription
                }
            }
        }

        return primaryKeyAttribute ?? NSAttributeDescription()
    }

    func sync_localPrimaryKey() -> String {
        let primaryAttribute = self.sync_primaryKeyAttribute()
        let localKey = primaryAttribute.name

        return localKey
    }

    func sync_remotePrimaryKey() -> String {
        let primaryKeyAttribute = self.sync_primaryKeyAttribute()
        var remoteKey = primaryKeyAttribute.customKey()

        if remoteKey == nil {
            if primaryKeyAttribute.name == SyncDefaultLocalPrimaryKey || primaryKeyAttribute.name == SyncDefaultLocalCompatiblePrimaryKey {
                remoteKey = SyncDefaultRemotePrimaryKey
            } else {
                remoteKey = primaryKeyAttribute.name.hyp_snakeCase()
            }
        }

        return remoteKey!
    }
}

