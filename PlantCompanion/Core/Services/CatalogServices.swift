import Foundation

/// Serves the curated catalog compiled into the app. Always available, works offline, and needs
/// no configuration, which is what makes it a safe fallback for every other catalog source.
struct BundledCatalogService: PlantCatalogService {
    let catalog: [PlantSpecies]

    init(catalog: [PlantSpecies] = StarterCatalog.species) {
        self.catalog = catalog
    }

    func search(query: String) async throws -> [PlantSpecies] {
        catalog.filter { $0.matches(query: query) }
    }

    func species(id: String) async throws -> PlantSpecies? {
        catalog.first { $0.id == id }
    }
}

/// Reads the same curated catalog from a deployed proxy, so care guidance can be corrected
/// without shipping an app update.
actor ProxyCatalogService: PlantCatalogService {
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
        return try await fetch([PlantSpecies].self, from: url) ?? []
    }

    func species(id: String) async throws -> PlantSpecies? {
        guard let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw PlantServiceError.invalidConfiguration
        }
        return try await fetch(PlantSpecies.self, from: baseURL.appending(path: "v1/plants/\(encoded)"))
    }

    /// Returns nil for a 404 so a missing species reads as absent rather than as a failure.
    private func fetch<Value: Decodable>(_ type: Value.Type, from url: URL) async throws -> Value? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PlantServiceError.invalidResponse }
        if http.statusCode == 404 { return nil }
        guard 200..<300 ~= http.statusCode else {
            throw PlantServiceError.requestFailed("The plant catalog is temporarily unavailable.")
        }

        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            throw PlantServiceError.invalidResponse
        }
    }
}

/// Prefers a remote catalog but never lets one become a single point of failure: an error or an
/// empty result falls through to the bundled copy, so Discover keeps working offline.
actor ResilientCatalogService: PlantCatalogService {
    private let primary: any PlantCatalogService
    private let fallback: any PlantCatalogService

    init(primary: any PlantCatalogService, fallback: any PlantCatalogService = BundledCatalogService()) {
        self.primary = primary
        self.fallback = fallback
    }

    func search(query: String) async throws -> [PlantSpecies] {
        if let remote = try? await primary.search(query: query), !remote.isEmpty {
            return remote
        }
        return try await fallback.search(query: query)
    }

    func species(id: String) async throws -> PlantSpecies? {
        if let remote = try? await primary.species(id: id) {
            return remote
        }
        return try await fallback.species(id: id)
    }
}
