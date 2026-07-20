import SwiftData
import SwiftUI

struct PlantDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismissDetail
    @Bindable var plant: UserPlant

    @State private var isShowingDetailedWatering = false
    @State private var isShowingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                recommendationCard
                actions
                history
                if !plant.notes.isEmpty {
                    PlantSection("Notes") {
                        Text(plant.notes)
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .plantPage()
        .navigationTitle(plant.nickname)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit", systemImage: "slider.horizontal.3") { isShowingEdit = true }
            }
        }
        .sheet(isPresented: $isShowingDetailedWatering) {
            WateringLogSheet(plant: plant)
        }
        .sheet(isPresented: $isShowingEdit) {
            EditPlantSheet(plant: plant) { dismissDetail() }
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
                Label(plant.environment.title, systemImage: plant.environment == .indoor ? "house.fill" : "sun.max.fill")
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

    private var recommendationCard: some View {
        PlantSection("Next care check") {
            StatusPill(recommendation: recommendation)
            Text(recommendation.reason)
                .foregroundStyle(.secondary)
            Label("About every \(recommendation.intervalDays) days under the recorded conditions", systemImage: "calendar.badge.clock")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Water now", systemImage: "drop.fill") { quickWater() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Button("Add details", systemImage: "square.and.pencil") { isShowingDetailedWatering = true }
                .buttonStyle(.bordered)
                .controlSize(.large)
            Button("Ask companion", systemImage: "sparkles") { appModel.presentCompanion(for: plant) }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var history: some View {
        PlantSection("Care history") {
            if plant.sortedCareEvents.isEmpty {
                Text("No care has been logged yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(plant.sortedCareEvents) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: event.kind.symbol)
                            .foregroundStyle(PlantTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.kind.title)
                                .font(.headline)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let amount = event.amount, let unit = event.waterUnit {
                                Text("\(amount.formatted()) \(unit.rawValue)")
                                    .font(.subheadline)
                            }
                            if !event.note.isEmpty { Text(event.note).font(.subheadline) }
                        }
                        Spacer()
                    }
                    if event.id != plant.sortedCareEvents.last?.id { Divider() }
                }
            }
        }
    }

    private var recommendation: CareRecommendation {
        appModel.recommendationEngine.wateringRecommendation(for: plant, asOf: .now)
    }

    private func quickWater() {
        let event = CareEvent(kind: .watered)
        modelContext.insert(event)
        plant.careEvents.append(event)
        try? modelContext.save()
        Task { try? await appModel.scheduleReminder(for: plant) }
    }
}

private struct WateringLogSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let plant: UserPlant

    @State private var amount = ""
    @State private var unit: WaterUnit = Locale.current.measurementSystem == .us ? .fluidOunces : .milliliters
    @State private var timestamp = Date.now
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Watering") {
                    DatePicker("When", selection: $timestamp, in: ...Date.now)
                    HStack {
                        TextField("Amount (optional)", text: $amount)
                        Picker("Unit", selection: $unit) {
                            ForEach(WaterUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    TextField("Observation or note", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("Log Watering")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
        .frame(minWidth: 320, idealWidth: 440, minHeight: 360)
    }

    private func save() {
        let parsedAmount = Double(amount.replacingOccurrences(of: ",", with: "."))
        let event = CareEvent(kind: .watered, timestamp: timestamp, amount: parsedAmount, waterUnit: parsedAmount == nil ? nil : unit, note: note)
        modelContext.insert(event)
        plant.careEvents.append(event)
        try? modelContext.save()
        Task { try? await appModel.scheduleReminder(for: plant) }
        dismiss()
    }
}

private struct EditPlantSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: UserPlant
    let onDeleted: () -> Void
    @State private var isConfirmingDeletion = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nickname", text: $plant.nickname)
                Picker("Environment", selection: $plant.environmentRawValue) {
                    ForEach(PlantEnvironment.allCases) { Text($0.title).tag($0.rawValue) }
                }
                Picker("Light", selection: $plant.lightRawValue) {
                    ForEach(LightLevel.allCases) { Text($0.title).tag($0.rawValue) }
                }
                TextField("Location", text: $plant.locationName)
                Toggle("Remind me to check soil", isOn: $plant.reminderEnabled)
                TextField("Notes", text: $plant.notes, axis: .vertical)
                    .lineLimit(3...7)
                Section {
                    Button("Delete plant", systemImage: "trash", role: .destructive) {
                        isConfirmingDeletion = true
                    }
                }
            }
            .navigationTitle("Plant Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task { try? await appModel.scheduleReminder(for: plant) }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete \(plant.nickname)?", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
                Button("Delete plant", role: .destructive) { deletePlant() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes the plant and its care history from this device.")
            }
        }
        .frame(minWidth: 320, idealWidth: 460, minHeight: 500)
    }

    private func deletePlant() {
        let id = plant.id
        modelContext.delete(plant)
        try? modelContext.save()
        Task { await appModel.notifications.cancelWateringReminder(for: id) }
        dismiss()
        onDeleted()
    }
}
