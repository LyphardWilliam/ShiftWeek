// File: ShiftWeek/Features/Pay/PayView.swift
import ShiftCore
import SwiftUI

struct PayView: View {
    private let deps: AppDependencies
    @State private var viewModel: PayViewModel
    @State private var showingNewPayslip = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(deps: AppDependencies) {
        self.deps = deps
        _viewModel = State(initialValue: PayViewModel(deps: deps))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pay")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Payslip", systemImage: "plus") { showingNewPayslip = true }
                            .disabled(!viewModel.hasJobs)
                    }
                }
                .onAppear { viewModel.load() }
                .sheet(isPresented: $showingNewPayslip, onDismiss: viewModel.load) {
                    PayslipFormView(deps: deps)
                }
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
        } else if viewModel.rows.isEmpty {
            ContentUnavailableView("No payslips yet", systemImage: "doc.text",
                                   description: Text("Add a payslip to compare it with your shifts."))
        } else {
            List(viewModel.rows) { row in
                NavigationLink {
                    PayslipDetailView(viewModel: viewModel, payslip: row.payslip)
                } label: {
                    rowLabel(row)
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) { viewModel.delete(row) }
                }
            }
        }
    }

    private func rowLabel(_ row: PayViewModel.Row) -> some View {
        // Large accessibility text puts the result badge under the details instead of beside them.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(JobPalette.color(row.job.colorIndex))
                        .frame(width: 12, height: 12)
                        .accessibilityHidden(true)
                    Text(row.job.name)
                        .font(.headline)
                }
                Text(Format.dayRange(row.payslip.periodStart, row.payslip.periodEnd))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Format.hours(row.payslip.hours)) · \(Format.money(row.payslip.gross))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let verdict = row.verdict {
                HStack(spacing: 4) {
                    Image(systemName: verdict.icon)
                        .foregroundStyle(verdict.color)
                    Text(verdict.shortTitle)
                }
                .font(.subheadline.weight(.semibold))
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(verdict.color.opacity(0.15), in: .capsule)
                .accessibilityLabel("Result: \(verdict.title)")
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .accessibilityElement(children: .combine)
    }

    private var showingError: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

#if DEBUG
#Preview {
    PayView(deps: .preview())
}
#endif
