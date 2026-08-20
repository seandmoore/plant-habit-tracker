import Foundation

enum ScanMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case species
    case health
    case both

    var id: Self { self }

    var title: String {
        switch self {
        case .species: "Species"
        case .health: "Health"
        case .both: "Both"
        }
    }
}

/// One scanner suggestion, matching `Contract/scan-candidate.schema.json`. Health results carry
/// no `scientificName`: they describe something to check, never a diagnosis.
struct ScanCandidate: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let scientificName: String?
    let confidence: Double
    let detail: String
    let source: String
}
