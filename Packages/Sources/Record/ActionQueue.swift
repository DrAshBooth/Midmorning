import Foundation

/// One action a notification handler queued while it could not open the
/// store (widgets-and-intents spec, "The action queue"; reminders spec,
/// "Actions on a planned meal reminder": "The handler MUST write the action
/// to the action queue file."). Six values only, and never a slot label.
public struct QueuedAction: Sendable, Equatable, Codable {
    public enum Kind: String, Sendable, Equatable, Codable {
        case skipped, snooze
    }

    public var kind: Kind
    public var dayKey: String
    public var slotIndex: Int
    /// "HH:mm".
    public var plannedTime: String
    /// The snooze count after this action; unused for `.skipped`.
    public var snoozeCount: Int
    public var moment: Date

    public init(kind: Kind, dayKey: String, slotIndex: Int, plannedTime: String, snoozeCount: Int, moment: Date) {
        self.kind = kind
        self.dayKey = dayKey
        self.slotIndex = slotIndex
        self.plannedTime = plannedTime
        self.snoozeCount = snoozeCount
        self.moment = moment
    }
}

/// The queue file's codec (widgets-and-intents spec: "The queue file MUST
/// carry a format version."). A notification handler calls only this
/// codec, never `RecordStore`: encoding and decoding touch no store file, so
/// this runs safely from a handler that must not open the store.
public enum ActionQueueCodec {
    public static let currentFormatVersion = 1

    private struct Envelope: Codable {
        var formatVersion: Int
        var actions: [QueuedAction]
    }

    /// `[]` for empty data, and for a format version this build does not
    /// know (widgets-and-intents spec: "The app MUST discard a queue file
    /// whose format version it does not know.").
    public static func decode(_ data: Data) -> [QueuedAction] {
        guard !data.isEmpty else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(Envelope.self, from: data), envelope.formatVersion == currentFormatVersion else { return [] }
        return envelope.actions
    }

    public static func encode(_ actions: [QueuedAction]) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(Envelope(formatVersion: currentFormatVersion, actions: actions))) ?? Data()
    }

    /// `actions` with `action` appended.
    public static func appending(_ action: QueuedAction, to data: Data) -> Data {
        encode(decode(data) + [action])
    }
}
