import Foundation
import Observation

/// The app's composition root: it decides which implementation backs each capability and holds
/// nothing else. Splitting this out of the old `AppModel` means service wiring, navigation
/// state, and conversation state stop sharing one object.
@MainActor
@Observable
final class AppEnvironment {
    let catalog: any PlantCatalogService
    let identification: any IdentificationService
    let companion: any CompanionService
    let notifications: any NotificationScheduling
    let planner: WateringPlanner

    init(
        catalog: (any PlantCatalogService)? = nil,
        identification: (any IdentificationService)? = nil,
        companion: (any CompanionService)? = nil,
        notifications: any NotificationScheduling = LocalNotificationScheduler(),
        planner: WateringPlanner = WateringPlanner()
    ) {
        let proxyURL = ProxyConfiguration.baseURL()
        self.catalog = catalog ?? Self.makeCatalogService(proxyURL: proxyURL)
        self.identification = identification ?? Self.makeIdentificationService(proxyURL: proxyURL)
        self.companion = companion ?? CompanionServiceFactory.makeDefault()
        self.notifications = notifications
        self.planner = planner
    }

    /// Without a configured proxy the app scans locally with fixed results, so no photo is ever
    /// sent to an unverified destination.
    private static func makeIdentificationService(proxyURL: URL?) -> any IdentificationService {
        guard let proxyURL else { return MockIdentificationService() }
        return ProxyIdentificationService(baseURL: proxyURL)
    }

    private static func makeCatalogService(proxyURL: URL?) -> any PlantCatalogService {
        let bundled = BundledCatalogService()
        guard let proxyURL else { return bundled }
        return ResilientCatalogService(primary: ProxyCatalogService(baseURL: proxyURL), fallback: bundled)
    }
}
