// File: ShiftWeek/App/ShiftWeekApp.swift
import SwiftUI

@main
struct ShiftWeekApp: App {
    var body: some Scene {
        WindowGroup {
            let groupID = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? ""
            let hasGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) != nil
            Text(hasGroup ? "ShiftWeek: App Group OK" : "ShiftWeek: App Group not available")
                .padding()
        }
    }
}
