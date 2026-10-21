// File: ShiftWeek/Features/Settings/SettingsViewModel.swift
import Foundation
import ShiftCore

@Observable final class SettingsViewModel {
    private(set) var jobs: [Job] = []
    var errorMessage: String?
    let usesAppGroup: Bool
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
        usesAppGroup = deps.usesAppGroup
    }

    func load() {
        do {
            jobs = try deps.jobs.allJobs()
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    func delete(_ job: Job) {
        do {
            try deps.deleteJob.execute(id: job.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        load()
    }

    #if DEBUG
    func loadDemoData() {
        do {
            try DemoData.load(into: deps, now: .now)
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        load()
    }
    #endif
}
