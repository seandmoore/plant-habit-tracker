import Foundation
import Observation

/// Navigation state, and nothing else. The old `AppModel` also owned the catalog, the companion
/// transcript, and every service, which meant unrelated screens re-rendered on each other's
/// changes and there was no single place to reason about where the app was.
@MainActor
@Observable
final class AppRouter {
    enum Destination: String, CaseIterable, Identifiable, Hashable {
        case today
        case plants
        case scan
        case discover

        var id: Self { self }

        var title: String {
            switch self {
            case .today: "Today"
            case .plants: "My Plants"
            case .scan: "Scan"
            case .discover: "Discover"
            }
        }

        var symbolName: String {
            switch self {
            case .today: "sun.max.fill"
            case .plants: "leaf.fill"
            case .scan: "viewfinder"
            case .discover: "magnifyingglass"
            }
        }
    }

    var destination: Destination = .today
    var isCompanionPresented = false

    /// The plant the companion should ground its answers in, or nil for general help.
    private(set) var companionPlantID: UUID?

    func select(_ destination: Destination) {
        self.destination = destination
    }

    func presentCompanion(for plantID: UUID? = nil) {
        companionPlantID = plantID
        isCompanionPresented = true
    }

    /// A binding-friendly selection for `NavigationSplitView`, which works in optionals.
    var sidebarSelection: Destination? {
        get { destination }
        set { if let newValue { destination = newValue } }
    }
}
