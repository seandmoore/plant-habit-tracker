import SwiftData
import SwiftUI

struct PlantDetailView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var plant: UserPlant

    @State private var isLoggingWatering = false
    @State private var isEditing = false
    @State private var wateringConfirmation = 0
    @State private var showsWateringConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                nextCheck
                actions
                history
                if !plant.notes.isEmpty {
                    PlantSection("Your notes") {
                        Text(plant.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }
            .plantReadableColumn()
        }
        .plantPage()
        .plantSaveError()
        .navigationTitle(plant.nickname)
        .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: plant.careEvents.count)
        .sensoryFeedback(.success, trigger: wateringConfirmation)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit plant", systemImage: "slider.horizontal.3") { isEditing = true }
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 20) {
                PlantArtwork(imageData: plant.photoData, size: 112)
                plantIdentity
                    .fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: 18) {
                PlantArtwork(imageData: plant.photoData, size: 96)
                plantIdentity
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plantIdentity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plant.commonName)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(plant.scientificName)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
            Label(plant.environment.title, systemImage: plant.environment.symbolName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !plant.locationName.isEmpty {
                Label(plant.locationName, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nextCheck: some View {
        let recommendation = store.recommendation(for: plant)

        return PlantSection("Next care check") {
            StatusPill(recommendation: recommendation)
            Text(recommendation.reason)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            Label(
                "About every \(recommendation.intervalDays) days under the recorded conditions",
                systemImage: "calendar.badge.clock"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: logWatering) {
                Label("Log watering", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Records that you watered this plant now.")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    detailButton
                    companionButton
                }
                .fixedSize(horizontal: true, vertical: false)

                VStack(alignment: .leading, spacing: 12) {
                    detailButton
                    companionButton
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if showsWateringConfirmation {
                Label {
                    Text("Watering saved. Your next check is updated.")
                } icon: {
                    if reduceMotion {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolEffect(.bounce, value: wateringConfirmation)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(PlantTheme.accent)
                .transition(PlantMotion.transition(reduceMotion: reduceMotion))
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailButton: some View {
        Button("Add watering details", systemImage: "square.and.pencil") {
            isLoggingWatering = true
        }
    }

    private var companionButton: some View {
        Button("Ask companion", systemImage: "bubble.left.and.bubble.right") {
            router.presentCompanion(for: plant.id)
        }
    }

    private var history: some View {
        let events = plant.sortedCareEvents

        return PlantSection("Care history") {
            if events.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    PlantIcon(symbolName: "clock.arrow.circlepath")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Every little care counts")
                            .font(.headline)
                        Text("Log your first watering to start this plant’s story.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(events) { event in
                    RowDivider(isFirst: event.id == events.first?.id)

                    HStack(alignment: .top, spacing: 12) {
                        PlantIcon(symbolName: event.kind.symbolName, size: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.kind.title).font(.headline)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let measurement = event.measurement {
                                Text(measurement).font(.subheadline)
                            }
                            if !event.note.isEmpty {
                                Text(event.note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .transition(PlantMotion.transition(reduceMotion: reduceMotion))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func logWatering() {
        withAnimation(PlantMotion.animation(reduceMotion: reduceMotion)) {
            // A failed save must never produce a success animation or haptic.
            if store.logWatering(for: plant) {
                wateringConfirmation += 1
                showsWateringConfirmation = true
            } else {
                showsWateringConfirmation = false
            }
        }
    }
}
