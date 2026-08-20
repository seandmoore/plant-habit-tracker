import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        @Bindable var router = router

        Group {
            if hasCompletedOnboarding {
                navigation
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                    router.select(.plants)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if hasCompletedOnboarding {
                CompanionRing(action: { router.presentCompanion() })
                    .padding(20)
            }
        }
        .sheet(isPresented: $router.isCompanionPresented) {
            CompanionSheet(plantID: router.companionPlantID)
                .presentationDetents([.medium, .large])
        }
    }

    /// iPhone gets tabs; iPad and Mac get a sidebar. Both drive the same destinations.
    @ViewBuilder
    private var navigation: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            tabNavigation
        } else {
            splitNavigation
        }
        #else
        splitNavigation
        #endif
    }

    private var tabNavigation: some View {
        @Bindable var router = router

        return TabView(selection: $router.destination) {
            Tab(AppRouter.Destination.today.title, systemImage: AppRouter.Destination.today.symbolName, value: .today) {
                TodayView()
            }
            Tab(AppRouter.Destination.plants.title, systemImage: AppRouter.Destination.plants.symbolName, value: .plants) {
                PlantsView()
            }
            Tab(AppRouter.Destination.scan.title, systemImage: AppRouter.Destination.scan.symbolName, value: .scan) {
                ScannerView()
            }
            Tab(AppRouter.Destination.discover.title, systemImage: AppRouter.Destination.discover.symbolName, value: .discover) {
                DiscoverView()
            }
        }
    }

    private var splitNavigation: some View {
        @Bindable var router = router

        return NavigationSplitView {
            List(AppRouter.Destination.allCases, selection: $router.sidebarSelection) { destination in
                Label(destination.title, systemImage: destination.symbolName)
                    .tag(destination)
            }
            .navigationTitle("Plant Companion")
        } detail: {
            switch router.destination {
            case .today: TodayView()
            case .plants: PlantsView()
            case .scan: ScannerView()
            case .discover: DiscoverView()
            }
        }
    }
}
