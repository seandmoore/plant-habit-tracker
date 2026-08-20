import Foundation
import Observation

/// Scanner state. Holding it here keeps the request lifecycle — including which response is
/// still wanted — out of the view.
@MainActor
@Observable
final class ScannerModel {
    var mode: ScanMode = .both
    var imageData: Data?
    var results: [ScanCandidate] = []
    var isScanning = false
    var errorMessage: String?

    /// Identifies the newest request so a slow earlier one cannot overwrite a later result.
    @ObservationIgnored private var activeRequestID = UUID()

    func loadImage(_ data: Data?, using service: any IdentificationService) async {
        guard let data else {
            errorMessage = "That image could not be opened."
            return
        }
        imageData = ImageDataNormalizer.normalized(data)
        await scan(using: service)
    }

    func scan(using service: any IdentificationService) async {
        guard let imageData else { return }

        let requestID = UUID()
        activeRequestID = requestID
        isScanning = true
        results = []
        errorMessage = nil

        do {
            let candidates = try await service.identify(imageData: imageData, mode: mode)
            guard activeRequestID == requestID else { return }
            results = candidates
        } catch {
            guard activeRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }

        guard activeRequestID == requestID else { return }
        isScanning = false
    }

    /// The catalog entry a candidate corresponds to, if the app can offer to add it directly.
    func catalogMatch(for candidate: ScanCandidate, in catalog: [PlantSpecies]) -> PlantSpecies? {
        catalog.first { species in
            if let scientificName = candidate.scientificName,
               species.scientificName.caseInsensitiveCompare(scientificName) == .orderedSame {
                return true
            }
            return species.commonName.caseInsensitiveCompare(candidate.title) == .orderedSame
        }
    }
}
