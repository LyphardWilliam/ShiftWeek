// File: ShiftWeekWidget/WidgetProvider.swift
import Foundation
import ShiftCore
import SwiftData
import WidgetKit

struct NextShift {
    let jobName: String
    let colorIndex: Int
    let start: Date
    let end: Date
}

struct ShiftWeekEntry: TimelineEntry {
    enum State {
        case ready(minutes: Int, pay: Decimal, next: NextShift?)
        case noJobs
        case needsApp
    }

    let date: Date
    let state: State

    static var sample: ShiftWeekEntry {
        let start = Calendar.shiftWeek.date(bySettingHour: 18, minute: 0, second: 0, of: .now)!
        let next = NextShift(jobName: "FreshMart", colorIndex: 5, start: start,
                             end: start.addingTimeInterval(6.5 * 3600))
        return ShiftWeekEntry(date: .now,
                              state: .ready(minutes: 1506, pay: Decimal(string: "733.10")!, next: next))
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftWeekEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftWeekEntry) -> Void) {
        completion(context.isPreview ? .sample : Self.load(now: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftWeekEntry>) -> Void) {
        let now = Date.now
        let refresh = now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: [Self.load(now: now)], policy: .after(refresh)))
    }

    /// Reads this week's shifts straight from the shared SwiftData store.
    static func load(now: Date) -> ShiftWeekEntry {
        guard SharedStore.isAppGroupAvailable, let container = try? SharedStore.makeContainer() else {
            return ShiftWeekEntry(date: now, state: .needsApp)
        }
        let context = ModelContext(container)
        return load(now: now, context: context)
    }

    /// Keeps the read-only store query reusable with an isolated context for verification.
    static func load(now: Date, context: ModelContext, calendar: Calendar = .shiftWeek) -> ShiftWeekEntry {
        do {
            if try context.fetchCount(FetchDescriptor<JobRecord>()) == 0 {
                return ShiftWeekEntry(date: now, state: .noJobs)
            }

            let weekStart = FortnightCalculator.weekStart(for: now, calendar: calendar)
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let weekShifts = try context.fetch(FetchDescriptor<ShiftRecord>(
                predicate: #Predicate { $0.start >= weekStart && $0.start < weekEnd }))
            let worked = weekShifts.compactMap { record -> WorkedShift? in
                guard let job = record.job else { return nil }
                let rates = PayRates(hourlyRate: job.hourlyRate, saturdayMultiplier: job.saturdayMultiplier,
                                     sundayMultiplier: job.sundayMultiplier,
                                     publicHolidayMultiplier: job.holidayMultiplier)
                return WorkedShift(start: record.start, end: record.end, clockIn: record.clockIn,
                                   clockOut: record.clockOut, unpaidBreakMinutes: record.unpaidBreakMinutes,
                                   rates: rates)
            }
            let total = PayCalculator.total(for: worked, calendar: calendar)

            var nextDescriptor = FetchDescriptor<ShiftRecord>(
                predicate: #Predicate { $0.end > now && $0.clockOut == nil },
                sortBy: [SortDescriptor(\.start)])
            nextDescriptor.fetchLimit = 1
            var next: NextShift?
            if let record = try context.fetch(nextDescriptor).first, let job = record.job {
                next = NextShift(jobName: job.name, colorIndex: job.colorIndex, start: record.start, end: record.end)
            }
            return ShiftWeekEntry(date: now, state: .ready(minutes: total.paidMinutes, pay: total.pay, next: next))
        } catch {
            return ShiftWeekEntry(date: now, state: .needsApp)
        }
    }
}
