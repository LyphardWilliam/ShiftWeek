// File: Packages/ShiftCore/Tests/ShiftCoreTests/MockRepositories.swift
import Foundation
import ShiftCore

// 测试专用的 Mock 错误，用于模拟数据库保存失败。
enum MockError: Error {
    case saveFailed
}

/// An in-memory mock implementation of JobRepository for testing.
final class MockJobRepository: JobRepository {
    var items: [Job] = []
    var failOnSave = false

    // 按名字排序返回所有工作。
    func allJobs() throws -> [Job] {
        items.sorted { $0.name < $1.name }
    }

    // 根据 id 查找工作。
    func job(id: UUID) throws -> Job? {
        items.first { $0.id == id }
    }

    // 保存或更新工作，如果 failOnSave 为 true 则抛出错误。
    func save(_ job: Job) throws {
        if failOnSave { throw MockError.saveFailed }
        items.removeAll { $0.id == job.id }
        items.append(job)
    }

    // 删除工作。
    func delete(id: UUID) throws {
        items.removeAll { $0.id == id }
    }
}

/// An in-memory mock implementation of ShiftRepository for testing.
final class MockShiftRepository: ShiftRepository {
    var items: [Shift] = []
    var failOnSave = false

    // 按时间范围查询班次，返回结果按开始时间排序。
    func shifts(from start: Date, to end: Date) throws -> [Shift] {
        items.filter { $0.start >= start && $0.start < end }.sorted { $0.start < $1.start }
    }

    // 按时间范围和工作 ID 查询班次。
    func shifts(jobID: UUID, from start: Date, to end: Date) throws -> [Shift] {
        try shifts(from: start, to: end).filter { $0.jobID == jobID }
    }

    // 根据 id 查找单个班次。
    func shift(id: UUID) throws -> Shift? {
        items.first { $0.id == id }
    }

    // 查找正在计时的班次（已上班但未下班）。
    func runningShift() throws -> Shift? {
        items.first { $0.clockIn != nil && $0.clockOut == nil }
    }

    // 保存或更新班次。
    func save(_ shift: Shift) throws {
        if failOnSave { throw MockError.saveFailed }
        if let index = items.firstIndex(where: { $0.id == shift.id }) {
            items[index] = shift
        } else {
            items.append(shift)
        }
    }

    // 删除班次。
    func delete(id: UUID) throws {
        items.removeAll { $0.id == id }
    }
}

/// An in-memory mock implementation of PayslipRepository for testing.
final class MockPayslipRepository: PayslipRepository {
    var items: [Payslip] = []
    var failOnSave = false

    // 返回所有工资单，按发薪期结束时间从新到旧排序。
    func allPayslips() throws -> [Payslip] {
        items.sorted { $0.periodEnd > $1.periodEnd }
    }

    // 保存或更新工资单。
    func save(_ payslip: Payslip) throws {
        if failOnSave { throw MockError.saveFailed }
        items.removeAll { $0.id == payslip.id }
        items.append(payslip)
    }

    // 删除工资单。
    func delete(id: UUID) throws {
        items.removeAll { $0.id == id }
    }
}