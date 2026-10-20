// File: Packages/ShiftCore/Sources/ShiftCore/FortnightCalculator.swift
import Foundation

/// Represents the status of a fortnight's working hours against visa limits.
public enum FortnightStatus: Sendable, Equatable {
    case ok, nearLimit, overLimit
}

/// The result of a fortnight calculation.
public struct FortnightResult: Sendable, Equatable {
    public var firstWeekStart: Date
    public var paidMinutes: Int
    public var status: FortnightStatus
}

/// A utility namespace for calculating fortnightly working hours (e.g., for student visas).
public enum FortnightCalculator {
    public static let reminderMinutes = 2_400   // 40 小时提醒线
    public static let limitMinutes = 2_880      // 48 小时上限线

    /// Calculates the Monday 00:00 of the week containing the given date.
    // 计算包含给定日期的那一周的周一 00:00。
    public static func weekStart(for date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        // 在 Foundation 中，Sunday = 1, Monday = 2 ... Saturday = 7。
        let weekday = calendar.component(.weekday, from: day)
        
        // 计算距离周一过去的天数。
        let daysSinceMonday = (weekday + 5) % 7
        return addDays(-daysSinceMonday, to: day, calendar: calendar)
    }

    /// Calculates the total paid minutes within a specific week.
    // 计算特定一周内的总计薪分钟数。
    public static func paidMinutes(_ shifts: [WorkedShift], inWeekStarting weekStart: Date,
                                   calendar: Calendar) -> Int {
        let weekEnd = addDays(7, to: weekStart, calendar: calendar)
        var minutes = 0
        for shift in shifts where shift.start >= weekStart && shift.start < weekEnd {
            minutes += PayCalculator.paidMinutes(for: shift)
        }
        return minutes
    }

    /// Compares "last week + this week" with "this week + next week" and keeps the bigger one.
    // 对比“上周+本周” 与 “本周+下周”，取工时较多的一个双周窗口返回。
    public static func busiestFortnight(around weekStart: Date, shifts: [WorkedShift],
                                        calendar: Calendar) -> FortnightResult {
        let lastWeekStart = addDays(-7, to: weekStart, calendar: calendar)
        let nextWeekStart = addDays(7, to: weekStart, calendar: calendar)

        let lastWeek = paidMinutes(shifts, inWeekStarting: lastWeekStart, calendar: calendar)
        let thisWeek = paidMinutes(shifts, inWeekStarting: weekStart, calendar: calendar)
        let nextWeek = paidMinutes(shifts, inWeekStarting: nextWeekStart, calendar: calendar)

        let earlier = lastWeek + thisWeek
        let later = thisWeek + nextWeek
        
        // 如果后一个双周工时更多，则返回后一个。
        if later > earlier {
            return FortnightResult(firstWeekStart: weekStart, paidMinutes: later,
                                   status: status(forMinutes: later))
        }
        return FortnightResult(firstWeekStart: lastWeekStart, paidMinutes: earlier,
                               status: status(forMinutes: earlier))
    }

    /// Returns the status based on the threshold limits.
    // 根据阈值限制（40小时/48小时）返回状态。
    public static func status(forMinutes minutes: Int) -> FortnightStatus {
        if minutes < reminderMinutes { return .ok }
        if minutes <= limitMinutes { return .nearLimit }
        return .overLimit
    }

    // 辅助函数，安全地加减天数（使用日历运算以规避夏令时导致的小时缺失问题）。
    private static func addDays(_ days: Int, to date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}