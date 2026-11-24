import SwiftUI
import LightingCore
import UniformTypeIdentifiers

/// Explicit save boundary: browsing is allowed while dirty, but mutations and
/// switches must wait until the current scene is saved successfully.
struct ProjectLibraryView: View {
    @Binding var library: ProjectLibrary?
    @Binding var scene: LightingScene
    @Binding var saved: LightingScene?
    let onSave: () throws -> Void
    let onApply: (ProjectLibrary) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var naming: Naming?
    @State private var errorMessage: String?
    @State private var pendingDeletion: LightingProject?
    @State private var confirmDeletion = false
    @State private var showImporter = false
    @State private var isImporting = false
    @State private var importRequest = UUID()
    @State private var importTask: Task<Void, Never>?
    @State private var importMessage: String?
    @State private var acceptingImports = true

    private struct Naming: Identifiable {
        enum Kind { case create, rename(UUID), duplicate(UUID) }
        let id = UUID()
        let kind: Kind
        let title: String
        let initial: String
    }

    private var hasUnsavedChanges: Bool { saved != scene }
    private var canMutate: Bool { !hasUnsavedChanges && library != nil && !isImporting }
    private var canImport: Bool {
        acceptingImports && canMutate &&
            (library?.projects.count ?? ProjectLibrary.maximumProjects) < ProjectLibrary.maximumProjects
    }

