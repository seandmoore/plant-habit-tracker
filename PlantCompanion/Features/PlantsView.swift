import SwiftData
import SwiftUI

struct PlantsView: View {
    @Query(sort: \UserPlant.nickname) private var plants: [UserPlant]
    @State private var isAddingPlant = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView {
                        Label("No plants yet", systemImage: "leaf")
                    } description: {
                        Text("Build your collection one plant at a time.")
                    } actions: {
                        Button("Add a plant") { isAddingPlant = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                            ForEach(filteredPlants) { plant in
                                NavigationLink {
                                    PlantDetailView(plant: plant)
                                } label: {
                                    PlantCollectionCard(plant: plant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
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

    private var filteredPlants: [UserPlant] {
        guard !searchText.isEmpty else { return plants }
        return plants.filter {
            $0.nickname.localizedCaseInsensitiveContains(searchText)
                || $0.commonName.localizedCaseInsensitiveContains(searchText)
                || $0.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private struct PlantCollectionCard: View {
    @Environment(AppModel.self) private var appModel
    let plant: UserPlant

    var body: some View {
        PlantSection {
            HStack(spacing: 14) {
                PlantArtwork(imageData: plant.photoData)
                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.nickname)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(plant.commonName)
                        .foregroundStyle(.secondary)
                    StatusPill(recommendation: recommendation)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var recommendation: CareRecommendation {
        appModel.recommendationEngine.wateringRecommendation(for: plant, asOf: .now)
    }
}
