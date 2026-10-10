import XCTest
@testable import PlantCompanion

@MainActor
final class AddPlantModelRegressionTests: XCTestCase {
    func testInitialLoadUsesTheFirstSpeciesName() async {
        let model = AddPlantModel()

        await model.load(using: BundledCatalogService())

        XCTAssertEqual(model.selectedSpeciesID, "monstera-deliciosa")
        XCTAssertEqual(model.nickname, "Monstera")
    }

    func testAutomaticNicknameFollowsEachSpeciesChange() async {
        let model = AddPlantModel()
        await model.load(using: BundledCatalogService())

        select("epipremnum-aureum", in: model)
        XCTAssertEqual(model.nickname, "Golden pothos")

        select("sansevieria-trifasciata", in: model)
        XCTAssertEqual(model.nickname, "Snake plant")
    }

    func testCustomNicknameSurvivesSpeciesChangesAndReloads() async {
        let model = AddPlantModel()
        await model.load(using: BundledCatalogService())
        model.nickname = "Moss"

        select("epipremnum-aureum", in: model)
        await model.load(using: BundledCatalogService())

        XCTAssertEqual(model.nickname, "Moss")
    }

    func testCustomNicknameThatMatchesASpeciesNameStillStaysCustom() async {
        let model = AddPlantModel()
        await model.load(using: BundledCatalogService())
        model.nickname = "Golden pothos"

        select("epipremnum-aureum", in: model)
        select("sansevieria-trifasciata", in: model)

        XCTAssertEqual(model.nickname, "Golden pothos")
    }

    func testRetypingTheDefaultNameIsPreservedAsACustomNickname() async {
        let model = AddPlantModel()
        await model.load(using: BundledCatalogService())
        model.nickname = "Monstera"

        select("epipremnum-aureum", in: model)

        XCTAssertEqual(model.nickname, "Monstera")
    }

    func testBlankNicknameFallsBackAndFollowsLaterSpeciesChanges() async {
        let model = AddPlantModel()
        await model.load(using: BundledCatalogService())
        model.nickname = " \n "

        select("epipremnum-aureum", in: model)
        XCTAssertEqual(model.nickname, "Golden pothos")

        select("sansevieria-trifasciata", in: model)
        XCTAssertEqual(model.nickname, "Snake plant")
    }

    func testNicknameEnteredBeforeCatalogLoadsIsPreserved() async {
        let model = AddPlantModel(preselectedSpeciesID: "epipremnum-aureum")
        model.nickname = "Kitchen vine"

        await model.load(using: BundledCatalogService())

        XCTAssertEqual(model.selectedSpeciesID, "epipremnum-aureum")
        XCTAssertEqual(model.nickname, "Kitchen vine")
    }

    func testPreselectedSpeciesOutsideTheSearchPageGetsADefaultThatFollowsChanges() async throws {
        let selected = try XCTUnwrap(StarterCatalog.species.first { $0.id == "epipremnum-aureum" })
        let first = try XCTUnwrap(StarterCatalog.species.first { $0.id == "monstera-deliciosa" })
        let model = AddPlantModel(preselectedSpeciesID: selected.id)

        await model.load(using: PartialCatalogService(page: [first], selected: selected))

        XCTAssertEqual(model.nickname, "Golden pothos")
        XCTAssertEqual(model.pickerOptions.map(\.id), [selected.id, first.id])

        select(first.id, in: model)
        XCTAssertEqual(model.nickname, "Monstera")
    }

    private func select(_ speciesID: String, in model: AddPlantModel) {
        model.selectedSpeciesID = speciesID
        model.speciesDidChange()
    }
}

private struct PartialCatalogService: PlantCatalogService {
    let page: [PlantSpecies]
    let selected: PlantSpecies

    func search(query: String) async throws -> [PlantSpecies] { page }

    func species(id: String) async throws -> PlantSpecies? {
        selected.id == id ? selected : nil
    }
}
