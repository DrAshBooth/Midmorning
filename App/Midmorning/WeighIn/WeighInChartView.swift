import SwiftUI
import Charts
import Programme

/// The rolling-average chart (weigh-in spec, "The chart"). A line through
/// the rolling averages, one point per weigh-in, in the secondary text
/// colour so the line (primary text colour) stays the one thing that reads
/// as a trend. Swift Charts builds its own accessible representation and
/// audio graph from the marks; VoiceOver walk and the audio graph are a
/// device check (mm-t22.14).
struct WeighInChartView: View {
    let points: [RollingAveragePoint]
    let unit: WeightUnit
    let calendar: Calendar

    var body: some View {
        Chart {
            ForEach(points, id: \.dayKey) { point in
                LineMark(
                    x: .value(WeighInContent.chartDateLabel.string, date(for: point.dayKey)),
                    y: .value(WeighInContent.rollingAverageAccessibilityLabel.string, displayValue(point.averageKg))
                )
                .foregroundStyle(.primary)
            }
            ForEach(points, id: \.dayKey) { point in
                PointMark(
                    x: .value(WeighInContent.chartDateLabel.string, date(for: point.dayKey)),
                    y: .value(WeighInContent.weightLabel.string, displayValue(point.weightKg))
                )
                .symbolSize(60)
                .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month))
        }
        .frame(height: 180)
        .accessibilityLabel(WeighInContent.rollingAverageAccessibilityLabel.string)
        .accessibilityElement(children: .ignore)
    }

    /// The value the chart plots: kilograms directly, or the nearest whole
    /// pound total when the unit is stone and pounds — the chart's axis
    /// then reads in the person's unit either way.
    private func displayValue(_ kg: Double) -> Double {
        switch unit {
        case .kg: return kg
        case .stLb: return (kg / 0.453592).rounded()
        }
    }

    private func date(for dayKey: String) -> Date {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? Date()
    }
}
