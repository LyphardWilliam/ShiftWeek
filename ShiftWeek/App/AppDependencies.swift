// File: ShiftWeek/App/AppDependencies.swift
import Foundation
import ShiftCore
import SwiftData

/// Holds the repositories and builds the use cases. Passed down to every screen.
final class AppDependencies {
    let jobs: any JobRepository
    let shifts: any ShiftRepository
    let payslips: any PayslipRepository
    let calendar: Calendar
    let usesAppGroup: Bool        // false: the widget will show "Open ShiftWeek"
    let storeFailed: Bool         // true: running on an in-memory store
    private let container: ModelContainer?

    init(jobs: any JobRepository, shifts: any ShiftRepository, payslips: any PayslipRepository,
         calendar: Calendar = .shiftWeek, usesAppGroup: Bool = false, storeFailed: Bool = false,
         container: ModelContainer? = nil) {
        self.jobs = jobs
        self.shifts = shifts
        self.payslips = payslips
        self.calendar = calendar
        self.usesAppGroup = usesAppGroup
        self.storeFailed = storeFailed
        self.container = container
    }

    convenience init(container: ModelContainer, usesAppGroup: Bool, storeFailed: Bool) {
        let context = container.mainContext
        self.init(jobs: SwiftDataJobRepository(context: context),
                  shifts: SwiftDataShiftRepository(context: context),
                  payslips: SwiftDataPayslipRepository(context: context),
                  usesAppGroup: usesAppGroup, storeFailed: storeFailed, container: container)
    }

    var saveJob: SaveJobUseCase { SaveJobUseCase(jobs: jobs) }
    var deleteJob: DeleteJobUseCase { DeleteJobUseCase(jobs: jobs) }
    var saveShift: SaveShiftUseCase { SaveShiftUseCase(jobs: jobs, shifts: shifts) }
    var deleteShift: DeleteShiftUseCase { DeleteShiftUseCase(shifts: shifts) }
    var clockShift: ClockShiftUseCase { ClockShiftUseCase(shifts: shifts, calendar: calendar) }
    var weekSummary: GetWeekSummaryUseCase { GetWeekSummaryUseCase(jobs: jobs, shifts: shifts, calendar: calendar) }
    var savePayslip: SavePayslipUseCase { SavePayslipUseCase(jobs: jobs, payslips: payslips, calendar: calendar) }
    var deletePayslip: DeletePayslipUseCase { DeletePayslipUseCase(payslips: payslips) }
    var comparePayslip: ComparePayslipUseCase {
        ComparePayslipUseCase(jobs: jobs, shifts: shifts, calendar: calendar)
    }

    #if DEBUG
    /// In-memory store filled with the demo data, for SwiftUI previews.
    static func preview() -> AppDependencies {
        let container = try! SharedStore.makeInMemoryContainer()
        let deps = AppDependencies(container: container, usesAppGroup: false, storeFailed: false)
        try? DemoData.load(into: deps)
        return deps
    }
    #endif
}
