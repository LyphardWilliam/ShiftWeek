// File: ShiftWeek/Features/Week/WeekView.swift
import ShiftCore
import SwiftUI

struct WeekView: View {
    private let deps: AppDependencies
    @State private var viewModel: WeekViewModel
    @AppStorage("visaModeOn") private var visaModeOn = false
    @State private var showingNewShift = false
    @State private var editingShift: Shift?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(deps: AppDependencies) {
        self.deps = deps
        _viewModel = State(initialValue: WeekViewModel(deps: deps))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasJobs {
                    weekList
                } else {
                    ContentUnavailableView("No jobs yet", systemImage: "briefcase",
                                           description: Text("Add a job in Settings to start tracking shifts."))
                }
            }
            .navigationTitle("Week")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Previous week", systemImage: "chevron.left") { viewModel.showPreviousWeek() }
                    Button("Next week", systemImage: "chevron.right") { viewModel.showNextWeek() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if !viewModel.isCurrentWeek {
                        Button("This Week") { viewModel.showThisWeek() }
                    }
                    Button("Add Shift", systemImage: "plus") { showingNewShift = true }
                        .disabled(!viewModel.hasJobs)
                }
            }
            .onAppear { viewModel.load() }
            .sheet(isPresented: $showingNewShift, onDismiss: viewModel.load) {
                ShiftFormView(deps: deps, day: viewModel.isCurrentWeek ? .now : viewModel.weekStart)
            }
            .sheet(item: $editingShift, onDismiss: viewModel.load) { shift in
                ShiftFormView(deps: deps, shift: shift)
            }
            .alert("Something went wrong", isPresented: showingError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var weekList: some View {
        List {
            if let summary = viewModel.summary {
                summarySection(summary)
            }
            ForEach(viewModel.days) { day in
                Section(Format.shortDay(day.date)) {
                    if day.items.isEmpty {
                        Text("No shifts")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(day.items) { item in
                        Button { editingShift = item.shift } label: { row(item) }
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { viewModel.delete(item) }
                            }
                    }
                }
            }
        }
    }

    private func summarySection(_ summary: WeekSummary) -> some View {
        let range = Format.dayRange(viewModel.weekStart, viewModel.days.last?.date ?? viewModel.weekStart)
        return Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(range)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Format.duration(minutes: summary.paidMinutes)) · \(Format.money(summary.estimatedPay)) est.")
                    .font(.title3.bold())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(range): \(Format.spokenDuration(minutes: summary.paidMinutes)), "
                                + "\(Format.money(summary.estimatedPay)) estimated")
            if visaModeOn {
                fortnightRow(summary.fortnight)
            }
        } footer: {
            if visaModeOn {
                Text("Student visa work limits can change. Check Home Affairs for the current rules.")
            }
        }
    }

    private func fortnightRow(_ fortnight: FortnightResult) -> some View {
        let lastDay = deps.calendar.date(byAdding: .day, value: 13, to: fortnight.firstWeekStart)!
        return VStack(alignment: .leading, spacing: 4) {
            Text("Busiest fortnight: \(Format.duration(minutes: fortnight.paidMinutes))")
            Text(Format.dayRange(fortnight.firstWeekStart, lastDay))
                .font(.caption)
                .foregroundStyle(.secondary)
            fortnightStatus(fortnight.status)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    // The icon carries the colour; the words stay readable in light and dark mode.
    @ViewBuilder private func fortnightStatus(_ status: FortnightStatus) -> some View {
        switch status {
        case .ok:
            Text("Under 40 h")
                .foregroundStyle(.secondary)
        case .nearLimit:
            Label {
                Text("Getting close to 48 h")
            } icon: {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            }
        case .overLimit:
            Label {
                Text("Over 48 h this fortnight")
            } icon: {
                Image(systemName: "exclamationmark.octagon").foregroundStyle(.red)
            }
        }
    }

    private func row(_ item: ShiftItem) -> some View {
        // Large accessibility text moves the hours and pay onto their own line.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            if !dynamicTypeSize.isAccessibilitySize {
                Circle()
                    .fill(JobPalette.color(item.job.colorIndex))
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.job.name)
                        .font(.headline)
                    if item.shift.clockIn != nil {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Clock times recorded")
                    }
                }
                Text(timeRange(item.shift))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !item.shift.note.isEmpty {
                    Text(item.shift.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(Format.duration(minutes: item.paidMinutes)) · \(Format.money(item.pay))")
                .font(.subheadline)
                .monospacedDigit()
        }
        .foregroundStyle(Color.primary)   // a Button in a List would otherwise tint the text
        .accessibilityElement(children: .combine)
    }

    private func timeRange(_ shift: Shift) -> String {
        let text = "\(Format.time(shift.start)) – \(Format.time(shift.end))"
        return deps.calendar.isDate(shift.end, inSameDayAs: shift.start) ? text : text + " (+1 day)"
    }

    private var showingError: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

#if DEBUG
#Preview {
    WeekView(deps: .preview())
}
#endif
