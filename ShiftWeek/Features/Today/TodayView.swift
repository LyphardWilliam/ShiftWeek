// File: ShiftWeek/Features/Today/TodayView.swift
import ShiftCore
import SwiftUI

struct TodayView: View {
    private let deps: AppDependencies
    @State private var viewModel: TodayViewModel
    @State private var showingNewShift = false
    @State private var editingShift: Shift?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(deps: AppDependencies) {
        self.deps = deps
        _viewModel = State(initialValue: TodayViewModel(deps: deps))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today")
                .navigationSubtitle(dynamicTypeSize.isAccessibilitySize ? "" : Format.longDay(.now))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Shift", systemImage: "plus") { showingNewShift = true }
                            .disabled(!viewModel.hasJobs)
                    }
                }
                .onAppear { viewModel.load() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { viewModel.load() }
                }
                .sheet(isPresented: $showingNewShift, onDismiss: { viewModel.load() }) {
                    ShiftFormView(deps: deps, day: .now)
                }
                .sheet(item: $editingShift, onDismiss: { viewModel.load() }) { shift in
                    ShiftFormView(deps: deps, shift: shift)
                }
                .sensoryFeedback(.success, trigger: viewModel.clockChanges)
                .alert("Something went wrong", isPresented: showingError) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    @ViewBuilder private var content: some View {
        if !viewModel.hasJobs {
            ContentUnavailableView("No jobs yet", systemImage: "briefcase",
                                   description: Text("Add a job in Settings to start tracking shifts."))
        } else if viewModel.items.isEmpty {
            ContentUnavailableView("No shifts today", systemImage: "sun.max",
                                   description: Text("Tap + to add one, or plan your week in the Week tab."))
        } else {
            ScrollView {
                if dynamicTypeSize.isAccessibilitySize {
                    Text(Format.longDay(.now))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)
                }
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.items) { item in
                        card(item)
                    }
                }
                .padding()
            }
        }
    }

    // Big accessibility text sizes get one full-width card per row instead of circles.
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [GridItem(.adaptive(minimum: 150), spacing: 16)]
    }

    private func card(_ item: ShiftItem) -> some View {
        ShiftCard(item: item, large: dynamicTypeSize.isAccessibilitySize) {
            viewModel.tap(item)
        }
        // Long-press lifts just the card's shape instead of a grey square behind the circle.
        .contentShape(.contextMenuPreview, dynamicTypeSize.isAccessibilitySize
                      ? AnyShape(RoundedRectangle(cornerRadius: 24)) : AnyShape(Circle()))
        .contextMenu {
            Button("Edit Shift", systemImage: "pencil") { editingShift = item.shift }
            if item.shift.clockIn != nil {
                Button("Clear Clock Times", systemImage: "arrow.counterclockwise", role: .destructive) {
                    viewModel.clearClock(item)
                }
            }
        }
        .accessibilityActions {
            Button("Edit Shift") { editingShift = item.shift }
            if item.shift.clockIn != nil {
                Button("Clear Clock Times") { viewModel.clearClock(item) }
            }
        }
    }

    private var showingError: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

private struct ShiftCard: View {
    let item: ShiftItem
    let large: Bool
    let action: () -> Void

    private var tint: Color { JobPalette.color(item.job.colorIndex) }
    private var isWorking: Bool { item.shift.clockIn != nil && item.shift.clockOut == nil }

    var body: some View {
        Button(action: action) {
            if large {
                styled(RoundedRectangle(cornerRadius: 24))
            } else {
                styled(Circle())
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.job.name), \(Format.time(item.shift.start)) to \(Format.time(item.shift.end))")
        .accessibilityValue(spokenStatus)
        .accessibilityHint(hint)
    }

    private func styled(_ shape: some InsettableShape) -> some View {
        details
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(tint.opacity(0.18)))
            .overlay(shape.strokeBorder(tint, lineWidth: isWorking ? 6 : 3))
            .contentShape(shape)
    }

    private var details: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            Text(item.job.name)
                .font(.headline)
                .lineLimit(large ? nil : 2)
            Text("\(Format.time(item.shift.start)) – \(Format.time(item.shift.end))")
                .font(.caption)
                .foregroundStyle(.secondary)
            status
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.primary)
    }

    @ViewBuilder private var status: some View {
        switch item.shift.clockState {
        case .notStarted: Text("Not started")
        case .working(let since): Text(since, style: .timer)
        case .done(let minutes): Text("Done · \(Format.duration(minutes: minutes))")
        }
    }

    private var icon: String {
        switch item.shift.clockState {
        case .notStarted: "play.circle"
        case .working: "timer"
        case .done: "checkmark.circle.fill"
        }
    }

    private var spokenStatus: String {
        switch item.shift.clockState {
        case .notStarted: "Not started"
        case .working: "Working"
        case .done(let minutes): "Done, \(Format.spokenDuration(minutes: minutes))"
        }
    }

    private var hint: String {
        switch item.shift.clockState {
        case .notStarted: "Double-tap to clock in."
        case .working: "Double-tap to clock out."
        case .done: ""
        }
    }
}

#if DEBUG
#Preview {
    TodayView(deps: .preview())
}
#endif
