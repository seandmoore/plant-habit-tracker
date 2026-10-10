import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlantStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]
    @State private var lastLoggedPlantName: String?
    @State private var successfulLogCount = 0

    var body: some View {
        let queue = store.careQueue(plants)
        let due = queue.filter { $0.recommendation.needsAttention }
        let upcoming = queue.filter { !$0.recommendation.needsAttention }

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header
                    if plants.isEmpty {
                        emptyState
                    } else {
                        careOverview(checkCount: due.count)

                        if let lastLoggedPlantName {
                            savedConfirmation(for: lastLoggedPlantName)
                                .transition(PlantMotion.transition(reduceMotion: reduceMotion))
                        }

                        if !due.isEmpty {
                            careSection("Check in today", entries: due)
                        }
                        if !upcoming.isEmpty {
                            careSection("Next check-ins", entries: upcoming)
                        }
                        habitSummary
                    }
                }
                .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: successfulLogCount)
                .plantReadableColumn()
            }
            .plantPage()
            .plantSaveError()
            .navigationTitle("Today")
            .sensoryFeedback(.success, trigger: successfulLogCount)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("A little attention. A little growth.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        PlantSection {
            ContentUnavailableView {
                Label("Make room for a little green", systemImage: "leaf.circle")
            } description: {
                Text("Add your first plant for gentle care checks and a history that grows with you.")
            } actions: {
                Button("Open My Plants", systemImage: "plus") { router.select(.plants) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func careOverview(checkCount: Int) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 24))

        return PlantSection {
            Label("Your daily moment", systemImage: "sun.horizon")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PlantTheme.accent)

            layout {
                careMetric(value: checkCount, caption: "to check today", color: checkCount > 0 ? PlantTheme.warning : PlantTheme.accent)
                careMetric(value: plants.count, caption: "in your care", color: PlantTheme.accent)
            }

            Divider()

            Text(checkCount == 0
                 ? "No scheduled checks today. Take a moment to notice how your plants are doing."
                 : "Start with the soil. A care check is a reminder to observe, and water only if needed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func careMetric(value: Int, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func careSection(_ title: String, entries: [CareQueueEntry]) -> some View {
        PlantSection(title) {
            ForEach(entries) { entry in
                RowDivider(isFirst: entry.id == entries.first?.id)
                careRow(entry)
            }
        }
    }

    @ViewBuilder
    private func careRow(_ entry: CareQueueEntry) -> some View {
        if entry.recommendation.needsAttention {
            if dynamicTypeSize.isAccessibilitySize {
                stackedCareRow(entry)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        plantLink(entry)
                        logWaterButton(for: entry.plant)
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    stackedCareRow(entry)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            plantLink(entry)
        }
    }

    private func stackedCareRow(_ entry: CareQueueEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            plantLink(entry)
            logWaterButton(for: entry.plant)
        }
    }

    private func plantLink(_ entry: CareQueueEntry) -> some View {
        NavigationLink {
            PlantDetailView(plant: entry.plant)
        } label: {
            HStack(spacing: 8) {
                PlantRow(plant: entry.plant, recommendation: entry.recommendation)
                if !entry.recommendation.needsAttention {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func logWaterButton(for plant: UserPlant) -> some View {
        Button("Log water", systemImage: "drop") {
            logWatering(for: plant)
        }
        .buttonStyle(.bordered)
        .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: false)
        .accessibilityLabel("Log watering for \(plant.nickname)")
        .accessibilityHint("Records that you have watered this plant.")
    }

    private func savedConfirmation(for plantName: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            confirmationSymbol
                .font(.title3)
                .foregroundStyle(PlantTheme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Watering saved")
                    .font(.subheadline.weight(.semibold))
                Text("\(plantName)’s next check is updated.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button("Dismiss confirmation", systemImage: "xmark") {
                withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) {
                    lastLoggedPlantName = nil
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(16)
        .background(PlantTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var confirmationSymbol: some View {
        if reduceMotion {
            Image(systemName: "checkmark.circle.fill")
        } else {
            Image(systemName: "checkmark.circle.fill")
                .symbolEffect(.bounce, value: successfulLogCount)
        }
    }

    private var habitSummary: some View {
        PlantSection {
            HStack(alignment: .top, spacing: 14) {
                PlantIcon(symbolName: "chart.bar.xaxis")
                VStack(alignment: .leading, spacing: 6) {
                    Text("Over the last 7 days")
                        .font(.headline)
                    Text(wateringCount == 1 ? "1 watering logged" : "\(wateringCount) waterings logged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .accessibilityElement(children: .combine)

            Text("Find your rhythm. Your history is here to reveal patterns, with no perfect streak to keep.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func logWatering(for plant: UserPlant) {
        guard store.logWatering(for: plant) else { return }
        withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) {
            lastLoggedPlantName = plant.nickname
            successfulLogCount += 1
        }
    }

    private var wateringCount: Int {
        store.wateringCount(in: plants, days: 7)
    }

    private var greeting: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }
}
