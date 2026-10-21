// File: Packages/ShiftCore/Sources/ShiftCore/Domain/PayUseCases.swift
import Foundation

/// A summary of a specific week's work, including the busiest fortnight.
public struct WeekSummary: Equatable, Sendable {
    public let weekStart: Date
    public let paidMinutes: Int
    public let estimatedPay: Decimal
    public let fortnight: FortnightResult        // 界面只在签证模式下显示这个字段
}

/// A use case for calculating the weekly summary.
public struct GetWeekSummaryUseCase {
    let jobs: any JobRepository
    let shifts: any ShiftRepository
    let calendar: Calendar

    public init(jobs: any JobRepository, shifts: any ShiftRepository, calendar: Calendar) {
        self.jobs = jobs
        self.shifts = shifts
        self.calendar = calendar
    }

    /// Calculates the total paid minutes, estimated pay, and busiest fortnight.
    // 计算指定周的工时和工资，以及最忙双周信息。
    public func execute(weekStart: Date) throws -> WeekSummary {
        // 取“上周”到“下周”三周的数据（为了算最忙双周）。
        let from = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let to = calendar.date(byAdding: .day, value: 14, to: weekStart)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // 先把所有工作的费率取出来，避免循环里重复查库。
        var ratesByJob: [UUID: PayRates] = [:]
        for job in try jobs.allJobs() {
            ratesByJob[job.id] = job.rates
        }
        
        // 查出这三周的班次，并转换为 WorkedShift（如果工作已删除则忽略该班次）。
        let worked = try shifts.shifts(from: from, to: to).compactMap { shift in
            ratesByJob[shift.jobID].map { shift.worked(rates: $0) }
        }

        // 筛选出“本周”的班次进行统计。
        let thisWeek = worked.filter { $0.start >= weekStart && $0.start < weekEnd }
        let total = PayCalculator.total(for: thisWeek, calendar: calendar)
        
        // 计算最忙双周。
        let fortnight = FortnightCalculator.busiestFortnight(around: weekStart, shifts: worked, calendar: calendar)
        
        return WeekSummary(weekStart: weekStart, paidMinutes: total.paidMinutes,
                           estimatedPay: total.pay, fortnight: fortnight)
    }
}

/// A use case for creating or updating a payslip with validation.
public struct SavePayslipUseCase {
    let jobs: any JobRepository
    let payslips: any PayslipRepository
    let calendar: Calendar

    public init(jobs: any JobRepository, payslips: any PayslipRepository, calendar: Calendar) {
        self.jobs = jobs
        self.payslips = payslips
        self.calendar = calendar
    }

    /// Validates and saves a payslip.
    // 校验工资单信息（工作存在、日期有效、工时和金额范围）并保存。
    public func execute(_ payslip: Payslip) throws -> Payslip {
        var payslip = payslip
        do {
            guard try jobs.job(id: payslip.jobID) != nil else { throw PayslipError.jobNotFound }

            // 将起止日期归到当天的 00:00，方便计算天数。
            payslip.periodStart = calendar.startOfDay(for: payslip.periodStart)
            payslip.periodEnd = calendar.startOfDay(for: payslip.periodEnd)
            
            // 校验规则：结束日期不能早于开始日期，且周期不能超过 31 天。
            let days = calendar.dateComponents([.day], from: payslip.periodStart, to: payslip.periodEnd).day ?? 0
            if payslip.periodEnd < payslip.periodStart || days > 30 { throw PayslipError.invalidPeriod }
            
            // 校验规则：工时必须在 0 到 200 之间。
            if payslip.hours <= 0 || payslip.hours > 200 { throw PayslipError.invalidHours }
            
            // 校验规则：税前工资必须大于 0。
            if payslip.gross <= 0 { throw PayslipError.invalidGross }

            try payslips.save(payslip)
            return payslip
        } catch let error as PayslipError {
            throw error
        } catch {
            throw PayslipError.storageFailed
        }
    }
}

/// A use case for deleting a payslip.
public struct DeletePayslipUseCase {
    let payslips: any PayslipRepository

    public init(payslips: any PayslipRepository) {
        self.payslips = payslips
    }

    public func execute(id: UUID) throws {
        do {
            try payslips.delete(id: id)
        } catch {
            throw PayslipError.storageFailed
        }
    }
}

/// The result of comparing a payslip against recorded shifts.
public struct PayslipCheck: Equatable, Sendable {
    public let job: Job
    public let items: [ShiftItem]                // 发薪期内的班次明细，按开始时间排序
    public let comparison: PayslipComparison
}

/// A use case for comparing a payslip with recorded shifts.
public struct ComparePayslipUseCase {
    let jobs: any JobRepository
    let shifts: any ShiftRepository
    let calendar: Calendar

    public init(jobs: any JobRepository, shifts: any ShiftRepository, calendar: Calendar) {
        self.jobs = jobs
        self.shifts = shifts
        self.calendar = calendar
    }

    /// Fetches the relevant shifts and compares them with the payslip data.
    // 查出对应发薪期内的班次，并与工资单数据进行对比。
    public func execute(_ payslip: Payslip) throws -> PayslipCheck {
        do {
            guard let job = try jobs.job(id: payslip.jobID) else { throw PayslipError.jobNotFound }

            // 查询范围是发薪期，结束日期要加 1 天（因为 periodEnd 是最后一天的 00:00）。
            let end = calendar.date(byAdding: .day, value: 1, to: payslip.periodEnd)!
            let items = try shifts.shifts(jobID: job.id, from: payslip.periodStart, to: end)
                .map { ShiftItem(shift: $0, job: job, calendar: calendar) }

            // 计算记录的总工资。
            let recorded = PayCalculator.total(for: items.map { $0.shift.worked(rates: job.rates) },
                                               calendar: calendar)
            
            // 调用对比器得出结果。
            let comparison = PayslipComparator.compare(recorded: recorded, payslipHours: payslip.hours,
                                                       payslipGross: payslip.gross)
            return PayslipCheck(job: job, items: items, comparison: comparison)
        } catch let error as PayslipError {
            throw error
        } catch {
            throw PayslipError.storageFailed
        }
    }
}