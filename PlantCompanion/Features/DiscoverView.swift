import SwiftUI

struct DiscoverView: View {
    @Environment(AppModel.self) private var appModel
    @State private var query = ""
    @State private var isSearching = false
    @State private var results: [PlantSpecies] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .plantPage()
                .navigationTitle("Discover")
                .searchable(text: $query, prompt: "Common or scientific name")
                .onSubmit(of: .search) { search() }
                .onChange(of: query) { _, newValue in
                    if newValue.isEmpty { search() }
                }
                .task {
                    if results.isEmpty { results = appModel.catalog }
                }
                .refreshable { await searchCatalog() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = errorMessage {
            ContentUnavailableView("Catalog unavailable", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if results.isEmpty && isSearching {
            ProgressView("Searching plants…")
        } else {
            List(results) { species in
                NavigationLink {
                    SpeciesDetailView(species: species)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Rectangle()
                                .fill(PlantTheme.mint.gradient)
                            Image(systemName: species.symbolName)
                                .foregroundStyle(PlantTheme.moss)
                        }
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(species.commonName).font(.headline)
                            Text(species.scientificName)
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.secondary)
                            Text(species.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func search() {
        isSearching = true
        Task {
            await searchCatalog()
            isSearching = false
        }
    }

    private func searchCatalog() async {
        do {
            results = try await appModel.catalogService.search(query: query)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SpeciesDetailView: View {
    let species: PlantSpecies
    @State private var isAdding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: species.symbolName)
                        .font(.system(size: 46))
                        .foregroundStyle(PlantTheme.accent)
                    Text(species.commonName).font(.largeTitle.bold())
                    Text(species.scientificName).italic().foregroundStyle(.secondary)
                    Text(species.summary).font(.title3).padding(.top, 4)
                }

                PlantSection("Starting care guide") {
                    FactRow(symbol: "sun.max.fill", title: "Light", value: species.light)
                    FactRow(symbol: "drop.fill", title: "Soil check", value: "Start around every \(species.baselineWateringDays) days, then adapt from observation")
                    FactRow(symbol: "square.3.layers.3d", title: "Soil", value: species.soil)
                    FactRow(symbol: "humidity.fill", title: "Humidity", value: species.humidity)
                }

                if let toxicity = species.toxicityNote {
                    PlantSection("Safety note") {
                        Label(toxicity, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(PlantTheme.warning)
                        Text("Verify safety details with a veterinarian, poison-control service, or another authoritative source for your situation.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
}

private struct FactRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(PlantTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(value).foregroundStyle(.secondary)
            }
        }
    }
}
