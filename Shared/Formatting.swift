// File: Shared/Formatting.swift
import SwiftUI

extension Calendar {
    /// Gregorian calendar with Monday as the first day of the week.
    static var shiftWeek: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = .current
        calendar.locale = Locale(identifier: "en_AU")
        return calendar
    }
}

enum JobPalette {
    static let names = ["Orange", "Red", "Pink", "Purple", "Indigo", "Blue", "Teal", "Green"]
    static let colors: [Color] = [.orange, .red, .pink, .purple, .indigo, .blue, .teal, .green]

    static func color(_ index: Int) -> Color {
        colors[abs(index) % colors.count]
    }

    static func name(_ index: Int) -> String {
        names[abs(index) % names.count]
    }
}

enum Format {
    static let australia = Locale(identifier: "en_AU")

    static func money(_ value: Decimal) -> String {
        value.formatted(.currency(code: "AUD").locale(australia))
    }

    static func signedMoney(_ value: Decimal) -> String {
        value > 0 ? "+" + money(value) : money(value)
    }

    static func duration(minutes: Int) -> String {
        let rest = minutes % 60
        return "\(minutes / 60)h " + (rest < 10 ? "0\(rest)" : "\(rest)") + "m"
    }

    static func hours(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(australia)) + " h"
    }

    static func signedHours(_ value: Decimal) -> String {
        value > 0 ? "+" + hours(value) : hours(value)
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(australia))
    }

    static func shortDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).locale(australia)) + " " + dayMonth(date)
    }

    static func longDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(australia))
    }

    static func dayRange(_ first: Date, _ last: Date) -> String {
        dayMonth(first) + " – " + dayMonth(last) + " " + last.formatted(.dateTime.year().locale(australia))
    }

    static func spokenDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteText = rest == 1 ? "1 minute" : "\(rest) minutes"
        if hours == 0 { return minuteText }
        if rest == 0 { return hourText }
        return hourText + " " + minuteText
    }

    private static func dayMonth(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(australia))
    }
}
