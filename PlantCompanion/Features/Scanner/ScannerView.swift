import PhotosUI
import SwiftUI

#if os(iOS)
import UIKit
#endif

struct ScannerView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var model = ScannerModel()
    @State private var catalog: [PlantSpecies] = []
    @State private var photoItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var speciesToAdd: PlantSpecies?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A closer look.")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Start with a photo. Get to know what’s growing.")
                            .foregroundStyle(.secondary)
                    }
                    captureCard
                    if model.isScanning {
                        scanningCard.transition(PlantMotion.transition(reduceMotion: reduceMotion))
                    }
                    if let errorMessage = model.errorMessage {
                        errorCard(errorMessage).transition(.opacity)
                    }
                    if !model.results.isEmpty {
                        resultsSection.transition(PlantMotion.transition(reduceMotion: reduceMotion))
                    }
                    privacyNote
                }
                .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: model.isScanning)
                .animation(PlantMotion.animation(reduceMotion: reduceMotion), value: model.results.count)
                .plantReadableColumn()
            }
            .plantPage()
            .navigationTitle("Plant Scanner")
            .onChange(of: photoItem) { _, item in
                Task {
                    let data = try? await item?.loadTransferable(type: Data.self)
                    await model.loadImage(data, using: appEnvironment.identification)
                }
            }
            .task {
                catalog = (try? await appEnvironment.catalog.search(query: "")) ?? []
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { data in
                    isShowingCamera = false
                    Task { await model.loadImage(data, using: appEnvironment.identification) }
                }
                .ignoresSafeArea()
            }
            #endif
            .sheet(item: $speciesToAdd) { species in
                AddPlantView(preselectedSpeciesID: species.id)
            }
        }
    }

    private var captureCard: some View {
        PlantSection {
            if dynamicTypeSize.isAccessibilitySize {
                scanModePicker.pickerStyle(.menu)
            } else {
                scanModePicker.pickerStyle(.segmented)
            }

            Group {
                if let imageData = model.imageData {
                    PlantArtwork(imageData: imageData, size: 220)
                } else {
                    framingGuide
                }
            }
            .frame(maxWidth: .infinity)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { captureActions }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 12) { captureActions }
            }
            .controlSize(.large)
        }
    }

    private var scanModePicker: some View {
        @Bindable var model = model

        return Picker("Scan type", selection: $model.mode) {
            ForEach(ScanMode.allCases) { Text($0.title).tag($0) }
        }
        .disabled(model.isScanning)
    }

    @ViewBuilder
    private var captureActions: some View {
        #if os(iOS)
        Button("Camera", systemImage: "camera") { isShowingCamera = true }
            .buttonStyle(.glassProminent)
            .disabled(model.isScanning || !UIImagePickerController.isSourceTypeAvailable(.camera))
        #endif

        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("Photo Library", systemImage: "photo.on.rectangle.angled")
        }
        .buttonStyle(.bordered)
        .disabled(model.isScanning)

        if model.imageData != nil {
            Button("Scan again", systemImage: "arrow.clockwise") {
                Task { await model.scan(using: appEnvironment.identification) }
            }
            .buttonStyle(.bordered)
            .disabled(model.isScanning)
        }
    }

    private var framingGuide: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "viewfinder")
                    .font(.system(size: 88, weight: .ultraLight))
                    .foregroundStyle(PlantTheme.accent.opacity(0.5))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 36, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(PlantTheme.accent)
            }
            .accessibilityHidden(true)
            Text("One plant. A little detail.")
                .font(.title3.weight(.semibold))
            Text("Fill the frame with clear leaves and stems for better suggestions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(PlantTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var scanningCard: some View {
        PlantSection {
            HStack(spacing: 16) {
                CompanionRing(state: .thinking)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Looking a little closer")
                        .font(.headline)
                    ProgressView("Comparing visible features…")
                        .font(.subheadline)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        PlantSection {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(PlantTheme.warning)
        }
    }

    private var resultsSection: some View {
        PlantSection("Suggestions") {
            Text("Compare the candidates before choosing. Confidence is not certainty.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(model.results) { candidate in
                RowDivider(isFirst: candidate.id == model.results.first?.id)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.title).font(.headline)
                            if let scientificName = candidate.scientificName {
                                Text(scientificName).italic().foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(candidate.confidence, format: .percent.precision(.fractionLength(0)))
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(value: candidate.confidence)
                        .tint(PlantTheme.accent)
                    Text(candidate.detail).font(.subheadline)
                    Text(candidate.source).font(.caption).foregroundStyle(.secondary)

                    if let match = model.catalogMatch(for: candidate, in: catalog) {
                        Button("Use this identification", systemImage: "plus.circle") { speciesToAdd = match }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var privacyNote: some View {
        PlantSection("Privacy and limits") {
            Label(
                "Photos are sent only when you start a scan. The configured service should discard uploads after processing.",
                systemImage: "hand.raised.fill"
            )
            Label(
                "Health results are possibilities, not diagnoses. Limited diseases and species can be recognized.",
                systemImage: "cross.case"
            )
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
