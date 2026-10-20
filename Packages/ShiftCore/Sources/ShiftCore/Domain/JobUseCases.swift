// File: Packages/ShiftCore/Sources/ShiftCore/Domain/JobUseCases.swift
import Foundation

/// A use case for creating or updating a job with validation.
public struct SaveJobUseCase {
    let jobs: any JobRepository

    // 注入工作仓库的协议，方便测试时替换为 mock。
    public init(jobs: any JobRepository) {
        self.jobs = jobs
    }

    /// Validates and saves a job.
    /// - Throws: `JobError` if validation fails or the repository fails.
    // 校验工作信息（名字非空、不重复、时薪与倍率范围）并保存。
    public func execute(_ job: Job) throws -> Job {
        var job = job
        // 去除名字首尾的空格。
        job.name = job.name.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            // 校验规则：名字不能为空。
            if job.name.isEmpty { throw JobError.emptyName }
            
            // 校验规则：名字不能与已有工作重复（忽略大小写）。
            let others = try jobs.allJobs().filter { $0.id != job.id }
            if others.contains(where: { $0.name.lowercased() == job.name.lowercased() }) {
                throw JobError.duplicateName
            }
            
            // 校验规则：时薪必须在 1 到 500 之间。
            if job.hourlyRate < 1 || job.hourlyRate > 500 { throw JobError.invalidRate }
            
            // 校验规则：倍率必须在 1.0 到 3.0 之间。
            let multipliers = [job.saturdayMultiplier, job.sundayMultiplier, job.holidayMultiplier]
            if multipliers.contains(where: { $0 < 1 || $0 > 3 }) { throw JobError.invalidMultiplier }
            
            // 保存到仓库。
            try jobs.save(job)
            return job
        } catch let error as JobError {
            // 如果是领域错误，原样抛出。
            throw error
        } catch {
            // 仓库抛出的其他错误，统一包装为 storageFailed。
            throw JobError.storageFailed
        }
    }
}

/// A use case for deleting a job.
public struct DeleteJobUseCase {
    let jobs: any JobRepository

    public init(jobs: any JobRepository) {
        self.jobs = jobs
    }

    /// Deletes the job and its associated data.
    public func execute(id: UUID) throws {
        do {
            try jobs.delete(id: id)
        } catch {
            throw JobError.storageFailed
        }
    }
}