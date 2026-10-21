// File: ShiftWeekWidget/ShiftWeekWidget.swift
import SwiftUI
import WidgetKit

@main
struct ShiftWeekWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShiftWeekWidget()
    }
}

struct ShiftWeekWidget: Widget {
    let kind = "ShiftWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ShiftWeekWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ShiftWeek")
        .description("Your hours, estimated pay and next shift this week.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShiftWeekWidgetView: View {
    let entry: ShiftWeekEntry
    var family: WidgetFamily? = nil
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            switch entry.state {
            case .ready(let minutes, let pay, let next):
                if (family ?? widgetFamily) == .systemMedium {
                    HStack(alignment: .top, spacing: 16) {
                        totals(minutes: minutes, pay: pay)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        mediumNext(next)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        totals(minutes: minutes, pay: pay)
                        Divider()
                            .padding(.vertical, 4)
                        smallNext(next)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            case .noJobs:
                message("Add a job in ShiftWeek", systemImage: "briefcase")
            case .needsApp:
                message("Open ShiftWeek", systemImage: "iphone")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func totals(minutes: Int, pay: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("This week")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Format.duration(minutes: minutes))
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
            Text("\(Format.money(pay)) est.")
                .font(.subheadline)
                .minimumScaleFactor(0.7)
        }
        .lineLimit(1)
    }

    @ViewBuilder private func smallNext(_ next: NextShift?) -> some View {
        if let next {
            Text("Next")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(next.start <= entry.date ? "Now" : weekdayAndTime(next.start))
                .font(.subheadline.bold())
            Text(next.jobName)
                .font(.caption)
                .lineLimit(1)
        } else {
            Text("No upcoming shifts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func mediumNext(_ next: NextShift?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Next shift")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let next {
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.jobName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(next.start <= entry.date ? "Now" : Format.shortDay(next.start))
                        .font(.subheadline)
                    Text("\(Format.time(next.start)) – \(Format.time(next.end))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 10)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(JobPalette.color(next.colorIndex))
                        .frame(width: 4)
                }
            } else {
                Text("No upcoming shifts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func message(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.tint)
            Text(text)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func weekdayAndTime(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).locale(Format.australia)) + " " + Format.time(date)
    }
}

#Preview(as: .systemSmall) {
    ShiftWeekWidget()
} timeline: {
    ShiftWeekEntry.sample
    ShiftWeekEntry(date: .now, state: .noJobs)
    ShiftWeekEntry(date: .now, state: .needsApp)
}

#Preview(as: .systemMedium) {
    ShiftWeekWidget()
} timeline: {
    ShiftWeekEntry.sample
}
