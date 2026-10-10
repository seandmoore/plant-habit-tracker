import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    router.select(.plants)
                    withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .tint(PlantTheme.accent)
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
                screen(.today)
            }
            Tab(AppRouter.Destination.plants.title, systemImage: AppRouter.Destination.plants.symbolName, value: .plants) {
                screen(.plants)
            }
            Tab(AppRouter.Destination.scan.title, systemImage: AppRouter.Destination.scan.symbolName, value: .scan) {
                screen(.scan)
            }
            Tab(AppRouter.Destination.discover.title, systemImage: AppRouter.Destination.discover.symbolName, value: .discover) {
                screen(.discover)
            }
        }
    }

    private var splitNavigation: some View {
        @Bindable var router = router

        return NavigationSplitView {
            List(AppRouter.Destination.allCases, selection: $router.sidebarSelection) { destination in
                Label(destination.title, systemImage: destination.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .tag(destination)
            }
            .listStyle(.sidebar)
            .navigationTitle("Plant Companion")
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            screen(router.destination)
        }
    }

    private func screen(_ destination: AppRouter.Destination) -> some View {
        Group {
            switch destination {
            case .today: TodayView()
            case .plants: PlantsView()
            case .scan: ScannerView()
            case .discover: DiscoverView()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Place the companion inside each tab's safe area, above its native tab bar.
            CompanionRing(action: { router.presentCompanion() })
                .padding(16)
        }
    }
}
