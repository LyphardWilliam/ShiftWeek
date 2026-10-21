// File: Packages/ShiftCore/Tests/ShiftCoreTests/UseCaseTests.swift
import Foundation
import ShiftCore
import Testing

/// Tests for the domain use cases using mock repositories.
struct UseCaseTests {
    // 为每个测试重新初始化 mock 仓库，确保测试之间相互隔离。
    let jobs = MockJobRepository()
    let shifts = MockShiftRepository()
    let payslips = MockPayslipRepository()
    
    // 定义一个公共的测试工作：Corner Cafe，时薪 $28.50。
    let cafe = Job(name: "Corner Cafe", hourlyRate: Decimal(string: "28.50")!,
                   saturdayMultiplier: Decimal(string: "1.25")!)

    // 测试：保存工作时，名字不能为空。
    @Test func saveJobRejectsEmptyName() {
        let saveJob = SaveJobUseCase(jobs: jobs)

        #expect(throws: JobError.emptyName) {
            try saveJob.execute(Job(name: "   ", hourlyRate: Decimal(string: "28.50")!))
        }
        #expect(jobs.items.isEmpty)
    }

    // 测试：保存工作时，名字不能重复（忽略大小写和首尾空格）。
    @Test func saveJobRejectsDuplicateName() {
        jobs.items = [cafe]
        let saveJob = SaveJobUseCase(jobs: jobs)

        #expect(throws: JobError.duplicateName) {
            try saveJob.execute(Job(name: " corner cafe ", hourlyRate: 25))
        }
        #expect(jobs.items.count == 1)
    }

    // 测试：保存班次时，不能与已有班次重叠。
    @Test func saveShiftRejectsOverlap() {
        jobs.items = [cafe]
        shifts.items = [Shift(jobID: cafe.id, start: date(2026, 10, 20, 9), end: date(2026, 10, 20, 17))]
        let saveShift = SaveShiftUseCase(jobs: jobs, shifts: shifts)

        #expect(throws: ShiftError.overlaps) {
            try saveShift.execute(Shift(jobID: cafe.id, start: date(2026, 10, 20, 16), end: date(2026, 10, 20, 20)))
        }
        #expect(shifts.items.count == 1)
    }

    // 测试：打卡流程（上班 -> 下班 -> 不能重复打卡）。
    @Test func clockInThenOutRecordsTimes() throws {
        let shift = Shift(jobID: cafe.id, start: date(2026, 10, 20, 9), end: date(2026, 10, 20, 17))
        shifts.items = [shift]
        let clock = ClockShiftUseCase(shifts: shifts, calendar: sydney)

        // 第一次打卡：上班。
        let clockedIn = try clock.toggle(shiftID: shift.id, now: date(2026, 10, 20, 9, 5))
        #expect(clockedIn.clockIn == date(2026, 10, 20, 9, 5))
        #expect(clockedIn.clockState == .working(since: date(2026, 10, 20, 9, 5)))

        // 第二次打卡：下班。
        let clockedOut = try clock.toggle(shiftID: shift.id, now: date(2026, 10, 20, 17, 2))
        #expect(clockedOut.clockOut == date(2026, 10, 20, 17, 2))
        #expect(clockedOut.clockState == .done(minutes: 477))

        // 第三次打卡：抛出错误（已完成）。
        #expect(throws: ClockError.alreadyFinished) {
            try clock.toggle(shiftID: shift.id, now: date(2026, 10, 20, 17, 10))
        }
    }

    // 测试：不能在不同的日子打卡。
    @Test func clockInRejectsOtherDay() {
        let shift = Shift(jobID: cafe.id, start: date(2026, 10, 21, 9), end: date(2026, 10, 21, 17))
        shifts.items = [shift]
        let clock = ClockShiftUseCase(shifts: shifts, calendar: sydney)

        #expect(throws: ClockError.notToday) {
            try clock.toggle(shiftID: shift.id, now: date(2026, 10, 20, 12))
        }
        #expect(shifts.items[0].clockIn == nil)
    }

    // 测试：保存工资单时，如果底层仓库报错，应该映射为领域错误 storageFailed。
    @Test func savePayslipMapsStorageError() {
        jobs.items = [cafe]
        payslips.failOnSave = true // 模拟仓库保存失败
        let savePayslip = SavePayslipUseCase(jobs: jobs, payslips: payslips, calendar: sydney)
        let payslip = Payslip(jobID: cafe.id, periodStart: date(2026, 10, 12), periodEnd: date(2026, 10, 18),
                              hours: 6, gross: 171)

        #expect(throws: PayslipError.storageFailed) {
            try savePayslip.execute(payslip)
        }
    }

    // 测试：对比工资单时，能正确识别出遗漏的班次（Check with employer）。
    @Test func comparePayslipFlagsMissingShift() throws {
        jobs.items = [cafe]
        shifts.items = [
            Shift(jobID: cafe.id, start: date(2026, 10, 12, 7), end: date(2026, 10, 12, 13)),
            Shift(jobID: cafe.id, start: date(2026, 10, 17, 8), end: date(2026, 10, 17, 14, 30),
                  unpaidBreakMinutes: 30),
            Shift(jobID: cafe.id, start: date(2026, 10, 19, 7), end: date(2026, 10, 19, 13)),   // 这个班不在发薪期内
        ]
        let compare = ComparePayslipUseCase(jobs: jobs, shifts: shifts, calendar: sydney)
        let payslip = Payslip(jobID: cafe.id, periodStart: date(2026, 10, 12), periodEnd: date(2026, 10, 18),
                              hours: Decimal(string: "6.00")!, gross: Decimal(string: "171.00")!)

        let check = try compare.execute(payslip)

        #expect(check.items.count == 2)
        #expect(check.comparison.recordedMinutes == 720)
        #expect(check.comparison.recordedPay == Decimal(string: "384.75")!)
        #expect(check.comparison.hoursDifference == Decimal(string: "-6.00")!)
        #expect(check.comparison.payDifference == Decimal(string: "-213.75")!)
        #expect(check.comparison.verdict == .checkWithEmployer)
    }
}