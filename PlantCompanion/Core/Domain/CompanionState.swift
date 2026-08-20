import Foundation

/// What the companion is doing. Lives in the domain rather than beside the ring that draws it,
/// so the conversation model does not depend on the view layer.
enum CompanionState: Hashable, Sendable {
    case idle
    case thinking
    case speaking

    var symbolName: String {
        switch self {
        case .idle: "leaf.fill"
        case .thinking: "ellipsis"
        case .speaking: "sparkles"
        }
    }
}
