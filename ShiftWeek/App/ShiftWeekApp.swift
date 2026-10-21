// File: ShiftWeek/App/ShiftWeekApp.swift
import SwiftData
import SwiftUI

@main
struct ShiftWeekApp: App {
    private let deps: AppDependencies

    init() {
        let usesAppGroup = SharedStore.isAppGroupAvailable
        do {
            let container = try SharedStore.makeContainer()
            deps = AppDependencies(container: container, usesAppGroup: usesAppGroup, storeFailed: false)
        } catch {
            // Keep the app usable for this session even if the saved data can't be opened.
            guard let container = try? SharedStore.makeInMemoryContainer() else {
                fatalError("Could not create the data store.")
            }
            deps = AppDependencies(container: container, usesAppGroup: usesAppGroup, storeFailed: true)
        }
        #if DEBUG
        // Launch with -demoData to start from the sample data.
        if CommandLine.arguments.contains("-demoData") {
            try? DemoData.load(into: deps)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(deps: deps)
        }
    }
}

struct RootTabView: View {
    let deps: AppDependencies
    @State private var showingStorageAlert = false

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView(deps: deps)
            }
            Tab("Week", systemImage: "calendar") {
                WeekView(deps: deps)
            }
            Tab("Pay", systemImage: "dollarsign.circle") {
                PayView(deps: deps)
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(deps: deps)
            }
        }
        .onAppear {
            showingStorageAlert = deps.storeFailed
        }
        .alert("Storage problem", isPresented: $showingStorageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ShiftWeek couldn't open its saved data. Changes made now won't be kept.")
        }
    }
}

#if DEBUG
#Preview {
    RootTabView(deps: .preview())
}
#endif
