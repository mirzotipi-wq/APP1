import Foundation
import LightingCore
import SwiftUI

/// Inspection is read-only. The parent must reserve recovery synchronously and
/// keep its task alive until the committed result has been adopted by the session.
/// This sheet only observes that task; closing it never cancels a confirmed write.
/// Keep presentation independent of workspace resets so success remains until Done.
@MainActor
struct ProjectLibraryRecoveryView: View {
    let onInspect: () async throws -> ProjectLibraryRecoverySnapshot
    let onRecover: (ProjectLibraryRecoverySnapshot) throws -> Task<Void, Error>

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .notInspected
    @State private var inspectionRequest = UUID()
    @State private var inspectionTask: Task<Void, Never>?
    @State private var confirmation: Inspection?
    @State private var showConfirmation = false

    private struct Inspection {
        let id: UUID
        let snapshot: ProjectLibraryRecoverySnapshot
    }

    private enum Phase {
        case notInspected
        case inspecting
        case ready(Inspection)
        case recovering
        case failed(title: String, message: String)
        case completed
    }

    private var isRecovering: Bool {
        if case .recovering = phase { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                if case .completed = phase {
                    completedSection
                } else {
                    explanationSection
                    statusSection
                }
            }
            .navigationTitle("Recover saved library")
            .navigationBarTitleDisplayMode(.inline)
            // Match the project library's measured full-size close target.
            // A navigation toolbar can constrain an inner 44-point frame.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    guard !isRecovering else { return }
                    cancelInspection()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(StudioPalette.action)
                .disabled(isRecovering)
                .accessibilityIdentifier("closeLibraryRecovery")
                .padding(.horizontal, 16)
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .alert("Keep files and start again?", isPresented: $showConfirmation, presenting: confirmation) { inspection in
                // Native alert actions have clear labels and system target sizes.
                Button("Keep files and start again") { recover(inspection) }
                Button("Cancel", role: .cancel) { confirmation = nil }
            } message: { _ in
                Text("Keep copies of the original saved files on this device and create a new library? Existing projects will not appear in the new library. You can import an editable backup from Projects afterward. If the saved files changed, recovery will stop for another check.")
            }
            .task {
                if case .notInspected = phase { inspect() }
            }
            .onDisappear { cancelInspection() }
            // Every outcome stays available for review until the user taps Done.
            .interactiveDismissDisabled(true)
        }
        .tint(StudioPalette.action)
    }

    private var explanationSection: some View {
        Section {
            Label("Saved library could not be opened", systemImage: "externaldrive.badge.exclamationmark")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("The saved library could not be opened by this app version. Its files may be damaged or may have been created by a newer version.")
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("libraryRecoveryExplanation")
            Text("If an app update is available, try it first. You can also tap Done and choose Retry loading saved project in the studio.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Starting again keeps copies of the original saved files on this device before creating a new library. Your existing projects remain unavailable here unless their files can be opened or you import an editable backup.")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch phase {
        case .notInspected:
            Section {
                Text("Check the saved files before deciding whether to start again. Checking does not change them.")
                    .fixedSize(horizontal: false, vertical: true)
                inspectButton("Check saved files")
            }
        case .inspecting:
            Section {
                ProgressView("Checking saved files")
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("libraryRecoveryInspectionProgress")
                Text("No files are changed during this check.")
                    .font(.subheadline)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case let .ready(inspection):
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved files to keep: \(inspection.snapshot.fileCount)")
                    Text("Total size: \(ByteCountFormatter.string(fromByteCount: Int64(inspection.snapshot.byteCount), countStyle: .file))")
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("libraryRecoveryInspectionSummary")
                Text("These files will be checked again when you confirm. Keeping them does not repair them or restore your previous projects.")
                    .font(.subheadline)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    guard case let .ready(current) = phase, current.id == inspection.id else { return }
                    confirmation = inspection
                    showConfirmation = true
                } label: {
                    Text("Review starting again")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(StudioPalette.prominentActionText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens a confirmation. The saved library changes only after you confirm.")
                .accessibilityIdentifier("reviewLibraryRecovery")
                inspectButton("Check saved files again")
            } header: {
                Text("Review the saved files")
            }
        case .recovering:
            Section {
                ProgressView("Keeping files and creating a new library")
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("libraryRecoveryProgress")
                Text("Please wait for the result. The confirmed operation must finish before this screen can close.")
                    .font(.subheadline)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case let .failed(title, message):
            Section {
                Label(title, systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("libraryRecoveryMessage")
                inspectButton("Check saved files again")
            }
        case .completed:
            EmptyView()
        }
    }

    private var completedSection: some View {
        Section {
            Label("New library is ready", systemImage: "checkmark.circle")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("libraryRecoverySuccess")
            Text("Copies of the original saved files were kept on this device before the new library was created. Your previous projects have not been restored.")
                .fixedSize(horizontal: false, vertical: true)
            Text("To import an editable backup, tap Done, open Projects, then choose Import editable project. Importing a valid backup adds that project to the new library.")
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("libraryRecoveryImportInstructions")
        }
    }

    private func inspectButton(_ title: LocalizedStringKey) -> some View {
        Button(action: inspect) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("checkLibraryRecoveryFiles")
    }

    private func inspect() {
        switch phase {
        case .recovering, .completed: return
        default: break
        }
        cancelInspection()
        let request = UUID()
        inspectionRequest = request
        phase = .inspecting
        inspectionTask = Task { @MainActor in
            defer {
                if inspectionRequest == request {
                    inspectionTask = nil
                    if case .inspecting = phase { phase = .notInspected }
                }
            }
            do {
                let snapshot = try await onInspect()
                guard !Task.isCancelled, inspectionRequest == request else { return }
                phase = .ready(Inspection(id: request, snapshot: snapshot))
            } catch {
                guard !Task.isCancelled, inspectionRequest == request,
                      !(error is CancellationError) else { return }
                let title = (error as? ProjectLibraryError) == .recoveryNotNeeded
                    ? "Recovery is not needed" : "Saved files could not be checked"
                phase = .failed(title: title, message: failureMessage(error))
            }
        }
    }

    private func cancelInspection() {
        inspectionRequest = UUID()
        inspectionTask?.cancel()
        inspectionTask = nil
        confirmation = nil
        showConfirmation = false
        switch phase {
        case .inspecting, .ready: phase = .notInspected
        default: break
        }
    }

    private func recover(_ inspection: Inspection) {
        guard case let .ready(current) = phase, current.id == inspection.id else { return }
        confirmation = nil
        do {
            // Reserve in the session before creating this sheet's observer.
            let task = try onRecover(inspection.snapshot)
            phase = .recovering
            Task { @MainActor in
                do {
                    try await task.value
                    // Do not suppress a committed receipt if an observer or
                    // enclosing presentation was cancelled in the meantime.
                    phase = .completed
                } catch {
                    phase = .failed(title: "Starting again was not confirmed", message: failureMessage(error))
                }
            }
        } catch {
            phase = .failed(title: "Starting again could not begin", message: failureMessage(error))
        }
        // Failed attempts discard their inspection and require a fresh check.
    }

    private func failureMessage(_ error: Error) -> String {
        if let libraryError = error as? ProjectLibraryError {
            switch libraryError {
            case .staleSnapshot:
                return "The saved files changed after they were checked. Check them again, then review and confirm before trying again. You can also tap Done and retry loading from the studio."
            case .recoveryNotNeeded:
                return "The library may now be readable, or there may be no saved library to recover. Tap Done, then choose Retry loading saved project in the studio."
            default:
                return "\(libraryError.localizedDescription) Check the saved files again before another attempt."
            }
        }
        // Unrecognized errors may contain private paths. Do not expose them or
        // claim that a write failed when its committed result is not known here.
        return "The result could not be confirmed. Check the saved files again before trying again, or tap Done and retry loading from the studio."
    }
}
