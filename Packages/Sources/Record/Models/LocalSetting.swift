import Foundation
import SwiftData

/// One row per device-only key, held in `Local.store` only. Not one of the
/// sixteen neutral CKRecord types: `Local.store` never syncs, so this type
/// never becomes a CKRecord and needs no neutral name of its own
/// (data-and-privacy spec, "Two store configurations in one directory").
/// Holds every value in the "Device" column of "What syncs and what stays on
/// the device", such as the app lock, the reminder switches, the install id,
/// the sync choice and the Diagnostics counts.
@Model
public final class LocalSetting {
    public var id: UUID = UUID()
    public var key: String = ""
    public var value: String = ""

    public init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}
