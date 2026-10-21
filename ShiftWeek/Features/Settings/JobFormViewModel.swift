// File: ShiftWeek/Features/Settings/JobFormViewModel.swift
import Foundation
import ShiftCore

@Observable final class JobFormViewModel {
    let isEditing: Bool
    var name: String
    var colorIndex: Int
    var rateText: String
    var saturdayText: String
    var sundayText: String
    var holidayText: String
    var errorMessage: String?
    private let jobID: UUID
    private let saveJob: SaveJobUseCase

    init(deps: AppDependencies, job: Job? = nil) {
        saveJob = deps.saveJob
        isEditing = job != nil
        jobID = job?.id ?? UUID()
        name = job?.name ?? ""
        colorIndex = job?.colorIndex ?? 0
        rateText = job.map { $0.hourlyRate.formatted(.number.precision(.fractionLength(2)).locale(Format.australia)) }
            ?? ""
        saturdayText = job.map { "\($0.saturdayMultiplier)" } ?? "1.0"
        sundayText = job.map { "\($0.sundayMultiplier)" } ?? "1.0"
        holidayText = job.map { "\($0.holidayMultiplier)" } ?? "1.0"
    }

    /// Returns true when the job was saved and the form can close.
    func save() -> Bool {
        let job = Job(id: jobID, name: name, colorIndex: colorIndex,
                      hourlyRate: number(rateText),
                      saturdayMultiplier: number(saturdayText),
                      sundayMultiplier: number(sundayText),
                      holidayMultiplier: number(holidayText))
        do {
            _ = try saveJob.execute(job)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // Text that isn't a number becomes 0, which the use case then rejects with a clear message.
    private func number(_ text: String) -> Decimal {
        Decimal(string: text.trimmingCharacters(in: .whitespaces), locale: Locale(identifier: "en_AU")) ?? 0
    }
}
