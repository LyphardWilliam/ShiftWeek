// File: ShiftWeek/Features/Pay/PayslipFormView.swift
import ShiftCore
import SwiftUI

struct PayslipFormView: View {
    @State private var viewModel: PayslipFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var typing: Bool

    init(deps: AppDependencies) {
        _viewModel = State(initialValue: PayslipFormViewModel(deps: deps))
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
                    DatePicker("Period start", selection: $viewModel.periodStart, displayedComponents: .date)
                    DatePicker("Period end", selection: $viewModel.periodEnd, displayedComponents: .date)
                }

                Section {
                    numberField("Hours on payslip", text: $viewModel.hoursText, prompt: "0.00")
                    numberField("Gross pay", prefix: "$", text: $viewModel.grossText, prompt: "0.00")
                }
            }
            .navigationTitle("New Payslip")
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { typing = false }
                }
            }
        }
    }

    private func numberField(_ title: String, prefix: String = "", text: Binding<String>,
                             prompt: String) -> some View {
        LabeledContent(title) {
            HStack(spacing: 2) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundStyle(.secondary)
                }
                TextField(title, text: text, prompt: Text(prompt))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($typing)
            }
        }
    }
}

#if DEBUG
#Preview {
    PayslipFormView(deps: .preview())
}
#endif
