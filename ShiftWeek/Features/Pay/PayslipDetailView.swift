// File: ShiftWeek/Features/Pay/PayslipDetailView.swift
import ShiftCore
import SwiftUI

struct PayslipDetailView: View {
    let viewModel: PayViewModel
    let payslip: Payslip
    @State private var check: PayslipCheck?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            if let check {
                verdictSection(check.comparison.verdict)
                comparisonSection(check.comparison)
                shiftsSection(check.items)
            }
            Section {
                Link("Fair Work Pay Calculator", destination: URL(string: "https://calculate.fairwork.gov.au/")!)
            } footer: {
                Text("Estimates use your own records and the rates you entered. This is not legal or financial advice.")
            }
        }
        .navigationTitle(check?.job.name ?? "Payslip")
        .navigationSubtitle(Format.dayRange(payslip.periodStart, payslip.periodEnd))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { check = viewModel.check(for: payslip) }
    }

    private func verdictSection(_ verdict: PayslipVerdict) -> some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: verdict.icon)
                    .font(.largeTitle)
                    .foregroundStyle(verdict.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verdict.title)
                        .font(.title2.bold())
                    Text(verdict.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Result: \(verdict.title)")
            .accessibilityValue(verdict.message)
        }
    }

    private struct Line: Identifiable {
        let name: String
        let recorded: String
        let payslip: String
        let difference: String
        var id: String { name }
        var spoken: String { "\(name): your records \(recorded), payslip \(payslip), difference \(difference)" }
    }

    private func comparisonSection(_ comparison: PayslipComparison) -> some View {
        let lines = [
            Line(name: "Hours", recorded: Format.hours(comparison.recordedHours),
                 payslip: Format.hours(comparison.payslipHours),
                 difference: Format.signedHours(comparison.hoursDifference)),
            Line(name: "Gross pay", recorded: Format.money(comparison.recordedPay),
                 payslip: Format.money(comparison.payslipGross),
                 difference: Format.signedMoney(comparison.payDifference)),
        ]
        return Section("Comparison") {
            if dynamicTypeSize.isAccessibilitySize {
                // Not enough room for columns, so each value gets its own line.
                ForEach(lines) { line in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.name).font(.headline)
                        Text("Your records: \(line.recorded)")
                        Text("Payslip: \(line.payslip)")
                        Text("Difference: \(line.difference)")
                    }
                    .accessibilityElement(children: .combine)
                }
            } else {
                Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("")
                        header("Your records")
                        header("Payslip")
                        header("Difference")
                    }
                    ForEach(lines) { line in
                        GridRow {
                            Text(line.name)
                                .gridColumnAlignment(.leading)
                            Text(line.recorded)
                            Text(line.payslip)
                            Text(line.difference)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .font(.subheadline)
                .monospacedDigit()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(lines.map(\.spoken).joined(separator: ". "))
            }
        }
    }

    private func header(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func shiftsSection(_ items: [ShiftItem]) -> some View {
        Section("Shifts in this period") {
            if items.isEmpty {
                Text("No shifts recorded for this job in this period.")
                    .foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                Text("\(Format.shortDay(item.shift.start)) · \(Format.time(item.shift.start)) – "
                     + "\(Format.time(item.shift.end)) · \(Format.duration(minutes: item.paidMinutes)) · "
                     + "\(Format.money(item.pay))")
                    .font(.subheadline)
            }
        }
    }
}

extension PayslipVerdict {
    var title: String {
        switch self {
        case .match: "Match"
        case .close: "Close"
        case .checkWithEmployer: "Check with employer"
        }
    }

    var shortTitle: String {
        self == .checkWithEmployer ? "Check" : title
    }

    var message: String {
        switch self {
        case .match: "Your records and this payslip agree."
        case .close: "There's a small difference. Worth a quick look."
        case .checkWithEmployer: "The hours or pay don't line up with your records."
        }
    }

    var icon: String {
        switch self {
        case .match: "checkmark.seal.fill"
        case .close: "exclamationmark.circle.fill"
        case .checkWithEmployer: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .match: .green
        case .close: .orange
        case .checkWithEmployer: .red
        }
    }
}
