import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    @State private var query = ""
    @State private var results: [PlantSpecies] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .plantPage()
                .navigationTitle("Discover")
                .searchable(text: $query, prompt: "Common or scientific name")
                // Re-runs as the query changes, so results follow typing without a submit step.
                .task(id: query) { await search() }
                .refreshable { await search() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            ContentUnavailableView(
                "Catalog unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text(errorMessage)
            )
        } else if results.isEmpty && isSearching {
            ProgressView("Searching plants…")
        } else if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(results) { species in
                NavigationLink {
                    SpeciesDetailView(species: species)
                } label: {
                    row(for: species)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func row(for species: PlantSpecies) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle().fill(PlantTheme.mint.gradient)
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

    private func search() async {
        isSearching = true
        defer { isSearching = false }

        do {
            results = try await appEnvironment.catalog.search(query: query)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
