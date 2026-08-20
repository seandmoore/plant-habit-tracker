import PhotosUI
import SwiftUI

#if os(iOS)
import UIKit
#endif

struct ScannerView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    @State private var model = ScannerModel()
    @State private var catalog: [PlantSpecies] = []
    @State private var photoItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var speciesToAdd: PlantSpecies?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    captureCard
                    if model.isScanning { scanningCard }
                    if let errorMessage = model.errorMessage { errorCard(errorMessage) }
                    if !model.results.isEmpty { resultsSection }
                    privacyNote
                }
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
        @Bindable var model = model

        return PlantSection {
            Picker("Scan type", selection: $model.mode) {
                ForEach(ScanMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(model.isScanning)

            Group {
                if let imageData = model.imageData {
                    PlantArtwork(imageData: imageData, size: 220)
                } else {
                    framingGuide
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                #if os(iOS)
                Button("Camera", systemImage: "camera.fill") { isShowingCamera = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isScanning || !UIImagePickerController.isSourceTypeAvailable(.camera))
                #endif

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
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
        }
    }

    private var framingGuide: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PlantTheme.mint.opacity(0.45))
            VStack(spacing: 12) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 54, weight: .light))
                Text("Fill the frame with one plant")
                    .font(.headline)
                Text("Clear leaf and stem details improve suggestions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 240)
        .accessibilityElement(children: .combine)
    }

    private var scanningCard: some View {
        PlantSection {
            ProgressView("Comparing visible features…")
                .frame(maxWidth: .infinity)
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
                        Button("Use this identification") { speciesToAdd = match }
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
