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
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ShiftWeekWidget", provider: Provider()) { _ in
            Text("ShiftWeek")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ShiftWeek")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
