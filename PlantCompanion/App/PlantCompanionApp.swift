import SwiftData
import SwiftUI

@main
struct PlantCompanionApp: App {
    private let container: ModelContainer
    @State private var appEnvironment: AppEnvironment
    @State private var router = AppRouter()
    @State private var store: PlantStore

    init() {
        let appEnvironment = AppEnvironment()
        let container: ModelContainer
        do {
            container = try ModelContainer(for: UserPlant.self, CareEvent.self)
        } catch {
            // Without a store there is no app; failing loudly beats running with silent data loss.
            fatalError("Could not open the plant database: \(error)")
        }

        self.container = container
        _appEnvironment = State(initialValue: appEnvironment)
        // Deliberately the container's own main context, the one @Query reads from, so a write
        // through the store is visible to every list immediately.
        _store = State(
            initialValue: PlantStore(
                context: container.mainContext,
                planner: appEnvironment.planner,
                notifications: appEnvironment.notifications
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(store)
                .environment(appEnvironment)
        }
        .modelContainer(container)
    }
}
