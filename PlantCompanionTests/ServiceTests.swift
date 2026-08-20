import XCTest
@testable import PlantCompanion

final class CatalogServiceTests: XCTestCase {
    func testSearchMatchesCommonAndScientificNames() async throws {
        let service = BundledCatalogService()

        let byCommon = try await service.search(query: "monstera")
        let byScientific = try await service.search(query: "ocimum")

        XCTAssertEqual(byCommon.first?.id, "monstera-deliciosa")
        XCTAssertEqual(byScientific.first?.id, "ocimum-basilicum")
    }

    func testSearchIgnoresCaseAndSurroundingWhitespace() async throws {
        let results = try await BundledCatalogService().search(query: "  MONSTERA  ")

        XCTAssertEqual(results.first?.id, "monstera-deliciosa")
    }

    func testEmptyQueryReturnsTheWholeCatalog() async throws {
        let results = try await BundledCatalogService().search(query: "")

        XCTAssertEqual(results.count, StarterCatalog.species.count)
    }

    func testAQueryThatMatchesNothingReturnsNothing() async throws {
        let results = try await BundledCatalogService().search(query: "zzzznope")

        XCTAssertTrue(results.isEmpty)
    }

    func testLookupByIdentifier() async throws {
        let service = BundledCatalogService()

        let found = try await service.species(id: "ficus-lyrata")
        let missing = try await service.species(id: "no-such-plant")

        XCTAssertEqual(found?.scientificName, "Ficus lyrata")
        XCTAssertNil(missing)
    }

    func testResilientCatalogPrefersTheRemoteResult() async throws {
        let remote = BundledCatalogService(catalog: [Self.remoteOnlySpecies])
        let service = ResilientCatalogService(primary: remote, fallback: BundledCatalogService())

        let results = try await service.search(query: "remote")

        XCTAssertEqual(results.map(\.id), ["remote-only"])
    }

    func testResilientCatalogFallsBackWhenTheRemoteFails() async throws {
        let service = ResilientCatalogService(primary: FailingCatalogService(), fallback: BundledCatalogService())

        let results = try await service.search(query: "monstera")

        XCTAssertEqual(results.first?.id, "monstera-deliciosa")
    }

    func testResilientCatalogFallsBackWhenTheRemoteIsEmpty() async throws {
        let service = ResilientCatalogService(primary: BundledCatalogService(catalog: []), fallback: BundledCatalogService())

        let results = try await service.search(query: "monstera")

        XCTAssertEqual(results.first?.id, "monstera-deliciosa")
    }

    func testResilientLookupFallsBackWhenTheRemoteDoesNotHaveTheSpecies() async throws {
        let service = ResilientCatalogService(primary: BundledCatalogService(catalog: []), fallback: BundledCatalogService())

        let species = try await service.species(id: "monstera-deliciosa")

        XCTAssertEqual(species?.commonName, "Monstera")
    }

    private static let remoteOnlySpecies = PlantSpecies(
        id: "remote-only",
        commonName: "Remote plant",
        scientificName: "Planta remota",
        summary: "",
        baselineWateringDays: 7,
        light: "",
        soil: "",
        humidity: "",
        environments: [.indoor],
        toxicityNote: nil,
        symbolName: "leaf.fill"
    )
}

private struct FailingCatalogService: PlantCatalogService {
    func search(query: String) async throws -> [PlantSpecies] {
        throw PlantServiceError.requestFailed("offline")
    }

    func species(id: String) async throws -> PlantSpecies? {
        throw PlantServiceError.requestFailed("offline")
    }
}

final class IdentificationServiceTests: XCTestCase {
    func testMockScannerReturnsSpeciesAndHealthSuggestions() async throws {
        let results = try await MockIdentificationService().identify(imageData: Data([1, 2, 3]), mode: .both)

        XCTAssertTrue(results.contains { $0.scientificName != nil })
        XCTAssertTrue(results.contains { $0.title.contains("stress") })
    }

