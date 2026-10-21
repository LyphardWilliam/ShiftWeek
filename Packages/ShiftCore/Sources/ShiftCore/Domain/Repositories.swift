// File: Packages/ShiftCore/Sources/ShiftCore/Domain/Repositories.swift
import Foundation

/// Represents errors that can occur during repository operations.
public enum RepositoryError: Error {
    case jobNotFound
}

/// A protocol defining data access operations for Jobs.
public protocol JobRepository {
    func allJobs() throws -> [Job]                       // 按名字排序
    func job(id: UUID) throws -> Job?
    func save(_ job: Job) throws                         // 根据 id 插入或更新
    func delete(id: UUID) throws                         // 级联删除该工作下的所有班次和工资单
}

/// A protocol defining data access operations for Shifts.
public protocol ShiftRepository {
    // 查询条件：start <= shift.start < end，按开始时间排序
    func shifts(from start: Date, to end: Date) throws -> [Shift]
    // 同上，但限定特定工作
    func shifts(jobID: UUID, from start: Date, to end: Date) throws -> [Shift]
    func shift(id: UUID) throws -> Shift?
    // 查询已上班但未下班的班次（用于确保同一时间只有一个班在打卡）
    func runningShift() throws -> Shift?
    // 如果关联的工作已被删除，抛出 RepositoryError.jobNotFound
    func save(_ shift: Shift) throws
    func delete(id: UUID) throws
}

/// A protocol defining data access operations for Payslips.
public protocol PayslipRepository {
    func allPayslips() throws -> [Payslip]               // 按发薪期从新到旧排序
    func save(_ payslip: Payslip) throws
    func delete(id: UUID) throws
}