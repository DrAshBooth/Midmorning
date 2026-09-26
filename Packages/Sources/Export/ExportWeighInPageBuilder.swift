import Foundation
import Record
import Programme

/// Builds the weigh-in page's rows from the store's kept weigh-ins (export
/// spec, "The optional weigh-in page"; weigh-in spec, "The weigh-in page in
/// an export": "The page MUST show a value as `weigh-in` displays it").
/// Reuses `WeighInWeight.display`, `weigh-in`'s own rounding rule, so the
/// export never carries a second copy of the stone-and-pounds math.
public enum ExportWeighInPageBuilder {
    public static func lines(from weighIns: [RecordStore.WeighInRow], fromDayKey: String, toDayKey: String, unit: WeightUnit) -> [ExportWeighInLine] {
        weighIns
            .filter { $0.dateKey >= fromDayKey && $0.dateKey <= toDayKey }
            .sorted { $0.dateKey < $1.dateKey }
            .map { row in
                ExportWeighInLine(dateText: ExportDayKey.dayHeading(row.dateKey), valueText: WeighInWeight.display(kg: row.weightKg, unit: unit))
            }
    }
}
