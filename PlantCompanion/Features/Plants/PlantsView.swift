import SwiftData
import SwiftUI

struct PlantsView: View {
    @Environment(PlantStore.self) private var store
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]
    @State private var isAddingPlant = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .plantPage()
            .navigationTitle("My Plants")
            .searchable(text: $searchText, prompt: "Search your plants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add plant", systemImage: "plus") { isAddingPlant = true }
                }
            }
            .sheet(isPresented: $isAddingPlant) {
                AddPlantView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No plants yet", systemImage: "leaf")
        } description: {
            Text("Build your collection one plant at a time.")
        } actions: {
            Button("Add a plant") { isAddingPlant = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var grid: some View {
        let queue = store.careQueue(plants.filter { $0.matches(query: searchText) })

        return ScrollView {
            if queue.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                    ForEach(queue) { entry in
                        NavigationLink {
                            PlantDetailView(plant: entry.plant)
                        } label: {
                            PlantCollectionCard(plant: entry.plant, recommendation: entry.recommendation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .plantReadableColumn()
            }
        }
    }
}
