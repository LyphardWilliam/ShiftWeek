// File: ShiftWeek/Features/Week/ShiftFormViewModel.swift
import Foundation
import ShiftCore

@Observable final class ShiftFormViewModel {
    let jobs: [Job]
    let isEditing: Bool
    var jobID: UUID?
    var day: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
    var note: String
    var errorMessage: String?
    private let original: Shift?
    private let calendar: Calendar
    private let saveShift: SaveShiftUseCase

    /// A new shift defaults to the first job, 9:00 am – 5:00 pm with a 30 minute break.
    init(deps: AppDependencies, shift: Shift? = nil, day: Date = .now) {
        let calendar = deps.calendar
        let jobs: [Job]
        var loadError: String?
        do {
            jobs = try deps.jobs.allJobs()
        } catch {
            jobs = []
            loadError = "Something went wrong. Please try again."
        }
        self.calendar = calendar
        self.jobs = jobs
        saveShift = deps.saveShift
        original = shift
        isEditing = shift != nil
        jobID = shift?.jobID ?? jobs.first?.id
        self.day = calendar.startOfDay(for: shift?.start ?? day)
        startTime = shift?.start ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)!
        endTime = shift?.end ?? calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day)!
        breakMinutes = shift?.unpaidBreakMinutes ?? 30
        note = shift?.note ?? ""
        errorMessage = loadError
    }

    var endsNextDay: Bool {
        on(day, endTime) <= on(day, startTime)
    }

    var paidMinutesPreview: Int {
        let times = shiftTimes()
        return max(0, Int(times.end.timeIntervalSince(times.start) / 60) - breakMinutes)
    }

    /// Returns true when the shift was saved and the form can close.
    func save() -> Bool {
        guard let jobID else {
            errorMessage = ShiftError.jobNotFound.localizedDescription
            return false
        }
        let times = shiftTimes()
        // Editing keeps the id and any clock times.
        var shift = original ?? Shift(jobID: jobID, start: times.start, end: times.end)
        shift.jobID = jobID
        shift.start = times.start
        shift.end = times.end
        shift.unpaidBreakMinutes = breakMinutes
        shift.note = note
        do {
            _ = try saveShift.execute(shift)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // An end time at or before the start time means the shift finishes the next day.
    private func shiftTimes() -> (start: Date, end: Date) {
        let start = on(day, startTime)
        var end = on(day, endTime)
        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end)!
        }
        return (start, end)
    }

    private func on(_ day: Date, _ time: Date) -> Date {
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: day)!
    }
}
