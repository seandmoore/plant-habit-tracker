import SwiftUI

struct SpeciesDetailView: View {
    let species: PlantSpecies
    @State private var isAdding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                careGuide
                if let toxicityNote = species.toxicityNote {
                    safetyNote(toxicityNote)
                }
                Button("Add to My Plants", systemImage: "plus") { isAdding = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .plantPage()
        .navigationTitle(species.commonName)
        .sheet(isPresented: $isAdding) {
            AddPlantView(preselectedSpeciesID: species.id)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: species.symbolName)
                .font(.system(size: 46))
                .foregroundStyle(PlantTheme.accent)
                .accessibilityHidden(true)
            Text(species.commonName).font(.largeTitle.bold())
            Text(species.scientificName).italic().foregroundStyle(.secondary)
            Text(species.summary).font(.title3).padding(.top, 4)
        }
    }

    private var careGuide: some View {
        PlantSection("Starting care guide") {
            FactRow(symbolName: "sun.max.fill", title: "Light", value: species.light)
            FactRow(
                symbolName: "drop.fill",
                title: "Soil check",
                value: "Start around every \(species.baselineWateringDays) days, then adapt from observation"
            )
            FactRow(symbolName: "square.3.layers.3d", title: "Soil", value: species.soil)
            FactRow(symbolName: "humidity.fill", title: "Humidity", value: species.humidity)
        }
    }

    /// Toxicity notes are starter hints, so they always point at an authoritative source.
    private func safetyNote(_ note: String) -> some View {
        PlantSection("Safety note") {
            Label(note, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(PlantTheme.warning)
            Text("Verify safety details with a veterinarian, poison-control service, or another authoritative source for your situation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
