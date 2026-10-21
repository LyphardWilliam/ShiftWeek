// File: ShiftWeek/Data/SwiftDataRepositories.swift
import Foundation
import ShiftCore
import SwiftData
import WidgetKit

// MARK: - Record to domain mapping

extension JobRecord {
    func toDomain() -> Job {
        Job(id: id, name: name, colorIndex: colorIndex, hourlyRate: hourlyRate,
            saturdayMultiplier: saturdayMultiplier, sundayMultiplier: sundayMultiplier,
            holidayMultiplier: holidayMultiplier)
    }
}

extension ShiftRecord {
    func toDomain() -> Shift? {
        guard let job else { return nil }
        return Shift(id: id, jobID: job.id, start: start, end: end, unpaidBreakMinutes: unpaidBreakMinutes,
                     note: note, clockIn: clockIn, clockOut: clockOut)
    }
}

extension PayslipRecord {
    func toDomain() -> Payslip? {
        guard let job else { return nil }
        return Payslip(id: id, jobID: job.id, periodStart: periodStart, periodEnd: periodEnd,
                       hours: hours, gross: gross)
    }
}

// MARK: - Helpers

private func fetchJobRecord(id: UUID, in context: ModelContext) throws -> JobRecord? {
    var descriptor = FetchDescriptor<JobRecord>(predicate: #Predicate { $0.id == id })
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first
}

/// Every write ends here so the Home Screen widget picks up the change.
private func saveAndReloadWidget(_ context: ModelContext) throws {
    try context.save()
    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: - Repositories

final class SwiftDataJobRepository: JobRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allJobs() throws -> [Job] {
        let descriptor = FetchDescriptor<JobRecord>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func job(id: UUID) throws -> Job? {
        try fetchJobRecord(id: id, in: context)?.toDomain()
    }

    func save(_ job: Job) throws {
        let record: JobRecord
        if let existing = try fetchJobRecord(id: job.id, in: context) {
            record = existing
        } else {
            record = JobRecord(id: job.id, name: job.name, hourlyRate: job.hourlyRate)
            context.insert(record)
        }
        record.name = job.name
        record.colorIndex = job.colorIndex
        record.hourlyRate = job.hourlyRate
        record.saturdayMultiplier = job.saturdayMultiplier
        record.sundayMultiplier = job.sundayMultiplier
        record.holidayMultiplier = job.holidayMultiplier
        try saveAndReloadWidget(context)
    }

    func delete(id: UUID) throws {
        guard let record = try fetchJobRecord(id: id, in: context) else { return }
        context.delete(record)   // cascade rule removes its shifts and payslips
        try saveAndReloadWidget(context)
    }
}

final class SwiftDataShiftRepository: ShiftRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func shifts(from start: Date, to end: Date) throws -> [Shift] {
        let descriptor = FetchDescriptor<ShiftRecord>(
            predicate: #Predicate { $0.start >= start && $0.start < end },
            sortBy: [SortDescriptor(\.start)])
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func shifts(jobID: UUID, from start: Date, to end: Date) throws -> [Shift] {
        let descriptor = FetchDescriptor<ShiftRecord>(
            predicate: #Predicate { $0.job?.id == jobID && $0.start >= start && $0.start < end },
            sortBy: [SortDescriptor(\.start)])
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func shift(id: UUID) throws -> Shift? {
        try fetchRecord(id: id)?.toDomain()
    }

    func runningShift() throws -> Shift? {
        var descriptor = FetchDescriptor<ShiftRecord>(
            predicate: #Predicate { $0.clockIn != nil && $0.clockOut == nil },
            sortBy: [SortDescriptor(\.start)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toDomain()
    }

    func save(_ shift: Shift) throws {
        guard let job = try fetchJobRecord(id: shift.jobID, in: context) else {
            throw RepositoryError.jobNotFound
        }
        let record: ShiftRecord
        if let existing = try fetchRecord(id: shift.id) {
            record = existing
        } else {
            record = ShiftRecord(id: shift.id, start: shift.start, end: shift.end)
            context.insert(record)
        }
        record.job = job
        record.start = shift.start
        record.end = shift.end
        record.unpaidBreakMinutes = shift.unpaidBreakMinutes
        record.note = shift.note
        record.clockIn = shift.clockIn
        record.clockOut = shift.clockOut
        try saveAndReloadWidget(context)
    }

    func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { return }
        context.delete(record)
        try saveAndReloadWidget(context)
    }

    private func fetchRecord(id: UUID) throws -> ShiftRecord? {
        var descriptor = FetchDescriptor<ShiftRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

final class SwiftDataPayslipRepository: PayslipRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allPayslips() throws -> [Payslip] {
        let descriptor = FetchDescriptor<PayslipRecord>(sortBy: [SortDescriptor(\.periodEnd, order: .reverse)])
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func save(_ payslip: Payslip) throws {
        guard let job = try fetchJobRecord(id: payslip.jobID, in: context) else {
            throw RepositoryError.jobNotFound
        }
        let record: PayslipRecord
        if let existing = try fetchRecord(id: payslip.id) {
            record = existing
        } else {
            record = PayslipRecord(id: payslip.id, periodStart: payslip.periodStart, periodEnd: payslip.periodEnd,
                                   hours: payslip.hours, gross: payslip.gross)
            context.insert(record)
        }
        record.job = job
        record.periodStart = payslip.periodStart
        record.periodEnd = payslip.periodEnd
        record.hours = payslip.hours
        record.gross = payslip.gross
        try saveAndReloadWidget(context)
    }

    func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { return }
        context.delete(record)
        try saveAndReloadWidget(context)
    }

    private func fetchRecord(id: UUID) throws -> PayslipRecord? {
        var descriptor = FetchDescriptor<PayslipRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
