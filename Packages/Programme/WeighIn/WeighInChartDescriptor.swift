import Foundation
import Accessibility

/// The audio graph of the rolling-average chart (weigh-in spec,
/// "Accessibility of the weigh-in": "The chart MUST provide the system
/// audio graph so a person using VoiceOver can explore the line.").
///
/// The chart view is one accessibility element with the label "Rolling
/// average" (`.accessibilityElement(children: .ignore)`). Swift Charts makes
/// a chart descriptor for its own view, and nobody can show that the one
/// element keeps it. So the view gives the element this descriptor itself
/// (`.accessibilityChartDescriptor`), and the audio graph does not depend
/// on what Swift Charts does inside (mm-t45.16).
///
/// The descriptor has one series, the line: one data point for each
/// weigh-in, at the weigh-in's day, with its rolling average. The values
/// are in the person's unit, as the chart plots them: kilograms, or the
/// nearest whole pound with "st lb". VoiceOver reads each value as the
/// screen shows it ("66.8 kg", "10 st 7 lb") and each date in en_GB ("5
/// October 2026").
public enum WeighInChartDescriptor {
    /// The descriptor for `points`. `title` is the chart's label ("Rolling
    /// average"); it also names the series and the value axis. `dateAxisTitle`
    /// names the date axis ("Date").
    public static func make(points: [RollingAveragePoint], unit: WeightUnit, calendar: Calendar,
                            title: String, dateAxisTitle: String) -> AXChartDescriptor {
        let data: [(x: Double, y: Double)] = points.compactMap { point in
            guard let day = DayKeyMath.midnight(point.dayKey, calendar: calendar) else { return nil }
            return (day.timeIntervalSince1970, plottedValue(point.averageKg, unit: unit))
        }
        let xAxis = AXNumericDataAxisDescriptor(
            title: dateAxisTitle,
            range: range(of: data.map(\.x), smallest: 86_400),
            gridlinePositions: [],
            valueDescriptionProvider: { dateText(Date(timeIntervalSince1970: $0), calendar: calendar) })
        let yAxis = AXNumericDataAxisDescriptor(
            title: title,
            range: range(of: data.map(\.y), smallest: 1),
            gridlinePositions: [],
            valueDescriptionProvider: { valueText($0, unit: unit) })
        let series = AXDataSeriesDescriptor(
            name: title, isContinuous: true,
            dataPoints: data.map { AXDataPoint(x: $0.x, y: $0.y) })
        return AXChartDescriptor(title: title, summary: nil, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series])
    }

    /// The value that the chart plots for `kg`: kilograms, or the nearest
    /// whole pound total with "st lb". The axis then reads in the person's
    /// unit.
    public static func plottedValue(_ kg: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return kg
        case .stLb: return (kg / BMI.kgPerPound).rounded()
        }
    }

    /// The text of a plotted value, as the screen shows a weight: "66.8 kg"
    /// or "10 st 7 lb".
    public static func valueText(_ value: Double, unit: WeightUnit) -> String {
        switch unit {
        case .kg:
            return WeighInWeight.display(kg: value, unit: .kg)
        case .stLb:
            let pounds = Int(value.rounded())
            return "\(pounds / 14) st \(pounds % 14) lb"
        }
    }

    /// The date of a data point, from the en_GB formatter on `calendar`
    /// (product-rules spec, "Dates and times in strings"): "5 October 2026".
    public static func dateText(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: date)
    }

    /// The range of `values`, at least `smallest` wide, so that one point
    /// (or equal values) still gives the axis a range.
    private static func range(of values: [Double], smallest: Double) -> ClosedRange<Double> {
        guard let low = values.min(), let high = values.max() else { return 0...smallest }
        return high - low >= smallest ? low...high : (low - smallest / 2)...(high + smallest / 2)
    }
}
