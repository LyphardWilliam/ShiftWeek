// File: Packages/ShiftCore/Tests/ShiftCoreTests/PayslipComparatorTests.swift
import Foundation
import ShiftCore
import Testing

/// Tests for PayslipComparator.
struct PayslipComparatorTests {
    
    /// Checks that a very small difference results in a Match verdict.
    // 检查金额差异极小时，结论为 Match（匹配）。
    @Test func smallDifferenceIsMatch() {
        let result = PayslipComparator.compare(recorded: PayTotal(paidMinutes: 450, pay: money("213.75")),
                                               payslipHours: money("7.50"), payslipGross: money("215.00"))
        #expect(result.verdict == .match)
        #expect(result.hoursDifference == 0)
        #expect(result.payDifference == money("1.25"))
    }

    /// Checks that a difference of exactly $10 results in a Close verdict.
    // 检查差额刚好达到 $10 时，结论为 Close（接近）。
    @Test func tenDollarGapIsClose() {
        let result = PayslipComparator.compare(recorded: PayTotal(paidMinutes: 600, pay: money("300.00")),
                                               payslipHours: money("10.00"), payslipGross: money("290.00"))
        #expect(result.verdict == .close)
        #expect(result.payDifference == money("-10.00"))
    }

    /// Checks that a massive gap (missing shift) results in Check with employer.
    // 检查差额巨大（例如漏排了一个班）时，结论为 Check with employer（需与雇主核实）。
    @Test func missingShiftIsCheckWithEmployer() {
        let result = PayslipComparator.compare(recorded: PayTotal(paidMinutes: 720, pay: money("384.75")),
                                               payslipHours: money("6.00"), payslipGross: money("171.00"))
        #expect(result.verdict == .checkWithEmployer)
        #expect(result.recordedHours == money("12.00"))
        #expect(result.hoursDifference == money("-6.00"))
        #expect(result.payDifference == money("-213.75"))
    }
}