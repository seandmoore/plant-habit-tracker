import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var query = ""
    @State private var results: [PlantSpecies] = []
    @State private var isSearching = true
    @State private var errorMessage: String?
    @State private var activeSearchID: UUID?

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
            ContentUnavailableView {
                Label("Catalog unavailable", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try again", systemImage: "arrow.clockwise") {
                    Task { await search() }
                }
                .buttonStyle(.bordered)
                .disabled(isSearching)
            }
        } else if results.isEmpty && isSearching {
            ProgressView("Searching plants…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            catalog
        }
    }

    private var catalog: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                introduction
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(results) { species in
                    NavigationLink {
                        SpeciesDetailView(species: species)
                    } label: {
                        row(for: species)
                    }
                    .listRowBackground(Color.clear)
                }
            } header: {
                HStack {
                    Text(query.isEmpty ? "Explore the catalog" : "Search results")
                    Spacer()
                    if isSearching {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel("Updating results")
                    } else {
                        Text("\(results.count)")
                            .monospacedDigit()
                            .accessibilityLabel("\(results.count) plants")
                    }
                }
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: PlantTheme.floatingClearance)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: PlantTheme.readableWidth)
        .frame(maxWidth: .infinity)
        .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: results.map(\.id))
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Grow your plant knowledge", systemImage: "books.vertical.fill")
                .font(.title2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
            Text("Find a familiar leaf or a new favorite. Get to know the light, soil, and care each plant needs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
    }

    private func row(for species: PlantSpecies) -> some View {
        HStack(alignment: .top, spacing: 14) {
            PlantArtwork(imageData: nil, size: 60, symbolName: species.symbolName)

            VStack(alignment: .leading, spacing: 5) {
                Text(species.commonName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(species.scientificName)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
                Text(species.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func search() async {
        let requestID = UUID()
        activeSearchID = requestID
        isSearching = true
        defer {
            if activeSearchID == requestID { isSearching = false }
        }

        do {
            let matches = try await appEnvironment.catalog.search(query: query)
            // Older or cancelled searches must not replace what the user just typed.
            guard !Task.isCancelled, activeSearchID == requestID else { return }
            results = matches
            errorMessage = nil
        } catch {
            guard !Task.isCancelled, activeSearchID == requestID else { return }
            errorMessage = error.localizedDescription
        }
    }
}
