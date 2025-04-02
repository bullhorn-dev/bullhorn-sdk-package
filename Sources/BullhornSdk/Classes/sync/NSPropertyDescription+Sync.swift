import Foundation
import CoreData

private let SyncCustomLocalPrimaryKey: String = "sync.isPrimaryKey"
private let SyncCompatibilityCustomLocalPrimaryKey: String = "hyper.isPrimaryKey"
private let SyncCustomLocalPrimaryKeyValue: String = "YES"
private let SyncCustomLocalPrimaryKeyAlternativeValue: String = "true"

private let SyncCustomRemoteKey: String = "sync.remoteKey"
private let SyncCompatibilityCustomRemoteKey: String = "hyper.remoteKey"

private let PropertyMapperNonExportableKey: String = "sync.nonExportable"
private let PropertyMapperCompatibilityNonExportableKey: String = "hyper.nonExportable"

private let PropertyMapperCustomValueTransformerKey: String = "sync.valueTransformer"
private let PropertyMapperCompatibilityCustomValueTransformerKey: String = "hyper.valueTransformer"

extension NSPropertyDescription {

    func isCustomPrimaryKey() -> Bool {
        var keyName = self.userInfo?[SyncCustomLocalPrimaryKey] as? String
        if keyName == nil {
            keyName = self.userInfo?[SyncCompatibilityCustomLocalPrimaryKey] as? String
        }

        let hasCustomPrimaryKey: Bool = (keyName != nil &&
            (keyName == SyncCustomLocalPrimaryKeyValue || keyName == SyncCustomLocalPrimaryKeyAlternativeValue))

        return hasCustomPrimaryKey
    }

    func customKey() -> String? {
        var keyName = self.userInfo?[SyncCustomRemoteKey] as? String
        if keyName == nil {
            keyName = self.userInfo?[SyncCompatibilityCustomRemoteKey] as? String
        }

        return keyName
    }

    func shouldExportAttribute() -> Bool {
        var nonExportableKey = self.userInfo?[PropertyMapperNonExportableKey] as? String
        if nonExportableKey == nil {
            nonExportableKey = self.userInfo?[PropertyMapperCompatibilityNonExportableKey] as? String
        }

        let shouldExportAttribute: Bool = (nonExportableKey == nil)

        return shouldExportAttribute
    }

    func customTransformerName() -> String? {
        var keyName = self.userInfo?[PropertyMapperCustomValueTransformerKey] as? String
        if keyName == nil {
            keyName = self.userInfo?[PropertyMapperCompatibilityCustomValueTransformerKey] as? String
        }

        return keyName
    }
}

