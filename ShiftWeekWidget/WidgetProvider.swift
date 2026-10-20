// File: ShiftWeekWidget/WidgetProvider.swift
import WidgetKit

struct ShiftWeekEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftWeekEntry {
        ShiftWeekEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftWeekEntry) -> Void) {
        completion(ShiftWeekEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftWeekEntry>) -> Void) {
        completion(Timeline(entries: [ShiftWeekEntry(date: .now)], policy: .never))
    }
}
