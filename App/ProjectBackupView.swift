import Foundation
import LightingCore
import SwiftUI
import UniformTypeIdentifiers

/// The menu captures these values before presentation. Saving an editable copy
/// never saves, switches, or changes a record in the app's project library.
struct ProjectBackupView: View {
    let name: String
    let scene: LightingScene
    @Environment(\.dismiss) private var dismiss
    @State private var prepared: ProjectBackupFile?
    @State private var preparationError: String?
    @State private var exportMessage: String?
    @State private var exportFailed = false
    @State private var showExporter = false
    @State private var retry = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Lighting setup") {
                    Text(StudioDisplayName.label(name, fallback: "Unnamed project")).font(.headline)
                        .accessibilityIdentifier("editableCopyProjectName")
                    Label("\(scene.lights.count) lights", systemImage: "lightbulb")
                        .accessibilityIdentifier("editableCopyLightCount")
                    Text("Includes the project name, lights, camera, preview settings and any committed room measurements from the studio when you opened this sheet.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section {
                    if prepared != nil {
                        Button {
                            exportMessage = nil
                            exportFailed = false
                            showExporter = true
                        } label: {
                            Label("Save editable copy", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(showExporter)
                        .accessibilityIdentifier("saveEditableProjectCopy")
                    } else if let preparationError {
                        Label("Copy could not be prepared", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Text(preparationError).font(.subheadline)
                            .accessibilityIdentifier("editableCopyPreparationError")
                        Button("Try again") { retry += 1 }
                            .frame(minHeight: 44)
                    } else {
                        ProgressView("Preparing editable copy")
                    }
                    if let exportMessage {
                        Label(exportMessage, systemImage: exportFailed ? "exclamationmark.triangle" : "checkmark.circle")
                            .font(.subheadline)
                            .accessibilityIdentifier("editableCopyExportMessage")
                    }
                }
                Section("Open the copy later") {
                    Text("In Projects, choose Import editable project. Importing creates a separate project and keeps existing projects.")
                    Text("Reference photos and edit history are not included. Your current studio edits stay open after exporting.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("editableCopyScope")
                }
            }
            .navigationTitle("Editable project copy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("closeEditableProjectCopy")
                }
            }
            .task(id: retry) { await prepare() }
            .fileExporter(isPresented: $showExporter, document: prepared, contentType: .json,
                          defaultFilename: ProjectBackupFile.suggestedFilename) { result in
                switch result {
                case .success:
                    exportFailed = false
                    exportMessage = "Editable copy saved to the location you selected."
                case .failure(let error):
                    let cocoa = error as NSError
                    guard cocoa.domain != NSCocoaErrorDomain || cocoa.code != NSUserCancelledError else { return }
                    exportFailed = true
                    exportMessage = "The copy could not be saved. Your studio edits remain open. \(error.localizedDescription)"
                }
                // On system-dialog cancellation SwiftUI does not call this
                // completion. No saved status or project mutation is produced.
            }
        }
    }

    @MainActor private func prepare() async {
        // Keep the immutable document alive if this task restarts while the
        // system exporter is using it, or after returning from its sheet.
        guard !Task.isCancelled, prepared == nil else { return }
        preparationError = nil
        let name = name, scene = scene
        let worker = Task.detached(priority: .utility) {
            try Task.checkCancellation()
            let project = try LightingProjectDocument(name: name, scene: scene)
            let file = try ProjectBackupFile(project: project)
            try Task.checkCancellation()
            return file
        }
        do {
            let file = try await withTaskCancellationHandler {
                let file = try await worker.value
                try Task.checkCancellation()
                return file
            } onCancel: {
                worker.cancel()
            }
            guard !Task.isCancelled else { return }
            prepared = file
        } catch {
            guard !Task.isCancelled else { return }
            preparationError = error.localizedDescription
        }
    }
}
