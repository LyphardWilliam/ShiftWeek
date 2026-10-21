// File: ShiftWeek/Features/Pay/PayViewModel.swift
import Foundation
import ShiftCore

@Observable final class PayViewModel {
    struct Row: Identifiable {
        let payslip: Payslip
        let job: Job
        let verdict: PayslipVerdict?
        var id: UUID { payslip.id }
    }

    private(set) var rows: [Row] = []
    private(set) var hasJobs = false
    var errorMessage: String?
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }

    func load() {
        do {
            let jobs = try deps.jobs.allJobs()
            hasJobs = !jobs.isEmpty
            rows = try deps.payslips.allPayslips().compactMap { payslip -> Row? in
                guard let job = jobs.first(where: { $0.id == payslip.jobID }) else { return nil }
                let verdict = try? deps.comparePayslip.execute(payslip).comparison.verdict
                return Row(payslip: payslip, job: job, verdict: verdict)
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    func delete(_ row: Row) {
        do {
            try deps.deletePayslip.execute(id: row.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        load()
    }

    func check(for payslip: Payslip) -> PayslipCheck? {
        do {
            return try deps.comparePayslip.execute(payslip)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
