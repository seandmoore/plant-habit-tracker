import Foundation
import Observation

/// Form state for adding a plant, kept out of the view so species loading and the
/// nickname-follows-species rule can be tested and reasoned about on their own.
@MainActor
@Observable
final class AddPlantModel {
    var catalog: [PlantSpecies] = []
    var selectedSpeciesID: String
    var nickname = ""
    var environment: PlantEnvironment = .indoor
    var light: LightLevel = .brightIndirect
    var locationName = ""
    var reminderEnabled = false
    var reminderHour = ReminderHour.default
    var notes = ""
    var photoData: Data?
    var loadError: String?

    /// A species chosen elsewhere — from Discover or a scan — that may not be in the loaded page.
    private var preselected: PlantSpecies?

    init(preselectedSpeciesID: String? = nil) {
        selectedSpeciesID = preselectedSpeciesID ?? ""
    }

    var selectedSpecies: PlantSpecies? {
        if let match = catalog.first(where: { $0.id == selectedSpeciesID }) { return match }
        return preselected?.id == selectedSpeciesID ? preselected : nil
    }

    /// The preselected species is prepended when the catalog does not already contain it, so the
    /// picker can always show what the person actually chose.
    var pickerOptions: [PlantSpecies] {
        guard let preselected, !catalog.contains(where: { $0.id == preselected.id }) else { return catalog }
        return [preselected] + catalog
    }

    var canSave: Bool { selectedSpecies != nil }

    func load(using service: any PlantCatalogService) async {
        do {
            catalog = try await service.search(query: "")
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }

        if !selectedSpeciesID.isEmpty, !catalog.contains(where: { $0.id == selectedSpeciesID }) {
            preselected = try? await service.species(id: selectedSpeciesID)
        }
        if selectedSpeciesID.isEmpty {
            selectedSpeciesID = catalog.first?.id ?? ""
        }
        applyDefaultNickname()
    }

    /// Keeps the nickname in step with the species until someone types their own.
    func speciesDidChange(from previousID: String) {
        let previousName = (pickerOptions.first { $0.id == previousID })?.commonName
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty || trimmed == previousName else { return }
        applyDefaultNickname()
    }

    func applyDefaultNickname() {
        guard let commonName = selectedSpecies?.commonName else { return }
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { nickname = commonName }
    }

    func setPhoto(from data: Data?) {
        guard let data else { return }
        photoData = ImageDataNormalizer.normalized(data)
    }
}
