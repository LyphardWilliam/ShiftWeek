// File: ShiftWeek/Features/Settings/SettingsView.swift
import ShiftCore
import SwiftUI

struct SettingsView: View {
    private let deps: AppDependencies
    @State private var viewModel: SettingsViewModel
    @AppStorage("visaModeOn") private var visaModeOn = false
    @State private var showingNewJob = false
    @State private var editingJob: Job?
    @State private var jobToDelete: Job?
    @State private var showingDeleteConfirm = false
    @State private var showingDemoAlert = false

    init(deps: AppDependencies) {
        self.deps = deps
        _viewModel = State(initialValue: SettingsViewModel(deps: deps))
    }

    var body: some View {
        NavigationStack {
            Form {
                jobsSection

                Section {
                    Toggle("Student visa mode", isOn: $visaModeOn)
                } header: {
                    Text("Student visa")
                } footer: {
                    Text("Shows the hours of your busiest fortnight on the Week tab. Work limits can change. Check Home Affairs for the current rules.")
                }

                aboutSection

                #if DEBUG
                Section("Demo") {
                    Button("Load Demo Data") { showingDemoAlert = true }
                }
                #endif
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.load() }
            .sheet(isPresented: $showingNewJob, onDismiss: viewModel.load) {
                JobFormView(deps: deps)
            }
            .sheet(item: $editingJob, onDismiss: viewModel.load) { job in
                JobFormView(deps: deps, job: job)
            }
            .confirmationDialog("Delete \(jobToDelete?.name ?? "job")?", isPresented: $showingDeleteConfirm,
                                titleVisibility: .visible, presenting: jobToDelete) { job in
                Button("Delete Job", role: .destructive) { viewModel.delete(job) }
            } message: { _ in
                Text("Its shifts and payslips will also be deleted.")
            }
            #if DEBUG
            .alert("Replace all data?", isPresented: $showingDemoAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Load", role: .destructive) { viewModel.loadDemoData() }
            } message: {
                Text("This deletes your jobs, shifts and payslips and loads sample data.")
            }
            #endif
            .alert("Something went wrong", isPresented: showingError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var jobsSection: some View {
        Section("Jobs") {
            if viewModel.jobs.isEmpty {
                Text("Add your first job to get started.")
                    .foregroundStyle(.secondary)
            }
            ForEach(viewModel.jobs) { job in
                Button {
                    editingJob = job
                } label: {
                    HStack {
                        Circle()
                            .fill(JobPalette.color(job.colorIndex))
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)
                        Text(job.name)
                        Spacer()
                        Text("\(Format.money(job.hourlyRate))/h")
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(Color.primary)   // a Button in a List would otherwise tint the text
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash") {
                        jobToDelete = job
                        showingDeleteConfirm = true
                    }
                    .tint(.red)
                }
            }
            Button("Add Job", systemImage: "plus") { showingNewJob = true }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: versionText)
            LabeledContent("Home Screen widget", value: viewModel.usesAppGroup ? "On" : "Off")
            Text("All data stays on this iPhone. No account, no tracking.")
            Link("Fair Work Pay Calculator", destination: URL(string: "https://calculate.fairwork.gov.au/")!)
        } header: {
            Text("About")
        } footer: {
            Text("Estimates use your own records and the rates you entered. This is not legal or financial advice.")
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var showingError: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

#if DEBUG
#Preview {
    SettingsView(deps: .preview())
}
#endif