    var body: some View {
        NavigationStack {
            List {
                if hasUnsavedChanges {
                    Section {
                        Label("Unsaved lighting setup", systemImage: "exclamationmark.circle")
                            .font(.headline)
                        Text("Save your current edits before creating, opening or organizing projects. Nothing is discarded automatically.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Save current setup") { perform { try onSave() } }
                            .disabled(isImporting)
                            .accessibilityIdentifier("librarySaveCurrent")
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.subheadline)
                            .foregroundStyle(.primary).accessibilityIdentifier("libraryError")
                    }
                }
                if isImporting {
                    Section {
                        ProgressView("Opening editable project")
                            .accessibilityIdentifier("projectImportProgress")
                        Button("Cancel import") { cancelImport() }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("cancelProjectImport")
                    }
                } else if let importMessage {
                    Section {
                        Label(importMessage, systemImage: "checkmark.circle")
                            .accessibilityIdentifier("projectImportMessage")
                    }
                }
                Section("On this device") {
                    if let library {
                        ForEach(library.projects.filter { !$0.isArchived }) { project in
                            projectRow(project, active: project.id == library.activeID)
                        }
                    } else {
                        Text("No saved projects yet.").foregroundStyle(.secondary)
                    }
                    Button {
                        naming = Naming(kind: .create, title: "New project", initial: "Portrait setup")
                    } label: {
                        Label("New project", systemImage: "plus.circle")
                    }
                    .disabled(!canMutate || (library?.projects.count ?? 0) >= ProjectLibrary.maximumProjects)
                    .accessibilityIdentifier("newProject")
                    Button {
                        importMessage = nil
                        errorMessage = nil
                        showImporter = true
                    } label: {
                        Label("Import editable project", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!canImport)
                    .accessibilityIdentifier("importEditableProject")
                    Text("Import a Key & Fill editable copy as a new project. Existing saved projects are kept.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let library, library.projects.count >= ProjectLibrary.maximumProjects {
                        Text("64-project limit reached, including archived projects. Remove an archived project to free a slot.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let library, library.projects.contains(where: { $0.isArchived }) {
                    Section("Archived") {
                        ForEach(library.projects.filter(\.isArchived)) { project in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(displayName(project)).font(.headline)
                                    if displayName(project) != project.name {
                                        Text("Project ID: \(project.id.uuidString.prefix(8))")
                                            .font(.caption.monospaced()).foregroundStyle(.secondary)
                                    }
                                    Text("\(project.scene.lights.count) lights").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Restore") { change { try $0.restore(project.id) } }
                                    .buttonStyle(.borderless).disabled(!canMutate)
                                    .frame(minHeight: 44)
                                    .accessibilityLabel("Restore \(displayName(project))")
                                    .accessibilityValue(identityValue(project))
                                Button(role: .destructive) {
                                    pendingDeletion = project
                                    confirmDeletion = true
                                } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 44, height: 44).contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless).disabled(!canMutate)
                                .accessibilityLabel("Delete archived \(displayName(project))")
                                .accessibilityValue(identityValue(project))
                            }
                        }
                        Text("Archived projects can be restored or permanently removed from this library.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { acceptingImports = false; cancelImport(); dismiss() }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json],
                          allowsMultipleSelection: false) { result in
                importSelection(result)
            }
            .onAppear { acceptingImports = true }
            .onDisappear {
                // A system picker may temporarily cover the sheet. Once an
                // actual read starts, closing Projects must cancel that read.
                if !showImporter { acceptingImports = false; cancelImport() }
            }
            .alert("Delete archived project?", isPresented: $confirmDeletion, presenting: pendingDeletion) { project in
                Button("Delete project", role: .destructive) {
                    // The domain and store re-check identity, archive status and the
                    // current snapshot; a failed write leaves the displayed library intact.
                    change { try $0.deleteArchived(project.id) }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: { project in
                Text("Remove “\(confirmationName(project))” and its saved lighting setup from this library? This cannot be undone here. Existing exports and legacy migration backups are not erased.")
            }
            .sheet(item: $naming) { action in
                ProjectNameEditor(title: action.title, initial: action.initial) { name in
                    try apply { next in
                        switch action.kind {
                        case .create: try next.create(name: name, scene: .portrait())
                        case .rename(let id): try next.rename(id, to: name)
                        case .duplicate(let id): try next.duplicate(id, name: name)
                        }
                    }
                }
            }
        }
    }

    private func projectRow(_ project: LightingProject, active: Bool) -> some View {
        HStack(spacing: 12) {
            if active {
                // This is a status row, not a disabled action. Keep the active
                // project's name readable and expose its selection to VoiceOver.
                projectRowLabel(project, active: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current project: \(displayName(project))")
                    .accessibilityValue("\(project.scene.lights.count) lights" + identityValue(project, prefix: ". "))
                    .accessibilityAddTraits(.isSelected)
                    .accessibilityIdentifier("activeProjectRow")
            } else {
                Button {
                    change { try $0.select(project.id) }
                } label: {
                    projectRowLabel(project, active: false)
                }
                .buttonStyle(.borderless).disabled(!canMutate)
                .accessibilityLabel("Open \(displayName(project))")
                .accessibilityValue(identityValue(project))
            }
            Menu {
                Button("Rename", systemImage: "pencil") {
                    naming = Naming(kind: .rename(project.id), title: "Rename project", initial: project.name)
                }
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    naming = Naming(kind: .duplicate(project.id), title: "Duplicate project",
                                    initial: StudioDisplayName.display(project.name, maximumCharacters: ProjectLibrary.maximumNameLength - 5) + " copy")
                }
                .disabled((library?.projects.count ?? 0) >= ProjectLibrary.maximumProjects)
                Button("Archive", systemImage: "archivebox") { change { try $0.archive(project.id) } }
                    .disabled(active)
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .disabled(!canMutate)
            .accessibilityLabel("Options for \(displayName(project))")
            .accessibilityValue(identityValue(project))
        }
    }

    private func projectRowLabel(_ project: LightingProject, active: Bool) -> some View {
        HStack {
            Image(systemName: active ? "checkmark.circle.fill" : "square.stack")
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(project)).font(.headline).foregroundStyle(.primary)
                if displayName(project) != project.name {
                    Text("Project ID: \(project.id.uuidString.prefix(8))")
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Text("\(project.scene.lights.count) lights" + (active ? " · Open" : ""))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 44)
    }

    private func apply(_ edit: (inout ProjectLibrary) throws -> Void) throws {
        guard canMutate, var next = library else { throw ProjectLibraryError.staleSnapshot }
        try edit(&next)
        try onApply(next)
    }

    private func displayName(_ project: LightingProject) -> String {
        let name = StudioDisplayName.display(project.name)
        return name.isEmpty ? "Unnamed project" : name
    }

    private func identityValue(_ project: LightingProject, prefix: String = "") -> String {
        displayName(project) == project.name ? "" : prefix + "Project ID \(project.id.uuidString.prefix(8))"
    }

    private func confirmationName(_ project: LightingProject) -> String {
        displayName(project) + (displayName(project) == project.name ? "" : " (ID \(project.id.uuidString.prefix(8)))")
    }

    private func change(_ edit: (inout ProjectLibrary) throws -> Void) {
        perform { try apply(edit) }
    }

    private func perform(_ operation: () throws -> Void) {
        do { try operation(); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    @MainActor private func importSelection(_ selection: Result<[URL], Error>) {
        guard acceptingImports else { return }
        let urls: [URL]
        do { urls = try selection.get() }
        catch {
            let cocoa = error as NSError
            guard cocoa.domain != NSCocoaErrorDomain || cocoa.code != NSUserCancelledError else { return }
            errorMessage = "The selected file could not be opened. No projects were changed. \(error.localizedDescription)"
            return
        }
        guard let url = urls.first, urls.count == 1 else {
            errorMessage = "Choose one editable Key & Fill project file."
            return
        }
        guard canImport else {
            errorMessage = hasUnsavedChanges
                ? "Save the current setup before importing. Your current edits have been kept."
                : "The library is full or unavailable. Free a project slot before importing."
            return
        }
        cancelImport()
        let request = UUID()
        importRequest = request
        isImporting = true
        importMessage = nil
        errorMessage = nil
        importTask = Task { @MainActor in
            do {
                let document = try await ProjectDocumentIO.read(from: url)
                guard !Task.isCancelled, request == importRequest else { return }
                // The actual apply path rechecks the current editor boundary and
                // performs the store's optimistic transaction before adoption.
                isImporting = false
                try apply { next in
                    try next.create(name: document.name, scene: document.scene)
                }
                importMessage = "Imported “\(StudioDisplayName.display(document.name))” as a new project."
                importTask = nil
            } catch {
                guard !Task.isCancelled, request == importRequest else { return }
                isImporting = false
                importTask = nil
                errorMessage = "The project was not imported. Existing projects and studio edits have been kept. \(error.localizedDescription)"
            }
        }
    }

    private func cancelImport() {
        importRequest = UUID()
        importTask?.cancel()
        importTask = nil
        isImporting = false
    }
}

private struct ProjectNameEditor: View {
    let title: String
    let onSubmit: (String) throws -> Void
    private let initialDisplay: String
    private let requiresNewName: Bool
    @State private var name: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    init(title: String, initial: String, onSubmit: @escaping (String) throws -> Void) {
        self.title = title
        self.onSubmit = onSubmit
        let bounded = StudioDisplayName.display(initial)
        self.initialDisplay = bounded
        self.requiresNewName = bounded != initial
        _name = State(initialValue: bounded)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project name") {
                    HStack {
                        TextField("Name", text: boundedDraft).focused($focused)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.done)
                            .accessibilityIdentifier("projectNameInput")
                            .onSubmit { submit() }
                        if !name.isEmpty {
                            Button {
                                name = ""; focused = true
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless).accessibilityLabel("Clear project name")
                            .accessibilityIdentifier("clearProjectName")
                        }
                    }
                    if requiresNewName {
                        Text("A shortened version of the name is shown. Enter a new name to save it. Cancelling keeps the complete original saved name.")
                            .font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("shortenedProjectNameNotice")
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                            .accessibilityIdentifier("projectNameError")
                    }
                }
                Section {
                    Button { submit() } label: {
                        Text("Save project name").fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled((try? StudioDisplayName.newInput(name)) == nil ||
                              (requiresNewName && name == initialDisplay))
                    .accessibilityIdentifier("confirmProjectName")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
             }
            .onAppear { focused = true }
        }
    }

    private func submit() {
        guard !requiresNewName || name != initialDisplay else {
            errorMessage = "Enter a new name, or cancel to keep the complete saved name."
            return
        }
        do {
            try onSubmit(StudioDisplayName.newInput(name))
            focused = false
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    /// Reject an oversized paste explicitly rather than rendering it or silently
    /// shortening the user's new name. Empty and incomplete drafts remain editable.
    private var boundedDraft: Binding<String> {
        Binding(get: { name }, set: { next in
            guard next.unicodeScalars.prefix(StudioDisplayName.maximumScalars + 1).count <= StudioDisplayName.maximumScalars else {
                errorMessage = StudioDisplayName.NameError.tooLong.localizedDescription
                return
            }
            name = next
            errorMessage = nil
        })
    }
}
