import SwiftData
import SwiftUI

@main
struct PlantCompanionApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .task { await appModel.loadCatalog() }
        }
        .modelContainer(for: [UserPlant.self, CareEvent.self])
    }
}
