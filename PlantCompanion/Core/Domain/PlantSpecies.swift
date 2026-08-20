import Foundation

/// A catalog entry. Care values are conservative starting points the app adapts from what
/// someone records; they are not authoritative botanical guidance.
struct PlantSpecies: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let commonName: String
    let scientificName: String
    let summary: String
    let baselineWateringDays: Int
    let light: String
    let soil: String
    let humidity: String
    let environments: [PlantEnvironment]
    let toxicityNote: String?
    let symbolName: String

    /// Matches both the common and scientific name, which is what every search surface needs.
    func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return commonName.localizedCaseInsensitiveContains(trimmed)
            || scientificName.localizedCaseInsensitiveContains(trimmed)
    }
}
