// File: ShiftWeek/Features/Week/ShiftFormView.swift
import ShiftCore
import SwiftUI

struct ShiftFormView: View {
    @State private var viewModel: ShiftFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(deps: AppDependencies, shift: Shift? = nil, day: Date = .now) {
        _viewModel = State(initialValue: ShiftFormViewModel(deps: deps, shift: shift, day: day))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let message = viewModel.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Picker("Job", selection: $viewModel.jobID) {
                        ForEach(viewModel.jobs) { job in
                            Text(job.name).tag(Optional(job.id))
                        }
                    }
                    DatePicker("Date", selection: $viewModel.day, displayedComponents: .date)
                    DatePicker("Start", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker("End", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                        if viewModel.endsNextDay {
                            Text("Ends the next day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Stepper("Unpaid break: \(viewModel.breakMinutes) min", value: $viewModel.breakMinutes,
                            in: 0...120, step: 5)
                }

                Section {
                    TextField("Note", text: $viewModel.note, axis: .vertical)
                        .accessibilityLabel("Note")
                }

                Section("Paid time") {
                    Text(Format.duration(minutes: viewModel.paidMinutesPreview))
                        .accessibilityLabel(Format.spokenDuration(minutes: viewModel.paidMinutesPreview))
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Shift" : "New Shift")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() { dismiss() }
                    }
                    .disabled(viewModel.jobs.isEmpty)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ShiftFormView(deps: .preview())
}
#endif
