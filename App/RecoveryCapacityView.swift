import SwiftUI
import LightingCore

/// Keep the unsaved editor untouched while choosing a specific archived record.
/// The store rechecks the complete displayed record inside the write transaction.
struct RecoveryCapacityView: View {
    /// Load the whole validated library so hidden records still disambiguate IDs.
    let onLoad: () async throws -> [LightingProject]
    let onReplace: (LightingProject) throws -> Task<Void, Error>
    @Environment(\.dismiss) private var dismiss
    @State private var candidates: [ProjectLibraryRowPresentation] = []
    @State private var selected: ProjectLibraryRowPresentation?
    @State private var confirmReplacement = false
    @State private var loaded = false
    @State private var loadFailed = false
    @State private var message: String?
    @State private var isLoading = false
    @State private var isReplacing = false
    @State private var loadRequest = UUID()
    @State private var loadTask: Task<Void, Never>?

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
                            .disabled(isLoading || isReplacing)
                    }
                }
                if !loaded || isLoading {
                    ProgressView("Opening archived projects")
                        .accessibilityIdentifier("recoveryCapacityProgress")
                } else if isReplacing {
                    Section {
                        ProgressView("Saving recovery project")
                            .accessibilityIdentifier("recoverySaveProgress")
                        Text("The confirmed replacement finishes before closing. If saving fails, your setup remains in the studio.")
                            .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    }
                } else if candidates.isEmpty && !loadFailed {
                    Section {
                        Text("No archived projects are available")
                            .font(.headline).accessibilityIdentifier("recoveryCapacityEmpty")
                        Text("Your edits remain open in this window. Return to the studio and choose Export, then Editable project copy, to preserve them in a file. No saved project has been removed.")
                            .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                        if message == nil {
                            Button("Refresh archived projects") { reload() }
                                .frame(minHeight: 44)
                        }
                    }
                } else if !candidates.isEmpty {
                    Section {
                        ForEach(candidates) { presentation in
                            Button {
                                // Freeze the displayed identity with the complete
                                // record that the replacement transaction rechecks.
                                selected = presentation
                                confirmReplacement = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(presentation.name).font(.headline)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let identifier = presentation.identifier {
                                        Text("Project ID: \(identifier)")
                                            .font(.caption.monospaced()).foregroundStyle(StudioPalette.secondaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Text("\(presentation.project.scene.lights.count) lights · Archived")
                                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading || isReplacing)
                            .accessibilityLabel("Replace archived \(presentation.name)")
                            .accessibilityValue(presentation.identityValue())
                        }
                    } header: {
                        Text("Choose an archived project").foregroundStyle(StudioPalette.secondaryText)
                    }
                }
            }
            .navigationTitle("Preserve current setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Keep editing") { cancelLoad(); dismiss() }
                        .disabled(isReplacing)
                        .accessibilityIdentifier("cancelRecoveryReplacement")
                }
            }
            .alert("Replace archived project?", isPresented: $confirmReplacement, presenting: selected) { presentation in
                // Keep this a native alert action. A custom accessibility
                // identifier produced nested duplicate Button nodes on the
                // tested iOS simulator; the action already has a clear label.
                Button("Replace and save setup", role: .destructive) { replace(presentation.project) }
                Button("Cancel", role: .cancel) { selected = nil }
            } message: { presentation in
                Text("Save your current setup as a new recovery project? If the library is still full, “\(presentation.confirmationName)” will be removed. That removal cannot be undone here. If space is available, the archived project is kept. Existing exported files are kept.")
            }
            .task { if !loaded { reload() } }
            .onDisappear { cancelLoad() }
            .interactiveDismissDisabled(isReplacing)
        }
        .tint(StudioPalette.action)
    }

    private func reload(preservingMessage: String? = nil) {
        guard !isReplacing else { return }
        cancelLoad()
        selected = nil
        confirmReplacement = false
        let request = UUID()
        loadRequest = request
        isLoading = true
        loadTask = Task { @MainActor in
            defer {
                if loadRequest == request { isLoading = false; loadTask = nil }
            }
            do {
                let latest = try await onLoad()
                guard !Task.isCancelled, request == loadRequest else { return }
                // Compute identities before hiding unarchived projects. The
                // validated library cannot have an archived active project.
                candidates = ProjectLibraryRowPresentation.make(for: latest)
                    .filter { $0.project.isArchived }
                loaded = true
                loadFailed = false
                message = preservingMessage
            } catch {
                guard !Task.isCancelled, request == loadRequest else { return }
                candidates = []
                loaded = true
                loadFailed = true
                message = "Archived projects could not be opened. Your current edits are still in the studio. \(error.localizedDescription)"
            }
        }
    }

    private func cancelLoad() {
        loadRequest = UUID()
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    private func replace(_ project: LightingProject) {
        guard !isReplacing, !isLoading else { return }
        do {
            let task = try onReplace(project) // Parent reservation precedes the observer.
            isReplacing = true
            Task { @MainActor in
                do {
                    try await task.value
                    isReplacing = false
                    dismiss()
                } catch {
                    isReplacing = false
                    selected = nil
                    let failure = "No recovery project was saved. The archived project may have changed; review the current choices before trying again. Your edits remain in the studio. \(error.localizedDescription)"
                    message = failure
                    reload(preservingMessage: failure)
                }
            }
        } catch {
            selected = nil
            message = "No recovery project was saved. The archived project may have changed; review the current choices before trying again. Your edits remain in the studio. \(error.localizedDescription)"
        }
    }
}
