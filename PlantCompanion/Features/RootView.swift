import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        @Bindable var appModel = appModel

        Group {
            if hasCompletedOnboarding {
                mainNavigation
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                    appModel.selectedDestination = .plants
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if hasCompletedOnboarding {
                CompanionRing(state: appModel.companionState) {
                    appModel.presentCompanion()
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $appModel.isCompanionPresented) {
            CompanionSheet()
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var mainNavigation: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            compactNavigation
        } else {
            wideNavigation
        }
        #else
        wideNavigation
        #endif
    }

    private var compactNavigation: some View {
        @Bindable var appModel = appModel

        return TabView(selection: $appModel.selectedDestination) {
            Tab(AppModel.Destination.today.title, systemImage: AppModel.Destination.today.symbol, value: .today) {
                TodayView()
            }
            Tab(AppModel.Destination.plants.title, systemImage: AppModel.Destination.plants.symbol, value: .plants) {
                PlantsView()
            }
            Tab(AppModel.Destination.scan.title, systemImage: AppModel.Destination.scan.symbol, value: .scan) {
                ScannerView()
            }
            Tab(AppModel.Destination.discover.title, systemImage: AppModel.Destination.discover.symbol, value: .discover) {
                DiscoverView()
            }
        }
    }

    private var wideNavigation: some View {
        @Bindable var appModel = appModel

        return NavigationSplitView {
            List(AppModel.Destination.allCases, selection: sidebarSelection) { destination in
                Label(destination.title, systemImage: destination.symbol)
                    .tag(destination)
            }
            .navigationTitle("Plant Companion")
        } detail: {
            switch appModel.selectedDestination {
            case .today: TodayView()
            case .plants: PlantsView()
            case .scan: ScannerView()
            case .discover: DiscoverView()
            }
        }
    }

    private var sidebarSelection: Binding<AppModel.Destination?> {
        Binding(
            get: { appModel.selectedDestination },
            set: { newValue in
                if let newValue { appModel.selectedDestination = newValue }
            }
        )
    }
}
