import SwiftUI

/// One plant in a list, with its current status. Shared by Today and the collection grid so both
/// present a plant identically.
struct PlantRow: View {
    let plant: UserPlant
    let recommendation: CareRecommendation
    var artworkSize: CGFloat = 62

    var body: some View {
        HStack(spacing: 14) {
            PlantArtwork(imageData: plant.photoData, size: artworkSize)
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.nickname)
                    .font(.headline)
                    .foregroundStyle(.primary)
                StatusPill(recommendation: recommendation)
            }
            Spacer(minLength: 0)
        }
    }
}

/// The collection grid's card.
struct PlantCollectionCard: View {
    let plant: UserPlant
    let recommendation: CareRecommendation

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
}

/// A labelled care fact, announced as one phrase.
struct FactRow: View {
    let symbolName: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .foregroundStyle(PlantTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(value).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
