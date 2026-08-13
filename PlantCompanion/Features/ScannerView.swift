import PhotosUI
import SwiftUI

#if os(iOS)
import UIKit
#endif

struct ScannerView: View {
    @Environment(AppModel.self) private var appModel
    @State private var mode: ScanMode = .both
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var results: [ScanCandidate] = []
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var isShowingCamera = false
    @State private var speciesToAdd: PlantSpecies?
    @State private var activePhotoLoadID: UUID?
    @State private var activeScanID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    captureCard
                    if isScanning {
                        PlantSection {
                            ProgressView("Comparing visible features…")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    if let errorMessage {
                        PlantSection {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(PlantTheme.warning)
                        }
                    }
                    if !results.isEmpty { resultsSection }
                    privacyNote
                }
                .padding()
                .padding(.bottom, 80)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .plantPage()
            .navigationTitle("Plant Scanner")
            .onChange(of: photoItem) { _, item in load(item) }
            #if os(iOS)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { data in
                    imageData = data
                    isShowingCamera = false
                    scan()
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
            Picker("Scan type", selection: $mode) {
                ForEach(ScanMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(isScanning)

            Group {
                if let imageData {
                    PlantArtwork(imageData: imageData, size: 220)
                } else {
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
            }
            .frame(maxWidth: .infinity)

            HStack {
                #if os(iOS)
                Button("Camera", systemImage: "camera.fill") { isShowingCamera = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning || !UIImagePickerController.isSourceTypeAvailable(.camera))
                #endif
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
                .disabled(isScanning)
                if imageData != nil {
                    Button("Scan again", systemImage: "arrow.clockwise") { scan() }
                        .buttonStyle(.bordered)
                        .disabled(isScanning)
                }
            }
        }
    }

    private var resultsSection: some View {
        PlantSection("Suggestions") {
            Text("Compare the candidates before choosing. Confidence is not certainty.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(results) { candidate in
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
                    if let match = catalogMatch(for: candidate) {
                        Button("Use this identification") { speciesToAdd = match }
                            .buttonStyle(.bordered)
                    }
                }
                if candidate.id != results.last?.id { Divider() }
            }
        }
    }

    private var privacyNote: some View {
        PlantSection("Privacy and limits") {
            Label("Photos are sent only when you start a scan. The configured service should discard uploads after processing.", systemImage: "hand.raised.fill")
            Label("Health results are possibilities, not diagnoses. Limited diseases and species can be recognized.", systemImage: "cross.case")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func load(_ item: PhotosPickerItem?) {
        guard let item else { return }
        let loadID = UUID()
        activePhotoLoadID = loadID
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    guard activePhotoLoadID == loadID else { return }
                    activePhotoLoadID = nil
                    errorMessage = "That image could not be opened."
                    return
                }
                guard activePhotoLoadID == loadID else { return }
                activePhotoLoadID = nil
                imageData = ImageDataNormalizer.jpegData(from: data) ?? data
                scan()
            } catch {
                guard activePhotoLoadID == loadID else { return }
                activePhotoLoadID = nil
                errorMessage = "That image could not be opened."
            }
        }
    }

    private func scan() {
        guard let imageData else { return }
        let scanID = UUID()
        let requestedMode = mode
        activeScanID = scanID
        isScanning = true
        results = []
        errorMessage = nil
        Task {
            do {
                let newResults = try await appModel.identificationService.identify(
                    imageData: imageData,
                    mode: requestedMode
                )
                guard activeScanID == scanID else { return }
                results = newResults
            } catch {
                guard activeScanID == scanID else { return }
                errorMessage = error.localizedDescription
            }
            activeScanID = nil
            isScanning = false
        }
    }

    private func catalogMatch(for candidate: ScanCandidate) -> PlantSpecies? {
        appModel.catalog.first {
            $0.scientificName.caseInsensitiveCompare(candidate.scientificName ?? "") == .orderedSame
                || $0.commonName.caseInsensitiveCompare(candidate.title) == .orderedSame
        }
    }
}

#if os(iOS)
private struct CameraPicker: UIViewControllerRepresentable {
    let completion: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.82) {
                parent.completion(data)
            } else {
                parent.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
#endif
