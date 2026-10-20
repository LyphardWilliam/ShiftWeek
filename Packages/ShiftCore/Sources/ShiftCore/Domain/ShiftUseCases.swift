// File: Packages/ShiftCore/Sources/ShiftCore/Domain/ShiftUseCases.swift
import Foundation

/// A use case for creating or updating a shift with validation.
public struct SaveShiftUseCase {
    let jobs: any JobRepository
    let shifts: any ShiftRepository

    public init(jobs: any JobRepository, shifts: any ShiftRepository) {
        self.jobs = jobs
        self.shifts = shifts
    }

    /// Validates and saves a shift.
    /// - Throws: `ShiftError` if validation fails or the repository fails.
    // 校验班次信息（工作是否存在、时长、休息时间、是否重叠）并保存。
    public func execute(_ shift: Shift) throws -> Shift {
        var shift = shift
        // 去除备注首尾的空格。
        shift.note = shift.note.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            // 校验规则：关联的工作必须存在。
            guard try jobs.job(id: shift.jobID) != nil else { throw ShiftError.jobNotFound }

            // 校验规则：班次时长必须在 15 分钟到 16 小时之间。
            let length = shift.end.timeIntervalSince(shift.start)
            if length < 15 * 60 || length > 16 * 3600 { throw ShiftError.invalidLength }
            
            // 校验规则：无薪休息不能为负，且必须小于总时长。
            if shift.unpaidBreakMinutes < 0 || shift.unpaidBreakMinutes >= Int(length / 60) {
                throw ShiftError.breakTooLong
            }

            // 校验规则：不能和已有的其他班次时间重叠。
            // 一个班次最长 16 小时，所以从 start - 16h 开始找就不会漏。
            let nearby = try shifts.shifts(from: shift.start.addingTimeInterval(-16 * 3600), to: shift.end)
            if nearby.contains(where: { $0.id != shift.id && $0.start < shift.end && $0.end > shift.start }) {
                throw ShiftError.overlaps
            }

            try shifts.save(shift)
            return shift
        } catch let error as ShiftError {
            throw error
        } catch {
            throw ShiftError.storageFailed
        }
    }
}

/// A use case for deleting a shift.
public struct DeleteShiftUseCase {
    let shifts: any ShiftRepository

    public init(shifts: any ShiftRepository) {
        self.shifts = shifts
    }

    public func execute(id: UUID) throws {
        do {
            try shifts.delete(id: id)
        } catch {
            throw ShiftError.storageFailed
        }
    }
}

/// A use case for clocking in and out of a shift.
public struct ClockShiftUseCase {
    let shifts: any ShiftRepository
    let calendar: Calendar

    public init(shifts: any ShiftRepository, calendar: Calendar) {
        self.shifts = shifts
        self.calendar = calendar
    }

    /// First tap clocks in, second tap clocks out.
    /// - Throws: `ClockError` if validation fails or the repository fails.
    // 切换打卡状态：第一次点打卡上班，第二次点打卡下班。
    public func toggle(shiftID: UUID, now: Date) throws -> Shift {
        do {
            guard var shift = try shifts.shift(id: shiftID) else { throw ClockError.shiftNotFound }
            switch shift.clockState {
            case .notStarted:
                // 校验规则：只能在班次排班的那一天打卡。
                guard calendar.isDate(shift.start, inSameDayAs: now) else { throw ClockError.notToday }
                
                // 校验规则：不能有其他班次正在运行。
                if let running = try shifts.runningShift(), running.id != shift.id {
                    throw ClockError.otherShiftRunning
                }
                shift.clockIn = now
                
            case .working(let since):
                // 下班打卡时间不能早于上班打卡时间。
                shift.clockOut = max(now, since)
                
            case .done:
                // 校验规则：已经打完卡的班次不能再点。
                throw ClockError.alreadyFinished
            }
            try shifts.save(shift)
            return shift
        } catch let error as ClockError {
            throw error
        } catch {
            throw ClockError.storageFailed
        }
    }

    /// Clears the clock times for a shift, resetting it to not started.
    // 清除打卡记录，恢复到未开始状态（供长按菜单使用）。
    public func clear(shiftID: UUID) throws -> Shift {
        do {
            guard var shift = try shifts.shift(id: shiftID) else { throw ClockError.shiftNotFound }
            shift.clockIn = nil
            shift.clockOut = nil
            try shifts.save(shift)
            return shift
        } catch let error as ClockError {
            throw error
        } catch {
            throw ClockError.storageFailed
        }
    }
}