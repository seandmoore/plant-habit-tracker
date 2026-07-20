import Foundation

actor StarterCatalogService: PlantCatalogService {
    private let plants: [PlantSpecies] = [
        PlantSpecies(id: "monstera-deliciosa", commonName: "Monstera", scientificName: "Monstera deliciosa", summary: "A bold tropical climber with naturally split leaves.", baselineWateringDays: 9, light: "Bright, indirect light", soil: "Airy, well-draining mix", humidity: "Average to humid", environments: [.indoor, .outdoorContainer], toxicityNote: "Can irritate people and pets if chewed.", symbolName: "leaf.fill"),
        PlantSpecies(id: "epipremnum-aureum", commonName: "Golden pothos", scientificName: "Epipremnum aureum", summary: "An adaptable trailing vine that tolerates a range of indoor conditions.", baselineWateringDays: 10, light: "Low to bright, indirect light", soil: "Well-draining potting mix", humidity: "Average", environments: [.indoor, .outdoorContainer], toxicityNote: "Can irritate people and pets if chewed.", symbolName: "leaf.fill"),
        PlantSpecies(id: "sansevieria-trifasciata", commonName: "Snake plant", scientificName: "Dracaena trifasciata", summary: "A resilient succulent-like houseplant with upright leaves.", baselineWateringDays: 18, light: "Low to bright light", soil: "Fast-draining succulent mix", humidity: "Average to dry", environments: [.indoor, .outdoorContainer], toxicityNote: "May be harmful to pets if eaten.", symbolName: "camera.macro"),
        PlantSpecies(id: "ficus-lyrata", commonName: "Fiddle-leaf fig", scientificName: "Ficus lyrata", summary: "A statement plant that appreciates consistency and bright filtered light.", baselineWateringDays: 9, light: "Bright, indirect light", soil: "Rich, well-draining mix", humidity: "Average to humid", environments: [.indoor, .outdoorContainer], toxicityNote: "Sap can irritate skin; harmful if eaten.", symbolName: "leaf.fill"),
        PlantSpecies(id: "chlorophytum-comosum", commonName: "Spider plant", scientificName: "Chlorophytum comosum", summary: "An easy arching plant that produces small plantlets.", baselineWateringDays: 7, light: "Medium to bright, indirect light", soil: "General potting mix", humidity: "Average", environments: [.indoor, .outdoorContainer], toxicityNote: nil, symbolName: "camera.macro"),
        PlantSpecies(id: "lavandula-angustifolia", commonName: "English lavender", scientificName: "Lavandula angustifolia", summary: "A fragrant, sun-loving perennial for containers and garden beds.", baselineWateringDays: 8, light: "Full sun", soil: "Lean, sharply drained soil", humidity: "Dry with good airflow", environments: [.outdoorContainer, .outdoorGround], toxicityNote: "Concentrated oils may be harmful if ingested.", symbolName: "camera.macro"),
        PlantSpecies(id: "ocimum-basilicum", commonName: "Basil", scientificName: "Ocimum basilicum", summary: "A tender culinary herb that grows quickly in warmth and sun.", baselineWateringDays: 3, light: "Full to partial sun", soil: "Moist, fertile, well-draining soil", humidity: "Average", environments: [.indoor, .outdoorContainer, .outdoorGround], toxicityNote: nil, symbolName: "leaf.fill"),
        PlantSpecies(id: "solanum-lycopersicum", commonName: "Tomato", scientificName: "Solanum lycopersicum", summary: "A productive warm-season crop that needs sun and consistent moisture.", baselineWateringDays: 3, light: "Full sun", soil: "Fertile, moisture-retentive soil", humidity: "Average with airflow", environments: [.outdoorContainer, .outdoorGround], toxicityNote: "Leaves and stems should not be eaten.", symbolName: "camera.macro"),
        PlantSpecies(id: "rosa", commonName: "Garden rose", scientificName: "Rosa spp.", summary: "A flowering shrub with many forms, colors, and growth habits.", baselineWateringDays: 6, light: "Full sun", soil: "Rich, well-draining soil", humidity: "Average with airflow", environments: [.outdoorContainer, .outdoorGround], toxicityNote: "Thorns can cause injury.", symbolName: "camera.macro"),
        PlantSpecies(id: "acer-palmatum", commonName: "Japanese maple", scientificName: "Acer palmatum", summary: "A graceful small tree valued for form and seasonal leaf color.", baselineWateringDays: 7, light: "Morning sun or filtered light", soil: "Moist, well-draining soil", humidity: "Average", environments: [.outdoorContainer, .outdoorGround], toxicityNote: nil, symbolName: "leaf.fill")
    ]

    func search(query: String) async throws -> [PlantSpecies] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return plants }
        return plants.filter {
            $0.commonName.localizedCaseInsensitiveContains(trimmed)
                || $0.scientificName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func species(id: String) async throws -> PlantSpecies? {
        plants.first { $0.id == id }
    }
}

actor ProxyPlantCatalogService: PlantCatalogService {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func search(query: String) async throws -> [PlantSpecies] {
        let endpoint = baseURL.appending(path: "v1/plants")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        }
        guard let url = components?.url else { throw PlantServiceError.invalidConfiguration }
        return try await fetch(url)
    }

    func species(id: String) async throws -> PlantSpecies? {
        let url = baseURL.appending(path: "v1/plants/\(id)")
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PlantServiceError.invalidResponse }
        if http.statusCode == 404 { return nil }
        guard 200..<300 ~= http.statusCode else {
            throw PlantServiceError.requestFailed("The plant catalog is temporarily unavailable.")
        }
        return try JSONDecoder().decode(PlantSpecies.self, from: data)
    }

    private func fetch(_ url: URL) async throws -> [PlantSpecies] {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PlantServiceError.requestFailed("The plant catalog is temporarily unavailable.")
        }
        do {
            return try JSONDecoder().decode([PlantSpecies].self, from: data)
        } catch {
            throw PlantServiceError.invalidResponse
        }
    }
}

actor ResilientCatalogService: PlantCatalogService {
    private let primary: any PlantCatalogService
    private let fallback: any PlantCatalogService

    init(primary: any PlantCatalogService, fallback: any PlantCatalogService) {
        self.primary = primary
        self.fallback = fallback
    }

    func search(query: String) async throws -> [PlantSpecies] {
        do {
            let remote = try await primary.search(query: query)
            if !remote.isEmpty { return remote }
        } catch {
            return try await fallback.search(query: query)
        }
        return try await fallback.search(query: query)
    }

    func species(id: String) async throws -> PlantSpecies? {
        do {
            if let remote = try await primary.species(id: id) { return remote }
        } catch {
            return try await fallback.species(id: id)
        }
        return try await fallback.species(id: id)
    }
}
