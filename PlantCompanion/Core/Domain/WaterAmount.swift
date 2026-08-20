import Foundation

/// Parses the optional amount someone types when logging a watering.
enum WaterAmount {
    /// Accepts both decimal separators, and treats anything unparseable as "not recorded" —
    /// logging that you watered at all is the point, so a bad amount must never block the save.
    static func parse(_ input: String) -> Double? {
        let normalized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }
}
