// File: ShiftWeek/Features/Today/TodayViewModel.swift
import Foundation
import ShiftCore

@Observable final class TodayViewModel {
    private(set) var items: [ShiftItem] = []
    private(set) var hasJobs = false
    private(set) var clockChanges = 0
    var errorMessage: String?
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }

    func load(now: Date = .now) {
        let calendar = deps.calendar
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        do {
            let jobs = try deps.jobs.allJobs()
            hasJobs = !jobs.isEmpty
            var shifts = try deps.shifts.shifts(from: today, to: tomorrow)
            // A shift from yesterday that is still running stays here until you clock out.
            if let running = try deps.shifts.runningShift(), !shifts.contains(where: { $0.id == running.id }) {
                shifts.insert(running, at: 0)
            }
            items = shifts.compactMap { shift -> ShiftItem? in
                guard let job = jobs.first(where: { $0.id == shift.jobID }) else { return nil }
                return ShiftItem(shift: shift, job: job, calendar: calendar)
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    func tap(_ item: ShiftItem, now: Date = .now) {
        do {
            _ = try deps.clockShift.toggle(shiftID: item.id, now: now)
            clockChanges += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        load(now: now)
    }

    func clearClock(_ item: ShiftItem) {
        do {
            _ = try deps.clockShift.clear(shiftID: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        load()
    }
}
