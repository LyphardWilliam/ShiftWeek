// File: ShiftWeek/Features/Settings/JobFormView.swift
import ShiftCore
import SwiftUI

struct JobFormView: View {
    @State private var viewModel: JobFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var typing: Bool

    init(deps: AppDependencies, job: Job? = nil) {
        _viewModel = State(initialValue: JobFormViewModel(deps: deps, job: job))
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
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .focused($typing)
                }

                Section("Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(0..<JobPalette.colors.count, id: \.self) { index in
                            colorButton(index)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    numberField("Hourly rate", prefix: "$", text: $viewModel.rateText, prompt: "28.50")
                    numberField("Saturday ×", text: $viewModel.saturdayText, prompt: "1.0")
                    numberField("Sunday ×", text: $viewModel.sundayText, prompt: "1.0")
                    numberField("Public holiday ×", text: $viewModel.holidayText, prompt: "1.0")
                } header: {
                    Text("Pay")
                } footer: {
                    Text("Use the rates from your contract or award. ShiftWeek doesn't look up award rates for you.")
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Job" : "New Job")
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
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { typing = false }
                }
            }
        }
    }

    private func colorButton(_ index: Int) -> some View {
        let selected = viewModel.colorIndex == index
        return Button {
            viewModel.colorIndex = index
        } label: {
            Circle()
                .fill(JobPalette.color(index))
                .frame(width: 44, height: 44)
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(JobPalette.name(index))
        .accessibilityAddTraits(selected ? .isSelected : [])
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
    JobFormView(deps: .preview())
}
#endif