    func testHealthSuggestionsCarryNoBinomialNameAndAreNotDiagnoses() async throws {
        let results = try await MockIdentificationService().identify(imageData: Data([1, 2, 3]), mode: .health)

        XCTAssertTrue(results.allSatisfy { $0.scientificName == nil })
        XCTAssertTrue(results.allSatisfy { $0.detail.contains("cannot confirm") })
    }

    func testEveryConfidenceStaysInsideTheContractRange() async throws {
        let results = try await MockIdentificationService().identify(imageData: Data([1, 2, 3]), mode: .both)

        XCTAssertTrue(results.allSatisfy { (0.0...1.0).contains($0.confidence) })
    }

    func testAnEmptyImageIsRejectedBeforeAnythingElse() async {
        do {
            _ = try await MockIdentificationService().identify(imageData: Data(), mode: .species)
            XCTFail("Expected an invalid response error")
        } catch PlantServiceError.invalidResponse {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProxyScannerRejectsAnOversizedImageBeforeAnyNetworkRequest() async throws {
        let service = ProxyIdentificationService(baseURL: try XCTUnwrap(URL(string: "https://proxy.example")))

        do {
            _ = try await service.identify(
                imageData: Data(count: ProxyIdentificationService.maximumImageBytes + 1),
                mode: .species
            )
            XCTFail("Expected an oversized image error")
        } catch PlantServiceError.imageTooLarge {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class CompanionServiceTests: XCTestCase {
    func testScriptedCompanionDoesNotPresentAHealthSuggestionAsADiagnosis() async throws {
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Why are the leaves yellow?", plantName: "Moss", groundedFacts: [])
        )

        XCTAssertTrue(response.localizedCaseInsensitiveContains("not a diagnosis"))
    }

    func testScriptedCompanionTreatsACareDateAsAReminderRatherThanACommand() async throws {
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Should I water it?", plantName: "Moss", groundedFacts: [])
        )

        XCTAssertTrue(response.localizedCaseInsensitiveContains("not a command"))
    }

    func testScriptedCompanionRepeatsSuppliedFactsRatherThanInventingAny() async throws {
        let fact = "Moss is recorded as Monstera (Monstera deliciosa)."
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Tell me about it", plantName: "Moss", groundedFacts: [fact])
        )

        XCTAssertTrue(response.contains(fact))
    }

    func testScriptedCompanionOffersWhatItCanDoWhenItHasNoFacts() async throws {
        let response = try await ScriptedCompanionService().respond(
            to: CompanionPrompt(question: "Hello", plantName: nil, groundedFacts: [])
        )

        XCTAssertTrue(response.contains("I can help you add a plant"))
    }
}

final class ProxyConfigurationTests: XCTestCase {
    func testAcceptsAnAbsoluteHTTPSOrigin() {
        XCTAssertNotNil(ProxyConfiguration.secureURL(from: "https://proxy.example"))
        XCTAssertNotNil(ProxyConfiguration.secureURL(from: "  https://proxy.example/base  "))
        XCTAssertNotNil(ProxyConfiguration.secureURL(from: "HTTPS://proxy.example"))
    }

    /// A plaintext or malformed origin would send plant photos somewhere unverified, so the app
    /// falls back to local behaviour instead of trusting it.
    func testRejectsAnythingThatIsNotAbsoluteHTTPS() {
        XCTAssertNil(ProxyConfiguration.secureURL(from: ""))
        XCTAssertNil(ProxyConfiguration.secureURL(from: "   "))
        XCTAssertNil(ProxyConfiguration.secureURL(from: "http://proxy.example"))
        XCTAssertNil(ProxyConfiguration.secureURL(from: "ftp://proxy.example"))
        XCTAssertNil(ProxyConfiguration.secureURL(from: "proxy.example"))
        XCTAssertNil(ProxyConfiguration.secureURL(from: "https://"))
    }
}

final class WaterAmountTests: XCTestCase {
    func testAcceptsBothDecimalSeparators() {
        XCTAssertEqual(WaterAmount.parse("250"), 250)
        XCTAssertEqual(WaterAmount.parse("12.5"), 12.5)
        XCTAssertEqual(WaterAmount.parse("12,5"), 12.5)
        XCTAssertEqual(WaterAmount.parse("  250  "), 250)
    }

    func testTreatsAnythingUnparseableAsNotRecorded() {
        XCTAssertNil(WaterAmount.parse(""))
        XCTAssertNil(WaterAmount.parse("a lot"))
        XCTAssertNil(WaterAmount.parse("0"))
        XCTAssertNil(WaterAmount.parse("-5"))
    }
}

final class LocalNotificationSchedulerTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testAFutureDueDateFiresAtTheChosenHourOnThatDay() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12)))
        let dueDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25)))

        let fireDate = await scheduler.fireDate(for: request(dueDate: dueDate, hour: 9), now: now)

        XCTAssertEqual(calendar.dateComponents([.year, .month, .day, .hour], from: fireDate),
                       DateComponents(year: 2026, month: 3, day: 25, hour: 9))
    }

    /// An overdue plant would otherwise hold a reminder that can never fire.
    func testADueDateAlreadyPastIsMovedToTheNextDay() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12)))
        let dueDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))

        let fireDate = await scheduler.fireDate(for: request(dueDate: dueDate, hour: 9), now: now)

        XCTAssertEqual(calendar.dateComponents([.year, .month, .day, .hour], from: fireDate),
                       DateComponents(year: 2026, month: 3, day: 21, hour: 9))
    }

    func testAnHourLaterTodayStillFiresToday() async throws {
        let scheduler = LocalNotificationScheduler(calendar: calendar)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 7)))
        let dueDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 20)))

        let fireDate = await scheduler.fireDate(for: request(dueDate: dueDate, hour: 9), now: now)

        XCTAssertEqual(calendar.dateComponents([.year, .month, .day, .hour], from: fireDate),
                       DateComponents(year: 2026, month: 3, day: 20, hour: 9))
    }

    func testEachPlantGetsOneStableReminderIdentifier() {
        let id = UUID()

        XCTAssertEqual(LocalNotificationScheduler.identifier(for: id), "watering-\(id.uuidString)")
        XCTAssertNotEqual(LocalNotificationScheduler.identifier(for: id), LocalNotificationScheduler.identifier(for: UUID()))
    }

    private func request(dueDate: Date, hour: Int) -> WateringReminderRequest {
        WateringReminderRequest(plantID: UUID(), plantName: "Moss", dueDate: dueDate, hour: hour)
    }
}

