// File: Packages/ShiftCore/Sources/ShiftCore/PayslipComparator.swift
import Foundation

/// Represents the verdict of comparing a payslip against recorded data.
public enum PayslipVerdict: String, Sendable, Equatable {
    case match, close, checkWithEmployer
}

/// Contains detailed comparison results between recorded work and a payslip.
public struct PayslipComparison: Sendable, Equatable {
    public var recordedMinutes: Int
    public var recordedHours: Decimal
    public var recordedPay: Decimal
    public var payslipHours: Decimal
    public var payslipGross: Decimal
    public var hoursDifference: Decimal   // 工资单减去记录
    public var payDifference: Decimal     // 工资单减去记录
    public var verdict: PayslipVerdict
}

/// A utility namespace for comparing recorded pay with payslip data.
public enum PayslipComparator {
    
    /// Compares recorded pay with payslip hours and gross pay to determine a verdict.
    // 将记录工资与工资单上的工时及税前总额进行对比，以得出最终结论。
    public static func compare(recorded: PayTotal, payslipHours: Decimal,
                               payslipGross: Decimal) -> PayslipComparison {
        // 将记录的分钟转换为小时（保留两位小数）。
        let recordedHours = PayCalculator.roundedToCents(Decimal(recorded.paidMinutes) / 60)
        let hoursDifference = PayCalculator.roundedToCents(payslipHours - recordedHours)
        let payDifference = PayCalculator.roundedToCents(payslipGross - recorded.pay)

        // Match 匹配的容差：15 分钟以内，且金额差在 max($2, 2%) 以内。
        let hoursTolerance = Decimal(25) / 100
        let matchTolerance = max(Decimal(2), PayCalculator.roundedToCents(recorded.pay * 2 / 100))
        
        // Close 接近的容差：金额差在 max($10, 5%) 以内。
        let closeTolerance = max(Decimal(10), PayCalculator.roundedToCents(recorded.pay * 5 / 100))

        let verdict: PayslipVerdict
        // 先判断精确匹配，再判断接近，两者都不满足则需联系雇主。
        if abs(hoursDifference) <= hoursTolerance && abs(payDifference) <= matchTolerance {
            verdict = .match
        } else if abs(payDifference) <= closeTolerance {
            verdict = .close
        } else {
            verdict = .checkWithEmployer
        }

        return PayslipComparison(recordedMinutes: recorded.paidMinutes,
                                 recordedHours: recordedHours,
                                 recordedPay: recorded.pay,
                                 payslipHours: payslipHours,
                                 payslipGross: payslipGross,
                                 hoursDifference: hoursDifference,
                                 payDifference: payDifference,
                                 verdict: verdict)
    }
}