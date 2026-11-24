import SwiftUI
import LightingCore

/// Keep the unsaved editor untouched while choosing a specific archived record.
/// The store rechecks the complete displayed record inside the write transaction.
struct RecoveryCapacityView: View {
    let onLoad: () throws -> [LightingProject]
    let onReplace: (LightingProject) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var candidates: [LightingProject] = []
    @State private var selected: LightingProject?
    @State private var confirmReplacement = false
    @State private var loaded = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("The library was full when saving", systemImage: "externaldrive.badge.exclamationmark")
                        .font(.headline)
                    Text("Choose an archived project that may be replaced with your current unsaved setup. Space is checked again before saving. If a slot has opened, no project is removed. Nothing changes until you confirm.")
                        .font(.subheadline)
                }
                if let message {
                    Section {
                        Text(message).accessibilityIdentifier("recoveryCapacityMessage")
                        Button("Refresh archived projects") { reload() }
                            .frame(minHeight: 44)
                    }
                }
                if !loaded {
                    ProgressView("Opening archived projects")
                } else if candidates.isEmpty {
                    Section {
                        Text("No archived projects are available")
                            .font(.headline).accessibilityIdentifier("recoveryCapacityEmpty")
                        Text("Your edits remain open in this window. Return to the studio and choose Export, then Editable project copy, to preserve them in a file. No saved project has been removed.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } else {
                    Section("Choose an archived project") {
                        ForEach(candidates) { project in
                            Button {
                                selected = project
                                confirmReplacement = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayName(project)).font(.headline)
                                    if displayName(project) != project.name {
                                        Text("Project ID: \(project.id.uuidString.prefix(8))")
                                            .font(.caption.monospaced()).foregroundStyle(.secondary)
                                    }
                                    Text("\(project.scene.lights.count) lights · Archived")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Replace archived \(displayName(project))")
                            .accessibilityValue(displayName(project) == project.name ? "" : "Project ID \(project.id.uuidString.prefix(8))")
                        }
                    }
                }
            }
            .navigationTitle("Preserve current setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Keep editing") { dismiss() }
                        .accessibilityIdentifier("cancelRecoveryReplacement")
                }
            }
            .alert("Replace archived project?", isPresented: $confirmReplacement, presenting: selected) { project in
                Button("Replace and save setup", role: .destructive) { replace(project) }
                    .accessibilityIdentifier("confirmRecoveryReplacement")
                Button("Cancel", role: .cancel) { selected = nil }
            } message: { project in
                Text("Save your current setup as a new recovery project? If the library is still full, “\(confirmationName(project))” will be removed. That removal cannot be undone here. If space is available, the archived project is kept. Existing exported files are kept.")
            }
            .task { if !loaded { reload() } }
        }
    }

    private func reload() {
        do {
            candidates = try onLoad()
            loaded = true
            message = nil
        } catch {
            candidates = []
            loaded = true
            message = "Archived projects could not be opened. Your current edits are still in the studio. \(error.localizedDescription)"
        }
    }

    private func displayName(_ project: LightingProject) -> String {
        let name = StudioDisplayName.display(project.name)
        return name.isEmpty ? "Unnamed project" : name
    }

    private func confirmationName(_ project: LightingProject) -> String {
        displayName(project) + (displayName(project) == project.name ? "" : " (ID \(project.id.uuidString.prefix(8)))")
    }

    private func replace(_ project: LightingProject) {
        do {
            try onReplace(project)
            dismiss()
        } catch {
            selected = nil
            reload()
            message = "No recovery project was saved. The archived project may have changed; review the current choices before trying again. Your edits remain in the studio. \(error.localizedDescription)"
        }
    }
}
