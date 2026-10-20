// File: Packages/ShiftCore/Tests/ShiftCoreTests/PayCalculatorTests.swift
import Foundation
import ShiftCore
import Testing

// 测试共用的工具：定义一个悉尼时区的日历，不受当前电脑时区影响。
let sydney: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
    calendar.firstWeekday = 2
    return calendar
}()

// 辅助函数：快速生成特定时间的 Date 对象。
func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    sydney.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

// 辅助函数：将字符串转为 Decimal，避免用 Double 造成精度丢失。
func money(_ text: String) -> Decimal {
    Decimal(string: text)!
}

// 定义两组测试用的费率标准。
let r1 = PayRates(hourlyRate: money("28.50"))
let r2 = PayRates(hourlyRate: 30, saturdayMultiplier: money("1.25"),
                  sundayMultiplier: money("1.5"), publicHolidayMultiplier: money("2.5"))

/// Tests for PayCalculator.
struct PayCalculatorTests {
    let tuesday = WorkedShift(start: date(2026, 10, 20, 9, 0), end: date(2026, 10, 20, 17, 0),
                              unpaidBreakMinutes: 30, rates: r1)

    /// Checks that scheduled shifts subtract unpaid breaks, and that breaks longer than the shift result in zero pay.
    // 检查排班班次扣除了无薪休息，以及休息比班还长时计薪为零，不会出现负数。
    @Test func scheduledShiftSubtractsBreak() {
        #expect(PayCalculator.paidMinutes(for: tuesday) == 450)
        #expect(PayCalculator.multiplier(for: tuesday, calendar: sydney) == 1)
        #expect(PayCalculator.pay(for: tuesday, calendar: sydney) == money("213.75"))

        let tooShort = WorkedShift(start: date(2026, 10, 20, 9, 0), end: date(2026, 10, 20, 9, 30),
                                   unpaidBreakMinutes: 45, rates: r1)
        #expect(PayCalculator.paidMinutes(for: tooShort) == 0)
        #expect(PayCalculator.pay(for: tooShort, calendar: sydney) == 0)
    }

    /// Checks that clock times override scheduled times and pay is rounded to cents.
    // 检查打卡时间覆盖排班时间，且工资最后能正确四舍五入到分。
    @Test func clockTimesReplaceScheduleAndRound() {
        var clocked = tuesday
        clocked.clockIn = date(2026, 10, 20, 9, 10)
        clocked.clockOut = date(2026, 10, 20, 17, 5)

        #expect(PayCalculator.paidMinutes(for: clocked) == 445)
        #expect(PayCalculator.pay(for: clocked, calendar: sydney) == money("211.38"))
        #expect(PayCalculator.total(for: [tuesday, clocked], calendar: sydney)
                == PayTotal(paidMinutes: 895, pay: money("425.13")))
    }

    /// Checks that overnight shifts use the rate of the day they started.
    // 检查跨午夜的班次，整班使用开始那天的费率，不在午夜切开。
    @Test func overnightShiftUsesStartDay() {
        let saturdayNight = WorkedShift(start: date(2026, 10, 24, 22, 0), end: date(2026, 10, 25, 2, 0),
                                        rates: r2)
        #expect(PayCalculator.multiplier(for: saturdayNight, calendar: sydney) == money("1.25"))
        #expect(PayCalculator.paidMinutes(for: saturdayNight) == 240)
        #expect(PayCalculator.pay(for: saturdayNight, calendar: sydney) == money("150.00"))
    }

    /// Checks that public holidays take precedence over Sunday rates.
    // 检查公众假期的倍率优先级高于周日倍率。
    @Test func publicHolidayBeatsSunday() {
        let boxingDay = WorkedShift(start: date(2027, 12, 26, 10, 0), end: date(2027, 12, 26, 14, 0),
                                    rates: r2)
        #expect(PayCalculator.multiplier(for: boxingDay, calendar: sydney) == money("2.5"))
        #expect(PayCalculator.pay(for: boxingDay, calendar: sydney) == money("300.00"))
        #expect(NSWPublicHolidays.contains(date(2026, 12, 28), calendar: sydney))
        #expect(!NSWPublicHolidays.contains(date(2026, 12, 27), calendar: sydney))
    }
}