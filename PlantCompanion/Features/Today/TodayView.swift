import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlantStore.self) private var store
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    if plants.isEmpty {
                        emptyState
                    } else {
                        careChecks
                        habitSummary
                    }
                }
                .plantReadableColumn()
            }
            .plantPage()
            .navigationTitle("Today")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.largeTitle.bold())
            Text("Care is an observation, not a perfect streak.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        PlantSection {
            ContentUnavailableView {
                Label("Grow your first collection", systemImage: "leaf.circle.fill")
            } description: {
                Text("Add a plant to start gentle care checks and watering history.")
            } actions: {
                Button("Open My Plants") { router.select(.plants) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var careChecks: some View {
        let queue = careQueue

        return PlantSection("Care checks") {
            ForEach(queue) { entry in
                RowDivider(isFirst: entry.id == queue.first?.id)

                HStack(spacing: 14) {
                    NavigationLink {
                        PlantDetailView(plant: entry.plant)
                    } label: {
                        PlantRow(plant: entry.plant, recommendation: entry.recommendation)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if entry.recommendation.needsAttention {
                        Button("Water", systemImage: "drop.fill") {
                            store.logWatering(for: entry.plant)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Water \(entry.plant.nickname)")
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private var habitSummary: some View {
        PlantSection("Last 7 days") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(wateringCount)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(wateringCount == 1 ? "watering logged" : "waterings logged")
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(PlantTheme.accent)
            }
            .accessibilityElement(children: .combine)

            Text("The history is here to reveal patterns—not to judge missed days.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var careQueue: [CareQueueEntry] {
        store.careQueue(plants)
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
