import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    if plants.isEmpty {
                        emptyState
                    } else {
                        dueSection
                        habitSection
                    }
                }
                .padding()
                .padding(.bottom, 80)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
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
                Button("Open My Plants") { appModel.selectedDestination = .plants }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var dueSection: some View {
        PlantSection("Care checks") {
            ForEach(sortedRecommendations, id: \.plant.id) { item in
                NavigationLink {
                    PlantDetailView(plant: item.plant)
                } label: {
                    HStack(spacing: 14) {
                        PlantArtwork(imageData: item.plant.photoData, size: 62)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.plant.nickname)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            StatusPill(recommendation: item.recommendation)
                        }
                        Spacer()
                        if item.recommendation.status != .upcoming {
                            Button("Water", systemImage: "drop.fill") {
                                water(item.plant)
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Water \(item.plant.nickname)")
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if item.plant.id != sortedRecommendations.last?.plant.id {
                    Divider()
                }
            }
        }
    }

    private var habitSection: some View {
        PlantSection("Last 7 days") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(recentWateringCount)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(recentWateringCount == 1 ? "watering logged" : "waterings logged")
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(PlantTheme.accent)
            }
            Text("The history is here to reveal patterns—not to judge missed days.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var sortedRecommendations: [(plant: UserPlant, recommendation: CareRecommendation)] {
        plants
            .map { ($0, appModel.recommendationEngine.wateringRecommendation(for: $0, asOf: .now)) }
            .sorted {
                if $0.1.status != $1.1.status { return $0.1.status < $1.1.status }
                return $0.1.dueDate < $1.1.dueDate
            }
    }

    private var recentWateringCount: Int {
        let start = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return plants.flatMap(\.careEvents).filter { $0.kind == .watered && $0.timestamp >= start }.count
    }

    private var greeting: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private func water(_ plant: UserPlant) {
        let event = CareEvent(kind: .watered)
        modelContext.insert(event)
        plant.careEvents.append(event)
        try? modelContext.save()
        Task { try? await appModel.scheduleReminder(for: plant) }
    }
}
