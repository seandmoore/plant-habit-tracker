import XCTest
@testable import PlantCompanion

final class ServiceTests: XCTestCase {
    func testCatalogSearchMatchesCommonAndScientificNames() async throws {
        let service = StarterCatalogService()

        let common = try await service.search(query: "monstera")
        let scientific = try await service.search(query: "ocimum")

        XCTAssertEqual(common.first?.id, "monstera-deliciosa")
        XCTAssertEqual(scientific.first?.id, "ocimum-basilicum")
    }

    func testEmptyCatalogQueryReturnsStarterCollection() async throws {
        let results = try await StarterCatalogService().search(query: "")
        XCTAssertGreaterThanOrEqual(results.count, 10)
    }

    func testMockScannerReturnsSpeciesAndHealthSuggestions() async throws {
        let results = try await MockIdentificationService().identify(imageData: Data([1, 2, 3]), mode: .both)

        XCTAssertTrue(results.contains { $0.scientificName != nil })
        XCTAssertTrue(results.contains { $0.title.contains("stress") })
        XCTAssertTrue(results.allSatisfy { (0.0...1.0).contains($0.confidence) })
    }

    func testProxyScannerRejectsOversizedImageBeforeNetworkRequest() async throws {
        let service = ProxyIdentificationService(baseURL: try XCTUnwrap(URL(string: "https://proxy.example")))

        do {
            _ = try await service.identify(imageData: Data(count: 10 * 1024 * 1024 + 1), mode: .species)
            XCTFail("Expected an oversized image error")
        } catch PlantServiceError.imageTooLarge {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScriptedCompanionDoesNotPresentHealthSuggestionAsDiagnosis() async throws {
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Why are the leaves yellow?", plantName: "Moss", groundedFacts: [])
        )

        XCTAssertTrue(response.localizedCaseInsensitiveContains("not a diagnosis"))
    }
}
