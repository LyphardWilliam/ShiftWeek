// File: ShiftWeek/Features/Week/WeekViewModel.swift
import Foundation
import ShiftCore

@Observable final class WeekViewModel {
    struct Day: Identifiable {
        let date: Date
        let items: [ShiftItem]
        var id: Date { date }
    }

    private(set) var weekStart: Date
    private(set) var days: [Day] = []
    private(set) var summary: WeekSummary?
    private(set) var hasJobs = false
    var errorMessage: String?
    private let deps: AppDependencies

    init(deps: AppDependencies, today: Date = .now) {
        self.deps = deps
        weekStart = FortnightCalculator.weekStart(for: today, calendar: deps.calendar)
    }

    var isCurrentWeek: Bool {
        weekStart == FortnightCalculator.weekStart(for: .now, calendar: deps.calendar)
    }

    func load() {
        let calendar = deps.calendar
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        do {
            let jobs = try deps.jobs.allJobs()
            hasJobs = !jobs.isEmpty
            let items = try deps.shifts.shifts(from: weekStart, to: weekEnd).compactMap { shift -> ShiftItem? in
                guard let job = jobs.first(where: { $0.id == shift.jobID }) else { return nil }
                return ShiftItem(shift: shift, job: job, calendar: calendar)
            }
            days = (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
                return Day(date: date, items: items.filter { calendar.isDate($0.shift.start, inSameDayAs: date) })
            }
            summary = try deps.weekSummary.execute(weekStart: weekStart)
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    func showPreviousWeek() {
        moveWeek(byDays: -7)
    }

    func showNextWeek() {
        moveWeek(byDays: 7)
    }

    func showThisWeek() {
        weekStart = FortnightCalculator.weekStart(for: .now, calendar: deps.calendar)
        load()
    }

    func delete(_ item: ShiftItem) {
        do {
            try deps.deleteShift.execute(id: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        load()
    }

    private func moveWeek(byDays offset: Int) {
        weekStart = deps.calendar.date(byAdding: .day, value: offset, to: weekStart)!
        load()
    }
}
