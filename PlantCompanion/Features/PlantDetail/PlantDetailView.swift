import SwiftData
import SwiftUI

struct PlantDetailView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: UserPlant

    @State private var isLoggingWatering = false
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                nextCheck
                actions
                history
                if !plant.notes.isEmpty {
                    PlantSection("Notes") { Text(plant.notes) }
                }
            }
            .plantReadableColumn()
        }
        .plantPage()
        .navigationTitle(plant.nickname)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit", systemImage: "slider.horizontal.3") { isEditing = true }
            }
        }
        .sheet(isPresented: $isLoggingWatering) {
            WateringLogSheet(plant: plant)
        }
        .sheet(isPresented: $isEditing) {
            EditPlantSheet(plant: plant) { dismiss() }
        }
    }

    private var hero: some View {
        HStack(spacing: 18) {
            PlantArtwork(imageData: plant.photoData, size: 108)
            VStack(alignment: .leading, spacing: 5) {
                Text(plant.commonName)
                    .font(.title2.weight(.semibold))
                Text(plant.scientificName)
                    .italic()
                    .foregroundStyle(.secondary)
                Label(plant.environment.title, systemImage: plant.environment.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !plant.locationName.isEmpty {
                    Label(plant.locationName, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var nextCheck: some View {
        let recommendation = store.recommendation(for: plant)

        return PlantSection("Next care check") {
            StatusPill(recommendation: recommendation)
            Text(recommendation.reason)
                .foregroundStyle(.secondary)
            Label(
                "About every \(recommendation.intervalDays) days under the recorded conditions",
                systemImage: "calendar.badge.clock"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Water now", systemImage: "drop.fill") { store.logWatering(for: plant) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Button("Add details", systemImage: "square.and.pencil") { isLoggingWatering = true }
                .buttonStyle(.bordered)
                .controlSize(.large)
            Button("Ask companion", systemImage: "sparkles") { router.presentCompanion(for: plant.id) }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var history: some View {
        let events = plant.sortedCareEvents

        return PlantSection("Care history") {
            if events.isEmpty {
                Text("No care has been logged yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    RowDivider(isFirst: event.id == events.first?.id)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: event.kind.symbolName)
                            .foregroundStyle(PlantTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.kind.title).font(.headline)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let measurement = event.measurement {
                                Text(measurement).font(.subheadline)
                            }
                            if !event.note.isEmpty {
                                Text(event.note).font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
