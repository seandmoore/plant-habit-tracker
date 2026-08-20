import SwiftUI

/// Records a watering with optional detail. Everything it collects is optional except the fact
/// that watering happened, so logging never becomes a chore.
struct WateringLogSheet: View {
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plant: UserPlant

    @State private var amount = ""
    @State private var unit: WaterUnit = .localeDefault
    @State private var timestamp = Date.now
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Watering") {
                    DatePicker("When", selection: $timestamp, in: ...Date.now)
                    HStack {
                        TextField("Amount (optional)", text: $amount)
                            .accessibilityLabel("Amount of water")
                        Picker("Unit", selection: $unit) {
                            ForEach(WaterUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    TextField("Observation or note", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Text("Leave the amount blank to record only that you watered.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Watering")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 440, minHeight: 360)
    }

    private func save() {
        store.logWatering(
            for: plant,
            amount: WaterAmount.parse(amount),
            unit: unit,
            timestamp: timestamp,
            note: note
        )
        dismiss()
    }
}
