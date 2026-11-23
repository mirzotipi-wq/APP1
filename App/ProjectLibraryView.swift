import SwiftUI
import LightingCore

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

    private struct Naming: Identifiable {
        enum Kind { case create, rename(UUID), duplicate(UUID) }
        let id = UUID()
        let kind: Kind
        let title: String
        let initial: String
    }

    private var hasUnsavedChanges: Bool { saved != scene }
    private var canMutate: Bool { !hasUnsavedChanges && library != nil }

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
                            .accessibilityIdentifier("librarySaveCurrent")
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.subheadline)
                            .foregroundStyle(.primary).accessibilityIdentifier("libraryError")
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
                                    Text(project.name).font(.headline)
                                    Text("\(project.scene.lights.count) lights").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Restore") { change { try $0.restore(project.id) } }
                                    .buttonStyle(.borderless).disabled(!canMutate)
                                    .frame(minHeight: 44)
                                    .accessibilityLabel("Restore \(project.name)")
                                Button(role: .destructive) {
                                    pendingDeletion = project
                                    confirmDeletion = true
                                } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 44, height: 44).contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless).disabled(!canMutate)
                                .accessibilityLabel("Delete archived \(project.name)")
                            }
                        }
                        Text("Archived projects can be restored or permanently removed from this library.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Delete archived project?", isPresented: $confirmDeletion, presenting: pendingDeletion) { project in
                Button("Delete project", role: .destructive) {
                    // The domain and store re-check identity, archive status and the
                    // current snapshot; a failed write leaves the displayed library intact.
                    change { try $0.deleteArchived(project.id) }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: { project in
                Text("Remove “\(project.name)” and its saved lighting setup from this library? This cannot be undone here. Existing exports and legacy migration backups are not erased.")
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
                    .accessibilityLabel("Current project: \(project.name)")
                    .accessibilityValue("\(project.scene.lights.count) lights")
                    .accessibilityAddTraits(.isSelected)
                    .accessibilityIdentifier("activeProjectRow")
            } else {
                Button {
                    change { try $0.select(project.id) }
                } label: {
                    projectRowLabel(project, active: false)
                }
                .buttonStyle(.borderless).disabled(!canMutate)
                .accessibilityLabel("Open \(project.name)")
            }
            Menu {
                Button("Rename", systemImage: "pencil") {
                    naming = Naming(kind: .rename(project.id), title: "Rename project", initial: project.name)
                }
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    naming = Naming(kind: .duplicate(project.id), title: "Duplicate project",
                                    initial: String(project.name.prefix(ProjectLibrary.maximumNameLength - 5)) + " copy")
                }
                .disabled((library?.projects.count ?? 0) >= ProjectLibrary.maximumProjects)
                Button("Archive", systemImage: "archivebox") { change { try $0.archive(project.id) } }
                    .disabled(active)
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .disabled(!canMutate)
            .accessibilityLabel("Options for \(project.name)")
        }
    }

    private func projectRowLabel(_ project: LightingProject, active: Bool) -> some View {
        HStack {
            Image(systemName: active ? "checkmark.circle.fill" : "square.stack")
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name).font(.headline).foregroundStyle(.primary)
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

    private func change(_ edit: (inout ProjectLibrary) throws -> Void) {
        perform { try apply(edit) }
    }

    private func perform(_ operation: () throws -> Void) {
        do { try operation(); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct ProjectNameEditor: View {
    let title: String
    let onSubmit: (String) throws -> Void
    @State private var name: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    init(title: String, initial: String, onSubmit: @escaping (String) throws -> Void) {
        self.title = title
        self.onSubmit = onSubmit
        _name = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project name") {
                    HStack {
                        TextField("Name", text: $name).focused($focused)
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
                    .disabled((try? ProjectLibrary.normalizedName(name)) == nil)
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
        do {
            try onSubmit(ProjectLibrary.normalizedName(name))
            focused = false
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
