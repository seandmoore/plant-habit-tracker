import SwiftUI

/// A compact care row that stacks vertically at accessibility text sizes.
struct PlantRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let plant: UserPlant
    let recommendation: CareRecommendation
    var artworkSize: CGFloat = 62

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))

        layout {
            PlantArtwork(imageData: plant.photoData, size: artworkSize)
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.nickname)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(plant.commonName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                StatusPill(recommendation: recommendation)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// The collection grid's card.
struct PlantCollectionCard: View {
    let plant: UserPlant
    let recommendation: CareRecommendation

    var body: some View {
        PlantSection {
            HStack(alignment: .top) {
                PlantArtwork(imageData: plant.photoData, size: 76)
                Spacer(minLength: 12)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(8)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.nickname)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(plant.commonName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            StatusPill(recommendation: recommendation)
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
            PlantIcon(symbolName: symbolName, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
