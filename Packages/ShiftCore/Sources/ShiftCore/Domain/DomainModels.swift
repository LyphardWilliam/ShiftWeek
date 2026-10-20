// File: Packages/ShiftCore/Sources/ShiftCore/Domain/DomainModels.swift
import Foundation

/// Represents a job with its pay rates and visual properties.
public struct Job: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var colorIndex: Int
    public var hourlyRate: Decimal
    public var saturdayMultiplier: Decimal
    public var sundayMultiplier: Decimal
    public var holidayMultiplier: Decimal

    // 初始化方法，提供默认值（UUID、颜色、倍率等）。
    public init(id: UUID = UUID(), name: String, colorIndex: Int = 0, hourlyRate: Decimal,
                saturdayMultiplier: Decimal = 1, sundayMultiplier: Decimal = 1, holidayMultiplier: Decimal = 1) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.hourlyRate = hourlyRate
        self.saturdayMultiplier = saturdayMultiplier
        self.sundayMultiplier = sundayMultiplier
        self.holidayMultiplier = holidayMultiplier
    }

    // 将当前工作转换为用于计算工资的 PayRates 对象。
    public var rates: PayRates {
        PayRates(hourlyRate: hourlyRate, saturdayMultiplier: saturdayMultiplier,
                 sundayMultiplier: sundayMultiplier, publicHolidayMultiplier: holidayMultiplier)
    }
}

/// Represents the current clock state of a shift.
public enum ClockState: Equatable, Sendable {
    case notStarted
    case working(since: Date)
    case done(minutes: Int)
}

/// Represents a single scheduled shift with optional clock-in and clock-out times.
public struct Shift: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var jobID: UUID
    public var start: Date
    public var end: Date
    public var unpaidBreakMinutes: Int
    public var note: String
    public var clockIn: Date?
    public var clockOut: Date?

    // 初始化方法。注意：跨午夜的班次，end 是第二天的 Date。
    public init(id: UUID = UUID(), jobID: UUID, start: Date, end: Date, unpaidBreakMinutes: Int = 0,
                note: String = "", clockIn: Date? = nil, clockOut: Date? = nil) {
        self.id = id
        self.jobID = jobID
        self.start = start
        self.end = end
        self.unpaidBreakMinutes = unpaidBreakMinutes
        self.note = note
        self.clockIn = clockIn
        self.clockOut = clockOut
    }

    // 根据打卡时间推导出当前的打卡状态（没打卡 / 正在工作 / 已完成）。
    public var clockState: ClockState {
        guard let clockIn else { return .notStarted }
        guard let clockOut else { return .working(since: clockIn) }
        // 这里的分钟数是实际在岗时间（不扣休息），用于 UI 显示。
        return .done(minutes: Int((clockOut.timeIntervalSince(clockIn) / 60).rounded()))
    }

    // 将 Shift 转换为 WorkedShift，方便交给 PayCalculator 计算工资。
    public func worked(rates: PayRates) -> WorkedShift {
        WorkedShift(start: start, end: end, clockIn: clockIn, clockOut: clockOut,
                    unpaidBreakMinutes: unpaidBreakMinutes, rates: rates)
    }
}

/// Represents a payslip entered by the user for a specific pay period.
public struct Payslip: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var jobID: UUID
    public var periodStart: Date
    public var periodEnd: Date
    public var hours: Decimal
    public var gross: Decimal

    public init(id: UUID = UUID(), jobID: UUID, periodStart: Date, periodEnd: Date, hours: Decimal, gross: Decimal) {
        self.id = id
        self.jobID = jobID
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.hours = hours
        self.gross = gross
    }
}

/// A composite model representing a shift with its associated job and calculated pay.
public struct ShiftItem: Identifiable, Equatable, Sendable {
    public let shift: Shift
    public let job: Job
    public let paidMinutes: Int
    public let pay: Decimal
    public var id: UUID { shift.id }

    // 组合班次、工作与日历，直接计算出计薪分钟和金额，供 UI 直接绑定使用。
    public init(shift: Shift, job: Job, calendar: Calendar) {
        let worked = shift.worked(rates: job.rates)
        self.shift = shift
        self.job = job
        paidMinutes = PayCalculator.paidMinutes(for: worked)
        pay = PayCalculator.pay(for: worked, calendar: calendar)
    }
}