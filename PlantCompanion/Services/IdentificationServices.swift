import Foundation

actor MockIdentificationService: IdentificationService {
    func identify(imageData: Data, mode: ScanMode) async throws -> [ScanCandidate] {
        try await Task.sleep(for: .milliseconds(650))
        guard !imageData.isEmpty else { throw PlantServiceError.invalidResponse }

        switch mode {
        case .species:
            return speciesCandidates
        case .health:
            return healthCandidates
        case .both:
            return speciesCandidates + healthCandidates
        }
    }

    private var speciesCandidates: [ScanCandidate] {
        [
            ScanCandidate(id: "mock-monstera", title: "Monstera", scientificName: "Monstera deliciosa", confidence: 0.86, detail: "Compare leaf shape and growth habit before confirming.", source: "Demo result"),
            ScanCandidate(id: "mock-rhaphidophora", title: "Mini monstera", scientificName: "Rhaphidophora tetrasperma", confidence: 0.34, detail: "A visually similar climbing aroid.", source: "Demo result")
        ]
    }

    private var healthCandidates: [ScanCandidate] {
        [
            ScanCandidate(id: "mock-stress", title: "Possible watering stress", scientificName: nil, confidence: 0.61, detail: "Check soil moisture, roots, light, and recent care. A photo cannot confirm the cause.", source: "Demo result")
        ]
    }
}

actor ProxyIdentificationService: IdentificationService {
    private static let maximumImageBytes = 10 * 1024 * 1024
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func identify(imageData: Data, mode: ScanMode) async throws -> [ScanCandidate] {
        guard !imageData.isEmpty else { throw PlantServiceError.invalidResponse }
        guard imageData.count <= Self.maximumImageBytes else { throw PlantServiceError.imageTooLarge }

        let endpoint = baseURL.appending(path: "v1/identify")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "mode", value: mode.rawValue)]
        guard let url = components?.url else { throw PlantServiceError.invalidConfiguration }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(String(imageData.count), forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.upload(for: request, from: imageData)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PlantServiceError.requestFailed("The scanner is temporarily unavailable.")
        }
        do {
            return try JSONDecoder().decode([ScanCandidate].self, from: data)
        } catch {
            throw PlantServiceError.invalidResponse
        }
    }
}
