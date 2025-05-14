
import Foundation

class BHOffsetsManager {

    static var shared: BHOffsetsManager = BHOffsetsManager()
    
    var offsets: [BHOffset] = []
    
    // MARK: - Public
    
    func offset(for postId: String) -> BHOffset? {
        return offsets.first(where: { $0.id == postId })
    }

    func updateOffsets() {
        fetchStorageItems()
    }
    
    func insertOrUpdateOffset(_ offset: BHOffset) {
        if let row = offsets.firstIndex(where: {$0.id == offset.id}) {
            self.offsets[row] = offset
            self.updateStorageOffset(offset)
        } else {
            self.offsets.append(offset)
            self.insertStorageOffset(offset)
        }
    }

    func removeOffset(_ postId: String) {
        offsets.removeAll(where: { $0.id == postId })
        self.removeOffset(postId)
    }

    // MARK: - Storage Providers
    
    fileprivate func fetchStorageItems() {
        DataBaseManager.shared.fetchOffsets() { items in
            self.offsets = items
        }
    }

    fileprivate func fetchStorageOffset(_ id: String) -> BHOffset? {
        return DataBaseManager.shared.fetchOffset(with: id)
    }

    fileprivate func insertStorageOffset(_ offset: BHOffset) {
        if !DataBaseManager.shared.insertOrUpdateOffset(with: offset) {
            BHLog.w("\(#function) - failed to insert offset")
        }
    }

    fileprivate func updateStorageOffset(_ offset: BHOffset) {
        if !DataBaseManager.shared.updateOffset(with: offset) {
            BHLog.w("\(#function) - failed to update offset")
        }
    }

    fileprivate func removeStorageOffset(_ id: String) {
        if !DataBaseManager.shared.removeOffset(with: id) {
            BHLog.w("\(#function) - failed to remove offset")
        }
    }
}


