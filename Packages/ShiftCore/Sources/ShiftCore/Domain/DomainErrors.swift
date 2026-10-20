// File: Packages/ShiftCore/Sources/ShiftCore/Domain/DomainErrors.swift
import Foundation

/// Errors related to Job operations.
public enum JobError: LocalizedError, Equatable {
    case emptyName, duplicateName, invalidRate, invalidMultiplier, storageFailed

    // 提供面向用户的英文错误提示，界面直接显示 error.localizedDescription 即可。
    public var errorDescription: String? {
        switch self {
        case .emptyName: "Enter a name for this job."
        case .duplicateName: "You already have a job with this name."
        case .invalidRate: "Enter an hourly rate between $1 and $500."
        case .invalidMultiplier: "Multipliers must be between 1.0 and 3.0."
        case .storageFailed: "Couldn't save your changes. Please try again."
        }
    }
}

/// Errors related to Shift operations.
public enum ShiftError: LocalizedError, Equatable {
    case jobNotFound, invalidLength, breakTooLong, overlaps, storageFailed

    public var errorDescription: String? {
        switch self {
        case .jobNotFound: "Choose a job for this shift."
        case .invalidLength: "A shift must be between 15 minutes and 16 hours long."
        case .breakTooLong: "The unpaid break must be shorter than the shift."
        case .overlaps: "This shift overlaps another shift."
        case .storageFailed: "Couldn't save the shift. Please try again."
        }
    }
}

/// Errors related to clock-in and clock-out operations.
public enum ClockError: LocalizedError, Equatable {
    case shiftNotFound, notToday, otherShiftRunning, alreadyFinished, storageFailed

    public var errorDescription: String? {
        switch self {
        case .shiftNotFound: "This shift no longer exists."
        case .notToday: "You can only clock in on the day of the shift."
        case .otherShiftRunning: "Clock out of your other shift first."
        case .alreadyFinished: "This shift is already done. Long-press it to clear the times."
        case .storageFailed: "Couldn't save the clock time. Please try again."
        }
    }
}

/// Errors related to Payslip operations.
public enum PayslipError: LocalizedError, Equatable {
    case jobNotFound, invalidPeriod, invalidHours, invalidGross, storageFailed

    public var errorDescription: String? {
        switch self {
        case .jobNotFound: "Choose a job for this payslip."
        case .invalidPeriod: "The pay period must end on or after its start and be 31 days or less."
        case .invalidHours: "Enter the hours shown on your payslip (more than 0, up to 200)."
        case .invalidGross: "Enter the gross pay shown on your payslip (more than $0)."
        case .storageFailed: "Couldn't save the payslip. Please try again."
        }
    }
}