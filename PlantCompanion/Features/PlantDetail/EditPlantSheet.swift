import SwiftUI

struct EditPlantSheet: View {
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plant: UserPlant
    @State private var edits: PlantEdits
    let onDeleted: () -> Void

    @State private var isConfirmingDeletion = false

    init(plant: UserPlant, onDeleted: @escaping () -> Void) {
        self.plant = plant
        self.onDeleted = onDeleted
        _edits = State(initialValue: PlantEdits(plant: plant))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    TextField("Nickname", text: $edits.nickname)
                    TextField("Location", text: $edits.locationName)
                }

                Section("Growing place") {
                    Picker("Environment", selection: $edits.environment) {
                        ForEach(PlantEnvironment.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Light", selection: $edits.light) {
                        ForEach(LightLevel.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Care reminders") {
                    Toggle("Remind me to check soil", isOn: $edits.reminderEnabled)
                    if edits.reminderEnabled {
                        Picker("Reminder time", selection: $edits.reminderHour) {
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
                    TextField("Notes", text: $edits.notes, axis: .vertical)
                        .lineLimit(3...7)
                }

                Section {
                    Button("Delete plant", systemImage: "trash", role: .destructive) {
                        isConfirmingDeletion = true
                    }
                }
            }
            .navigationTitle("Plant Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if store.commitEdits(to: plant, edits: edits) { dismiss() }
                    }
                }
            }
            .confirmationDialog(
                "Delete \(plant.nickname)?",
                isPresented: $isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete plant", role: .destructive) { deletePlant() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes the plant and its care history from this device.")
            }
        }
        .plantSaveError()
        .frame(minWidth: 320, idealWidth: 460, minHeight: 500)
    }

    private func deletePlant() {
        guard store.delete(plant) else { return }
        dismiss()
        onDeleted()
    }
}

/// The hours a reminder may fire. Bounded to waking hours so a care check never arrives at 3am.
enum ReminderHour {
    static let selectable = Array(6..<21)
    static let `default` = 9

    static func title(for hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.autoupdatingCurrent.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}
