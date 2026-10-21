// File: Shared/SharedStore.swift
import Foundation
import SwiftData

/// Builds the SwiftData container that the app and the widget both read.
enum SharedStore {
    static var schema: Schema {
        Schema([JobRecord.self, ShiftRecord.self, PayslipRecord.self])
    }

    /// The App Group from Info.plist, or nil when the build setting was not filled in.
    static var appGroupID: String? {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String,
              !id.isEmpty, !id.contains("$(") else { return nil }
        return id
    }

    static var isAppGroupAvailable: Bool {
        guard let id = appGroupID else { return false }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil
    }

    static func makeContainer() throws -> ModelContainer {
        let configuration: ModelConfiguration
        if isAppGroupAvailable, let id = appGroupID {
            configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(id))
        } else {
            // .none keeps the store in the app's own folder (.automatic would look for a group).
            configuration = ModelConfiguration(schema: schema, groupContainer: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
