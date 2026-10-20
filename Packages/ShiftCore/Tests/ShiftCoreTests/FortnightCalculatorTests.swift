// File: Packages/ShiftCore/Tests/ShiftCoreTests/FortnightCalculatorTests.swift
import Foundation
import ShiftCore
import Testing

/// Tests for FortnightCalculator.
struct FortnightCalculatorTests {
    // 辅助函数：快速生成一个班次。
    func shift(_ month: Int, _ day: Int, from startHour: Int, to endHour: Int) -> WorkedShift {
        WorkedShift(start: date(2026, month, day, startHour), end: date(2026, month, day, endHour), rates: r1)
    }

    /// Checks that the busiest fortnight is correctly identified among three weeks.
    // 检查在三周的数据中，能正确找出工时最多的那个双周窗口（本周+下周）。
    @Test func busiestFortnightPicksLaterWindow() {
        let shifts = [
            shift(10, 12, from: 8, to: 18), shift(10, 13, from: 8, to: 18),      // 上周：1200 分钟
            shift(10, 19, from: 8, to: 19), shift(10, 20, from: 8, to: 19),      // 本周：1320 分钟
            shift(10, 26, from: 8, to: 17), shift(10, 27, from: 8, to: 17),
            shift(10, 28, from: 8, to: 17)                                       // 下周：1620 分钟
        ]

        #expect(FortnightCalculator.weekStart(for: date(2026, 10, 25, 23, 30), calendar: sydney)
                == date(2026, 10, 19))
        #expect(FortnightCalculator.paidMinutes(shifts, inWeekStarting: date(2026, 10, 12), calendar: sydney)
                == 1200)

        let result = FortnightCalculator.busiestFortnight(around: date(2026, 10, 19), shifts: shifts,
                                                          calendar: sydney)
        #expect(result.firstWeekStart == date(2026, 10, 19))
        #expect(result.paidMinutes == 2940)
        #expect(result.status == .overLimit)
    }

    /// Checks the exact threshold boundaries for visa status.
    // 检查签证状态（40小时提醒，48小时超限）的确切临界值。
    @Test func fortnightStatusThresholds() {
        #expect(FortnightCalculator.status(forMinutes: 2399) == .ok)
        #expect(FortnightCalculator.status(forMinutes: 2400) == .nearLimit)
        #expect(FortnightCalculator.status(forMinutes: 2880) == .nearLimit)
        #expect(FortnightCalculator.status(forMinutes: 2881) == .overLimit)
    }
}