import CryptoKit
import Foundation

/// A JSON value the canonical-JSON writer can render. The content version
/// requirement needs a hash that is stable across machines and Swift
/// versions, so this type renders JSON itself instead of relying on
/// `JSONEncoder`'s key order, which Foundation does not promise to sort.
public indirect enum JSONValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
}

/// Canonical JSON for the content bundle hash. The content spec fixes the
/// rule: sort keys, use no whitespace outside strings, and use UTF-8.
public enum CanonicalJSON {
    /// Renders `value` as canonical JSON text.
    public static func string(from value: JSONValue) -> String {
        var out = ""
        write(value, into: &out)
        return out
    }

    /// The SHA-256 of the canonical JSON text, as lowercase hex.
    public static func sha256Hex(of value: JSONValue) -> String {
        let text = string(from: value)
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func write(_ value: JSONValue, into out: inout String) {
        switch value {
        case .string(let s):
            writeString(s, into: &out)
        case .int(let n):
            out += String(n)
        case .bool(let b):
            out += b ? "true" : "false"
        case .array(let items):
            out += "["
            for (index, item) in items.enumerated() {
                if index > 0 { out += "," }
                write(item, into: &out)
            }
            out += "]"
        case .object(let fields):
            out += "{"
            for (index, key) in fields.keys.sorted().enumerated() {
                if index > 0 { out += "," }
                writeString(key, into: &out)
                out += ":"
                write(fields[key]!, into: &out)
            }
            out += "}"
        }
    }

    private static func writeString(_ s: String, into out: inout String) {
        out += "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        out += "\""
    }
}
