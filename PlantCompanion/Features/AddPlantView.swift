import SwiftData
import SwiftUI
import PhotosUI

struct AddPlantView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let preselectedSpeciesID: String?
    @State private var selectedSpeciesID: String
    @State private var nickname = ""
    @State private var environment: PlantEnvironment = .indoor
    @State private var light: LightLevel = .brightIndirect
    @State private var locationName = ""
    @State private var remindersEnabled = false
    @State private var reminderHour = 9
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var resolvedSpecies: PlantSpecies?

    init(preselectedSpeciesID: String? = nil) {
        self.preselectedSpeciesID = preselectedSpeciesID
        _selectedSpeciesID = State(initialValue: preselectedSpeciesID ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    HStack {
                        PlantArtwork(imageData: photoData, size: 76)
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(photoData == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                        }
                    }
                    Picker("Species", selection: $selectedSpeciesID) {
                        Text("Choose a species").tag("")
                        ForEach(catalogForPicker) { species in
                            Text("\(species.commonName) — \(species.scientificName)")
                                .tag(species.id)
                        }
                    }
                    TextField("Nickname", text: $nickname, prompt: Text(selectedSpecies?.commonName ?? "For example, Moss"))
                }

                Section("Growing place") {
                    Picker("Environment", selection: $environment) {
                        ForEach(PlantEnvironment.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    Picker("Light", selection: $light) {
                        ForEach(LightLevel.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    TextField("Room, patio, or bed (optional)", text: $locationName)
                }

                Section("Care reminders") {
                    Toggle("Remind me to check the soil", isOn: $remindersEnabled)
                    if remindersEnabled {
                        Picker("Reminder time", selection: $reminderHour) {
                            ForEach(6..<21, id: \.self) { hour in
                                Text(formattedHour(hour)).tag(hour)
                            }
                        }
                    }
                    Text("Reminders suggest a soil check. They never mean the plant must be watered.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Notes") {
                    TextField("Anything useful about this plant", text: $notes, axis: .vertical)
                        .lineLimit(3...7)
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addPlant() }
                        .disabled(selectedSpecies == nil)
                }
            }
            .onChange(of: selectedSpeciesID) { _, _ in
                guard nickname.isEmpty else { return }
                nickname = selectedSpecies?.commonName ?? ""
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                    photoData = ImageDataNormalizer.jpegData(from: data) ?? data
                }
            }
            .task {
                if appModel.catalog.isEmpty { await appModel.loadCatalog() }
                if let preselectedSpeciesID,
                   !appModel.catalog.contains(where: { $0.id == preselectedSpeciesID }) {
                    resolvedSpecies = try? await appModel.catalogService.species(id: preselectedSpeciesID)
                }
                if nickname.isEmpty { nickname = selectedSpecies?.commonName ?? "" }
            }
        }
        .frame(minWidth: 320, idealWidth: 460, minHeight: 560)
    }

    private var selectedSpecies: PlantSpecies? {
        appModel.catalog.first { $0.id == selectedSpeciesID }
            ?? (resolvedSpecies?.id == selectedSpeciesID ? resolvedSpecies : nil)
    }

    private var catalogForPicker: [PlantSpecies] {
        guard let resolvedSpecies,
              !appModel.catalog.contains(where: { $0.id == resolvedSpecies.id }) else {
            return appModel.catalog
        }
        return [resolvedSpecies] + appModel.catalog
    }

    private func addPlant() {
        guard let species = selectedSpecies else { return }
        let plant = UserPlant(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? species.commonName : nickname,
            species: species,
            environment: environment,
            light: light,
            locationName: locationName,
            reminderEnabled: remindersEnabled,
            reminderHour: reminderHour,
            notes: notes,
            photoData: photoData
        )
        modelContext.insert(plant)
        try? modelContext.save()
        if remindersEnabled {
            Task { try? await appModel.scheduleReminder(for: plant) }
        }
        dismiss()
    }

    private func formattedHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}
