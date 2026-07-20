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

    func testScriptedCompanionDoesNotPresentHealthSuggestionAsDiagnosis() async throws {
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Why are the leaves yellow?", plantName: "Moss", groundedFacts: [])
        )

        XCTAssertTrue(response.localizedCaseInsensitiveContains("not a diagnosis"))
    }
}
