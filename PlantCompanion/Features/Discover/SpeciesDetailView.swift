import SwiftUI

struct SpeciesDetailView: View {
    let species: PlantSpecies
    @State private var isAdding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Button {
                    isAdding = true
                } label: {
                    Label("Add to My Plants", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                careGuide
                if let toxicityNote = species.toxicityNote {
                    safetyNote(toxicityNote)
                }
            }
            .plantReadableColumn()
        }
        .plantPage()
        .navigationTitle(species.commonName)
        .sheet(isPresented: $isAdding) {
            AddPlantView(preselectedSpeciesID: species.id)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) {
                    PlantArtwork(imageData: nil, size: 100, symbolName: species.symbolName)
                    identity
                        .fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 18) {
                    PlantArtwork(imageData: nil, size: 88, symbolName: species.symbolName)
                    identity
                }
            }

            Text(species.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plant guide")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PlantTheme.accent)
            Text(species.commonName)
                .font(.largeTitle.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(species.scientificName)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }

    private var careGuide: some View {
        PlantSection("Starting care guide") {
            FactRow(symbolName: "sun.max.fill", title: "Light", value: species.light)
            Divider()
            FactRow(
                symbolName: "drop.fill",
                title: "Soil check",
                value: "Start around every \(species.baselineWateringDays) days, then adapt from observation"
            )
            Divider()
            FactRow(symbolName: "square.3.layers.3d", title: "Soil", value: species.soil)
            Divider()
            FactRow(symbolName: "humidity.fill", title: "Humidity", value: species.humidity)
        }
    }

    /// Toxicity notes are starter hints, so they always point at an authoritative source.
    private func safetyNote(_ note: String) -> some View {
        PlantSection("Safety note") {
            Label(note, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(PlantTheme.warning)
                .fixedSize(horizontal: false, vertical: true)
            Text("Verify safety details with a veterinarian, poison-control service, or another authoritative source for your situation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
