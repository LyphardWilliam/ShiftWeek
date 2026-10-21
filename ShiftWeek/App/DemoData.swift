// File: ShiftWeek/App/DemoData.swift
#if DEBUG
import Foundation
import ShiftCore

/// Sample jobs, shifts and payslips. Writes straight to the repositories.
enum DemoData {
    static func load(into deps: AppDependencies, now: Date = .now) throws {
        let calendar = deps.calendar
        for job in try deps.jobs.allJobs() {
            try deps.jobs.delete(id: job.id)
        }

        let cafe = Job(name: "Corner Cafe", colorIndex: 0, hourlyRate: Decimal(string: "28.50")!,
                       saturdayMultiplier: Decimal(string: "1.25")!, sundayMultiplier: Decimal(string: "1.50")!,
                       holidayMultiplier: Decimal(string: "2.25")!)
        let mart = Job(name: "FreshMart", colorIndex: 5, hourlyRate: 26,
                       saturdayMultiplier: Decimal(string: "1.25")!, sundayMultiplier: Decimal(string: "1.50")!,
                       holidayMultiplier: Decimal(string: "2.50")!)
        try deps.jobs.save(cafe)
        try deps.jobs.save(mart)

        let today = calendar.startOfDay(for: now)
        let thisMonday = FortnightCalculator.weekStart(for: now, calendar: calendar)
        let lastMonday = calendar.date(byAdding: .day, value: -7, to: thisMonday)!

        func at(_ day: Date, plus days: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let date = calendar.date(byAdding: .day, value: days, to: day)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        }

        var shifts = [
            Shift(jobID: cafe.id, start: at(lastMonday, plus: 0, 7), end: at(lastMonday, plus: 0, 13)),
            Shift(jobID: mart.id, start: at(lastMonday, plus: 2, 17), end: at(lastMonday, plus: 2, 21)),
            Shift(jobID: cafe.id, start: at(lastMonday, plus: 5, 8), end: at(lastMonday, plus: 5, 14, 30),
                  unpaidBreakMinutes: 30),
            Shift(jobID: mart.id, start: at(lastMonday, plus: 6, 10), end: at(lastMonday, plus: 6, 15),
                  unpaidBreakMinutes: 30),
        ]

        // This week's regular shifts; the one that falls on today is replaced by today's two shifts.
        let regular = [
            Shift(jobID: cafe.id, start: at(thisMonday, plus: 0, 7), end: at(thisMonday, plus: 0, 13)),
            Shift(jobID: mart.id, start: at(thisMonday, plus: 2, 17), end: at(thisMonday, plus: 2, 21)),
            Shift(jobID: cafe.id, start: at(thisMonday, plus: 5, 8), end: at(thisMonday, plus: 5, 14, 30),
                  unpaidBreakMinutes: 30),
        ]
        shifts += regular.filter { !calendar.isDate($0.start, inSameDayAs: today) }

        shifts.append(Shift(jobID: cafe.id, start: at(today, plus: 0, 6), end: at(today, plus: 0, 9),
                            note: "Breakfast rush",
                            clockIn: at(today, plus: 0, 5, 58), clockOut: at(today, plus: 0, 9, 4)))
        shifts.append(Shift(jobID: mart.id, start: at(today, plus: 0, 18), end: at(today, plus: 1, 0, 30),
                            unpaidBreakMinutes: 30, note: "Stocktake"))

        for shift in shifts {
            try deps.shifts.save(shift)
        }

        let lastSunday = at(lastMonday, plus: 6, 0)
        try deps.payslips.save(Payslip(jobID: cafe.id, periodStart: lastMonday, periodEnd: lastSunday,
                                       hours: 6, gross: 171))
        try deps.payslips.save(Payslip(jobID: mart.id, periodStart: lastMonday, periodEnd: lastSunday,
                                       hours: Decimal(string: "8.50")!, gross: Decimal(string: "279.50")!))

        UserDefaults.standard.set(true, forKey: "visaModeOn")
    }
}
#endif
