// File: Packages/ShiftCore/Sources/ShiftCore/PayCalculator.swift
import Foundation

/// Represents the pay rates for a job, including base rate and multipliers.
public struct PayRates: Sendable, Equatable {
    public var hourlyRate: Decimal
    public var saturdayMultiplier: Decimal
    public var sundayMultiplier: Decimal
    public var publicHolidayMultiplier: Decimal

    // 初始化方法，周六、周日、公众假期的倍率默认值为 1。
    public init(hourlyRate: Decimal, saturdayMultiplier: Decimal = 1,
                sundayMultiplier: Decimal = 1, publicHolidayMultiplier: Decimal = 1) {
        self.hourlyRate = hourlyRate
        self.saturdayMultiplier = saturdayMultiplier
        self.sundayMultiplier = sundayMultiplier
        self.publicHolidayMultiplier = publicHolidayMultiplier
    }
}

/// Represents a single shift that has been worked, containing rostered and clocked times.
public struct WorkedShift: Sendable, Equatable {
    public var start: Date
    public var end: Date
    public var clockIn: Date?
    public var clockOut: Date?
    public var unpaidBreakMinutes: Int
    public var rates: PayRates

    // 初始化方法，打卡时间是可选的（没打卡就按排班时间算）。
    public init(start: Date, end: Date, clockIn: Date? = nil, clockOut: Date? = nil,
                unpaidBreakMinutes: Int = 0, rates: PayRates) {
        self.start = start
        self.end = end
        self.clockIn = clockIn
        self.clockOut = clockOut
        self.unpaidBreakMinutes = unpaidBreakMinutes
        self.rates = rates
    }
}

/// Represents the total paid minutes and pay for a collection of shifts.
public struct PayTotal: Sendable, Equatable {
    public var paidMinutes: Int
    public var pay: Decimal

    public init(paidMinutes: Int, pay: Decimal) {
        self.paidMinutes = paidMinutes
        self.pay = pay
    }
}

/// A utility namespace for calculating pay based on shifts and rates.
public enum PayCalculator {
    
    /// Calculates the paid minutes for a single shift.
    /// Note: Clock times override scheduled times. Unpaid break is always subtracted.
    // 计算单个班次的计薪分钟数。优先使用打卡时间，如果没有则用排班时间。最后扣除无薪休息时间。
    public static func paidMinutes(for shift: WorkedShift) -> Int {
        // 优先使用实际打卡时间。
        let from = shift.clockIn ?? shift.start
        let to = shift.clockOut ?? shift.end
        
        // 计算时间差并四舍五入到最近的分钟。
        let minutes = Int((to.timeIntervalSince(from) / 60).rounded())
        
        // 扣除无薪休息时间，最小为 0（防止休息时间比班还长导致负数）。
        return max(0, minutes - shift.unpaidBreakMinutes)
    }

    /// Returns the pay multiplier based on public holidays and weekends.
    /// Important: The multiplier is based entirely on the start day of the shift.
    // 根据公众假期和周末返回工资倍率。注意：倍率完全基于班次的开始日期（跨午夜也不切开）。
    public static func multiplier(for shift: WorkedShift, calendar: Calendar) -> Decimal {
        // 公众假期优先级最高。
        if NSWPublicHolidays.contains(shift.start, calendar: calendar) {
            return shift.rates.publicHolidayMultiplier
        }
        
        // Weekday 1 是周日，7 是周六。
        switch calendar.component(.weekday, from: shift.start) {
        case 1: return shift.rates.sundayMultiplier
        case 7: return shift.rates.saturdayMultiplier
        default: return 1
        }
    }

    /// Calculates the exact pay for a single shift.
    // 计算单个班次的具体工资金额。
    public static func pay(for shift: WorkedShift, calendar: Calendar) -> Decimal {
        // 获取计薪分钟数并转换为 Decimal。
        let minutes = Decimal(paidMinutes(for: shift))
        
        // 基础时薪乘以倍率。
        let rate = shift.rates.hourlyRate * multiplier(for: shift, calendar: calendar)
        
        // 分钟数乘以费率，除以 60 得到最终金额，最后四舍五入到分。
        return roundedToCents(minutes * rate / 60)
    }

    /// Sums up the total paid minutes and pay for multiple shifts.
    // 汇总多个班次的总计薪分钟数和总工资。
    public static func total(for shifts: [WorkedShift], calendar: Calendar) -> PayTotal {
        var total = PayTotal(paidMinutes: 0, pay: 0)
        for shift in shifts {
            // 分钟直接累加，金额每笔先四舍五入再累加，防止精度丢失导致总和对不上。
            total.paidMinutes += paidMinutes(for: shift)
            total.pay += pay(for: shift, calendar: calendar)
        }
        return total
    }

    /// Rounds a decimal value to two decimal places (cents) using standard rounding.
    // 使用标准的四舍五入，将十进制数值保留两位小数（精确到分）。
    public static func roundedToCents(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }
}