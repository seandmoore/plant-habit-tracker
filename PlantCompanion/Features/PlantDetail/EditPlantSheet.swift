import SwiftUI

struct EditPlantSheet: View {
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: UserPlant
    let onDeleted: () -> Void

    @State private var isConfirmingDeletion = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    TextField("Nickname", text: $plant.nickname)
                    TextField("Location", text: $plant.locationName)
                }

                Section("Growing place") {
                    Picker("Environment", selection: $plant.environment) {
                        ForEach(PlantEnvironment.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Light", selection: $plant.light) {
                        ForEach(LightLevel.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Care reminders") {
                    Toggle("Remind me to check soil", isOn: $plant.reminderEnabled)
                    if plant.reminderEnabled {
                        Picker("Reminder time", selection: $plant.reminderHour) {
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
                    TextField("Notes", text: $plant.notes, axis: .vertical)
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.commitEdits(to: plant)
                        dismiss()
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
        .frame(minWidth: 320, idealWidth: 460, minHeight: 500)
    }

    private func deletePlant() {
        store.delete(plant)
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
