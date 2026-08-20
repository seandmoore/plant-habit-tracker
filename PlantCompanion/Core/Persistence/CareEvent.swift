import Foundation
import SwiftData

@Model
final class CareEvent {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var timestamp: Date
    var amount: Double?
    var waterUnitRawValue: String?
    var note: String

    init(
        id: UUID = UUID(),
        kind: CareEventKind,
        timestamp: Date = .now,
        amount: Double? = nil,
        waterUnit: WaterUnit? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.timestamp = timestamp
        self.amount = amount
        // A unit without an amount is noise, so it is only recorded alongside one.
        self.waterUnitRawValue = amount == nil ? nil : waterUnit?.rawValue
        self.note = note
    }

    var kind: CareEventKind {
        get { CareEventKind(rawValue: kindRawValue) ?? .healthNote }
        set { kindRawValue = newValue.rawValue }
    }

    var waterUnit: WaterUnit? {
        get { waterUnitRawValue.flatMap(WaterUnit.init(rawValue:)) }
        set { waterUnitRawValue = newValue?.rawValue }
    }

    var measurement: String? {
        guard let amount, let waterUnit else { return nil }
        return "\(amount.formatted()) \(waterUnit.rawValue)"
    }
}
