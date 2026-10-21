// File: Shared/Records.swift
import Foundation
import SwiftData

@Model
final class JobRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorIndex: Int
    var hourlyRate: Decimal
    var saturdayMultiplier: Decimal
    var sundayMultiplier: Decimal
    var holidayMultiplier: Decimal
    @Relationship(deleteRule: .cascade, inverse: \ShiftRecord.job) var shifts: [ShiftRecord] = []
    @Relationship(deleteRule: .cascade, inverse: \PayslipRecord.job) var payslips: [PayslipRecord] = []

    init(id: UUID, name: String, colorIndex: Int = 0, hourlyRate: Decimal,
         saturdayMultiplier: Decimal = 1, sundayMultiplier: Decimal = 1, holidayMultiplier: Decimal = 1) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.hourlyRate = hourlyRate
        self.saturdayMultiplier = saturdayMultiplier
        self.sundayMultiplier = sundayMultiplier
        self.holidayMultiplier = holidayMultiplier
    }
}

@Model
final class ShiftRecord {
    @Attribute(.unique) var id: UUID
    var start: Date
    var end: Date
    var unpaidBreakMinutes: Int
    var note: String
    var clockIn: Date?
    var clockOut: Date?
    var job: JobRecord?

    init(id: UUID, job: JobRecord? = nil, start: Date, end: Date, unpaidBreakMinutes: Int = 0,
         note: String = "", clockIn: Date? = nil, clockOut: Date? = nil) {
        self.id = id
        self.job = job
        self.start = start
        self.end = end
        self.unpaidBreakMinutes = unpaidBreakMinutes
        self.note = note
        self.clockIn = clockIn
        self.clockOut = clockOut
    }
}

@Model
final class PayslipRecord {
    @Attribute(.unique) var id: UUID
    var periodStart: Date
    var periodEnd: Date
    var hours: Decimal
    var gross: Decimal
    var job: JobRecord?

    init(id: UUID, job: JobRecord? = nil, periodStart: Date, periodEnd: Date, hours: Decimal, gross: Decimal) {
        self.id = id
        self.job = job
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.hours = hours
        self.gross = gross
    }
}
