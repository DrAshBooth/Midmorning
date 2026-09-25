import Foundation
import SwiftData

/// Read and write access to `LocalSetting`, the device-only key-value row
/// `Local.store` holds (data-and-privacy spec, "Two store configurations in
/// one directory"). The app lock's own settings (`appLock.enabled`,
/// `appLock.faceOrTouchOnly`, `appLock.lockAfterSeconds`, the kept
/// enrolment-state hash) are the first rows to use this; a reminder switch
/// or any other device value uses the same two calls with its own key.
public extension RecordStore {
    /// The row's value for `key`, or `nil` when no row exists yet.
    func localSettingValue(forKey key: String) -> String? {
        var descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.value
    }

    /// Replaces the row for `key`, creating it on the first write.
    func setLocalSetting(key: String, value: String) throws {
        var descriptor = FetchDescriptor<LocalSetting>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.value = value
        } else {
            context.insert(LocalSetting(key: key, value: value))
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw Failure.saveFailed
        }
    }
}
