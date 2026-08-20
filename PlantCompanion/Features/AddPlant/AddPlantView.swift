import PhotosUI
import SwiftData
import SwiftUI

struct AddPlantView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var model: AddPlantModel
    @State private var photoItem: PhotosPickerItem?

    init(preselectedSpeciesID: String? = nil) {
        _model = State(initialValue: AddPlantModel(preselectedSpeciesID: preselectedSpeciesID))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Plant") {
                    HStack {
                        PlantArtwork(
                            imageData: model.photoData,
                            size: 76,
                            symbolName: model.selectedSpecies?.symbolName ?? "leaf.fill"
                        )
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(model.photoData == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                        }
                    }

                    Picker("Species", selection: $model.selectedSpeciesID) {
                        Text("Choose a species").tag("")
                        ForEach(model.pickerOptions) { species in
                            Text("\(species.commonName) — \(species.scientificName)").tag(species.id)
                        }
                    }

                    TextField(
                        "Nickname",
                        text: $model.nickname,
                        prompt: Text(model.selectedSpecies?.commonName ?? "For example, Moss")
                    )
                }

                Section("Growing place") {
                    Picker("Environment", selection: $model.environment) {
                        ForEach(PlantEnvironment.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Light", selection: $model.light) {
                        ForEach(LightLevel.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Room, patio, or bed (optional)", text: $model.locationName)
                }

                Section("Care reminders") {
                    Toggle("Remind me to check the soil", isOn: $model.reminderEnabled)
                    if model.reminderEnabled {
                        Picker("Reminder time", selection: $model.reminderHour) {
                            ForEach(ReminderHour.selectable, id: \.self) { hour in
                                Text(ReminderHour.title(for: hour)).tag(hour)
                            }
                        }
                    }
                    Text("Reminders suggest a soil check. They never mean the plant must be watered.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Notes") {
                    TextField("Anything useful about this plant", text: $model.notes, axis: .vertical)
                        .lineLimit(3...7)
                }

                if let loadError = model.loadError {
                    Section {
                        Label(loadError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(PlantTheme.warning)
                    }
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addPlant() }
                        .disabled(!model.canSave)
                }
            }
            .onChange(of: model.selectedSpeciesID) { previous, _ in
                model.speciesDidChange(from: previous)
            }
            .onChange(of: photoItem) { _, item in
                Task { model.setPhoto(from: try? await item?.loadTransferable(type: Data.self)) }
            }
            .task { await model.load(using: appEnvironment.catalog) }
        }
        .frame(minWidth: 320, idealWidth: 460, minHeight: 560)
    }

    private func addPlant() {
        guard let species = model.selectedSpecies else { return }
        store.addPlant(
            nickname: model.nickname,
            species: species,
            environment: model.environment,
            light: model.light,
            locationName: model.locationName,
            reminderEnabled: model.reminderEnabled,
            reminderHour: model.reminderHour,
            notes: model.notes,
            photoData: model.photoData
        )
        dismiss()
    }
}
