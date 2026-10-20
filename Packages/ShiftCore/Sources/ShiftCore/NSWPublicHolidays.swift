// File: Packages/ShiftCore/Sources/ShiftCore/NSWPublicHolidays.swift
import Foundation

/// Represents the public holidays in New South Wales, Australia.
public enum NSWPublicHolidays {
    
    /// The list of holiday dates in "yyyy-MM-dd" format.
    /// Note: Only includes dates from October 2026 to the end of 2027.
    // 假期日期列表，格式为 yyyy-MM-dd。只包含 2026年10月 到 2027年底。
    public static let dates: [String] = [
        "2026-10-05",
        "2026-12-25",
        "2026-12-26",
        "2026-12-28",
        "2027-01-01",
        "2027-01-26",
        "2027-03-26",
        "2027-03-27",
        "2027-03-28",
        "2027-03-29",
        "2027-04-25",
        "2027-04-26",
        "2027-06-14",
        "2027-10-04",
        "2027-12-25",
        "2027-12-26",
        "2027-12-27",
        "2027-12-28"
    ]

    /// Checks if the given date is a public holiday.
    /// - Parameters:
    ///   - date: The date to check.
    ///   - calendar: The calendar used to extract the date components.
    /// - Returns: True if it is a public holiday, false otherwise.
    // 检查给定日期是否为公众假期。需要传入具体的日历，以提取年月日进行比对。
    public static func contains(_ date: Date, calendar: Calendar) -> Bool {
        // 提取年月日组件。
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        
        // 拼装成 yyyy-MM-dd 格式的字符串进行比对。
        let key = "\(parts.year ?? 0)-\(twoDigits(parts.month ?? 0))-\(twoDigits(parts.day ?? 0))"
        return dates.contains(key)
    }

    // 辅助函数，将小于 10 的数字前面补 0，确保月份和日期是两位数。
    private static func twoDigits(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }
}