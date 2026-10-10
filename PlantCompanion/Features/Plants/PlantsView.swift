import SwiftData
import SwiftUI

struct PlantsView: View {
    @Environment(PlantStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]
    @State private var isAddingPlant = false
    @State private var searchText = ""
    @State private var filter = CollectionFilter.all

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    emptyState
                } else {
                    collection
                }
            }
            .plantPage()
            .navigationTitle("My Plants")
            .searchable(text: $searchText, prompt: "Name or species")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add plant", systemImage: "plus") { isAddingPlant = true }
                        .accessibilityHint("Choose a species and add it to your collection.")
                }
            }
            .sheet(isPresented: $isAddingPlant) {
                AddPlantView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your collection starts here", systemImage: "leaf.circle")
        } description: {
            Text("A windowsill favorite or a whole indoor jungle. Give your first plant a home here.")
        } actions: {
            Button("Add a plant", systemImage: "plus") { isAddingPlant = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var collection: some View {
        let queue = store.careQueue(plants)
        let matching = queue.filter { $0.plant.matches(query: searchText) }
        let visible = matching.filter { filter == .all || $0.recommendation.needsAttention }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                collectionSummary(checkCount: queue.filter { $0.recommendation.needsAttention }.count)
                filterControl

                if visible.isEmpty {
                    if matching.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        noChecksState
                    }
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        Text(filter == .all ? "Your plants" : "Ready for a check")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(visible.count, format: .number)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .accessibilityLabel("\(visible.count) plants")
                    }

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(visible) { entry in
                            NavigationLink {
                                PlantDetailView(plant: entry.plant)
                            } label: {
                                PlantCollectionCard(plant: entry.plant, recommendation: entry.recommendation)
                            }
                            .buttonStyle(.plain)
                            .transition(PlantMotion.transition(reduceMotion: reduceMotion))
                        }
                    }
                }
            }
            .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: filter)
            .plantReadableColumn()
        }
    }

    private func collectionSummary(checkCount: Int) -> some View {
        PlantSection {
            HStack(alignment: .top, spacing: 16) {
                PlantIcon(symbolName: "leaf.fill", size: 52)
                VStack(alignment: .leading, spacing: 6) {
                    Text(plants.count == 1 ? "1 plant in your care" : "\(plants.count) plants in your care")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                    Text(checkCount == 0
                         ? "No scheduled care checks right now."
                         : checkCount == 1 ? "One is ready for a closer look." : "\(checkCount) are ready for a closer look.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var filterControl: some View {
        if dynamicTypeSize.isAccessibilitySize {
            filterPicker
                .pickerStyle(.menu)
        } else {
            filterPicker
                .pickerStyle(.segmented)
        }
    }

    private var filterPicker: some View {
        Picker("Show plants", selection: $filter) {
            ForEach(CollectionFilter.allCases) { option in
                Text(option.title).tag(option)
            }
        }
    }

    private var noChecksState: some View {
        ContentUnavailableView {
            Label(searchText.isEmpty ? "No checks due" : "No matching checks", systemImage: "checkmark.circle")
        } description: {
            Text(searchText.isEmpty
                 ? "Your next care checks will appear here. You can still visit any plant to see how it’s doing."
                 : "Show all plants to see the rest of your search results.")
        } actions: {
            Button("Show all plants") { filter = .all }
                .buttonStyle(.bordered)
        }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 280), spacing: 16)]
    }
}

private enum CollectionFilter: String, CaseIterable, Identifiable {
    case all
    case needsAttention

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All plants"
        case .needsAttention: "Needs a check"
        }
    }
}