final class ReminderHourTests: XCTestCase {
    /// Bounded to waking hours so a care check never arrives in the middle of the night.
    func testSelectableHoursStayWithinWakingHours() {
        XCTAssertEqual(ReminderHour.selectable.first, 6)
        XCTAssertEqual(ReminderHour.selectable.last, 20)
        XCTAssertTrue(ReminderHour.selectable.contains(ReminderHour.default))
    }
}

final class ScannerModelTests: XCTestCase {
    @MainActor
    func testCatalogMatchPrefersAScientificNameAndIgnoresCase() {
        let model = ScannerModel()
        let candidate = ScanCandidate(
            id: "c",
            title: "Something else",
            scientificName: "monstera deliciosa",
            confidence: 0.8,
            detail: "",
            source: "test"
        )

        XCTAssertEqual(model.catalogMatch(for: candidate, in: StarterCatalog.species)?.id, "monstera-deliciosa")
    }

    @MainActor
    func testCatalogMatchFallsBackToTheCommonName() {
        let model = ScannerModel()
        let candidate = ScanCandidate(
            id: "c",
            title: "Snake plant",
            scientificName: nil,
            confidence: 0.5,
            detail: "",
            source: "test"
        )

        XCTAssertEqual(model.catalogMatch(for: candidate, in: StarterCatalog.species)?.id, "sansevieria-trifasciata")
    }

    @MainActor
    func testAHealthObservationMatchesNoCatalogEntry() {
        let model = ScannerModel()
        let candidate = ScanCandidate(
            id: "c",
            title: "Possible watering stress",
            scientificName: nil,
            confidence: 0.61,
            detail: "",
            source: "test"
        )

        XCTAssertNil(model.catalogMatch(for: candidate, in: StarterCatalog.species))
    }
}
