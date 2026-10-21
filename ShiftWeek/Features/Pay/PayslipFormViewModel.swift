// File: ShiftWeek/Features/Pay/PayslipFormViewModel.swift
import Foundation
import ShiftCore

@Observable final class PayslipFormViewModel {
    let jobs: [Job]
    var jobID: UUID?
    var periodStart: Date
    var periodEnd: Date
    var hoursText = ""
    var grossText = ""
    var errorMessage: String?
    private let savePayslip: SavePayslipUseCase

    /// The period defaults to last week, Monday to Sunday.
    init(deps: AppDependencies, today: Date = .now) {
        let calendar = deps.calendar
        let jobs = (try? deps.jobs.allJobs()) ?? []
        let thisMonday = FortnightCalculator.weekStart(for: today, calendar: calendar)
        self.jobs = jobs
        jobID = jobs.first?.id
        periodStart = calendar.date(byAdding: .day, value: -7, to: thisMonday)!
        periodEnd = calendar.date(byAdding: .day, value: -1, to: thisMonday)!
        savePayslip = deps.savePayslip
    }

    /// Returns true when the payslip was saved and the form can close.
    func save() -> Bool {
        guard let jobID else {
            errorMessage = PayslipError.jobNotFound.localizedDescription
            return false
        }
        let payslip = Payslip(jobID: jobID, periodStart: periodStart, periodEnd: periodEnd,
                              hours: number(hoursText), gross: number(grossText))
        do {
            _ = try savePayslip.execute(payslip)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // Text that isn't a number becomes 0, which the use case then rejects with a clear message.
    private func number(_ text: String) -> Decimal {
        Decimal(string: text.trimmingCharacters(in: .whitespaces), locale: Locale(identifier: "en_AU")) ?? 0
    }
}
