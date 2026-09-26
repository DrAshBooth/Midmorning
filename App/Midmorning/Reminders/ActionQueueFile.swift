import Foundation
import Record

/// Reads and writes the action queue file in the App Group container
/// (widgets-and-intents spec, "The action queue"). Every call here is plain
/// file I/O through `ActionQueueCodec`; nothing opens the store, so a
/// notification-action handler can call `append` safely while the app's
/// store is unreadable (app-lock spec, "A new entry before authentication":
/// the handler "MUST NOT open the store").
enum ActionQueueFile {
    /// Appends `action` to the queue file, creating it if it does not exist.
    /// Silently does nothing when the App Group container is unreachable
    /// (the notification-extension sandbox always has it; a test host might
    /// not).
    static func append(_ action: QueuedAction) {
        guard let url = StoreLocation.actionQueueURL() else { return }
        let existing = (try? Data(contentsOf: url)) ?? Data()
        let updated = ActionQueueCodec.appending(action, to: existing)
        try? updated.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
        try? FileProtection.protectSideFile(url)
    }

    /// Every queued action, or `[]` when the file is absent or unreadable.
    static func readAll() -> [QueuedAction] {
        guard let url = StoreLocation.actionQueueURL(), let data = try? Data(contentsOf: url) else { return [] }
        return ActionQueueCodec.decode(data)
    }

    /// Empties the queue file (widgets-and-intents spec: "The app MUST then
    /// empty the queue.").
    static func clear() {
        guard let url = StoreLocation.actionQueueURL() else { return }
        try? ActionQueueCodec.encode([]).write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
        try? FileProtection.protectSideFile(url)
    }

    /// Applies every queued action through `store`, in order, then empties
    /// the queue (widgets-and-intents spec, "The action queue": "the app
    /// MUST apply the queue through the store in order... The app MUST then
    /// empty the queue."). Throws, and keeps the queue, when the store
    /// cannot write. Answers the actions the store applied.
    @MainActor
    @discardableResult
    static func drain(into store: RecordStore, currentRecordDayKey: String) throws -> [QueuedAction] {
        let actions = readAll()
        guard !actions.isEmpty else { return [] }
        let applied = try store.applyQueuedActions(actions, currentRecordDayKey: currentRecordDayKey)
        clear()
        return applied
    }
}
