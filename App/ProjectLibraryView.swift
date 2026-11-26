import SwiftUI
import LightingCore
import UniformTypeIdentifiers

/// Explicit save boundary: browsing is allowed while dirty, but mutations and
/// switches must wait until the current scene is saved successfully.
struct ProjectLibraryView: View {
    @Binding var library: ProjectLibrary?
    @Binding var scene: LightingScene
    @Binding var saved: LightingScene?
    let isWorking: Bool
    let onSave: () throws -> Task<Void, Error>
    let onApply: (ProjectLibraryCommand) throws -> Task<Void, Error>
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var naming: Naming?
    @State private var errorMessage: String?
    @State private var pendingDeletion: ProjectLibraryRowPresentation?
    @State private var confirmDeletion = false
    @State private var searchText = ""
    @State private var showImporter = false
    @State private var isImporting = false
    @State private var isCommittingImport = false
    @State private var isPerformingOperation = false
    @State private var operationRequest = UUID()
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
    private var canMutate: Bool {
        !hasUnsavedChanges && library != nil && !isImporting && !isCommittingImport &&
            !isWorking && !isPerformingOperation
    }
    private var canImport: Bool {
        acceptingImports && canMutate &&
            (library?.projects.count ?? ProjectLibrary.maximumProjects) < ProjectLibrary.maximumProjects
    }

    var body: some View {
        // Determine identities from the whole library before filtering. A
        // search must not make two saved projects appear to be the same record.
        let projects = ProjectLibraryRowPresentation.make(for: library?.projects ?? [])
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleProjects = projects.filter { $0.matches(query) }
        let savedProjects = visibleProjects.filter { !$0.project.isArchived }
        let archivedProjects = visibleProjects.filter { $0.project.isArchived }
        NavigationStack {
            List {
                if hasUnsavedChanges {
                    Section {
                        Label("Unsaved lighting setup", systemImage: "exclamationmark.circle")
                            .font(.headline)
                        Text("Save your current edits before creating, opening or organizing projects. Nothing is discarded automatically.")
                            .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                        Button("Save current setup") { perform { try onSave() } }
                            .disabled(isImporting || isCommittingImport || isWorking || isPerformingOperation)
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
                } else if isCommittingImport || isWorking || isPerformingOperation {
                    Section {
                        ProgressView("Saving project changes")
                            .accessibilityIdentifier("projectLibraryProgress")
                        Text("You can close Projects while the save finishes.")
                            .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    }
                } else if let importMessage {
                    Section {
                        Label(importMessage, systemImage: "checkmark.circle")
                            .accessibilityIdentifier("projectImportMessage")
                    }
                }
                Section {
                    if let library {
                        ForEach(savedProjects) { project in
                            projectRow(project, active: project.id == library.activeID)
                        }
                        if savedProjects.isEmpty {
                            Text("No project names match in this section.")
                                .foregroundStyle(StudioPalette.secondaryText)
                                .accessibilityIdentifier("projectSearchEmpty")
                        }
                    } else {
                        Text("No saved projects yet.").foregroundStyle(StudioPalette.secondaryText)
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
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    if let library, library.projects.count >= ProjectLibrary.maximumProjects {
                        Text("64-project limit reached, including archived projects. Remove an archived project to free a slot.")
                            .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    }
                } header: {
                    Text("On this device").foregroundStyle(StudioPalette.secondaryText)
                } footer: {
                    if !projects.isEmpty {
                        Text("Saved top views: circles mark subjects, triangles mark cameras and squares mark lights.")
                            .foregroundStyle(StudioPalette.secondaryText)
                    }
                }
                if projects.contains(where: { $0.project.isArchived }) {
                    Section {
                        ForEach(archivedProjects) { project in
                            archivedProjectRow(project)
                        }
                        if archivedProjects.isEmpty {
                            Text("No archived project names match your search.")
                                .foregroundStyle(StudioPalette.secondaryText)
                                .accessibilityIdentifier("archivedProjectSearchEmpty")
                        }
                        Text("Archived projects can be restored or permanently removed from this library.")
                            .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    } header: {
                        Text("Archived").foregroundStyle(StudioPalette.secondaryText)
                    }
                }
            }
            .navigationTitle("Projects")
            .searchable(text: boundedSearch, placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search project names")
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // The native navigation-bar action exposed a 36pt target.
                // This close action owns its full target and can grow with
                // accessibility text without a fixed toolbar height.
                Button { acceptingImports = false; cancelImport(); dismiss() } label: {
                    HStack {
                        Spacer(minLength: 0)
                        Text("Done")
                            .font(.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(StudioPalette.action)
                .accessibilityIdentifier("projectLibraryDone")
                .padding(.horizontal, 16)
                .background(Color(uiColor: .systemGroupedBackground))
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
            .alert("Delete archived project?", isPresented: $confirmDeletion, presenting: pendingDeletion) { presentation in
                Button("Delete project", role: .destructive) {
                    let project = presentation.project
                    guard library?.projects.first(where: { $0.id == project.id }) == project else {
                        pendingDeletion = nil
                        errorMessage = ProjectLibraryError.staleSnapshot.localizedDescription
                        return
                    }
                    // The domain and store re-check identity, archive status and the
                    // current snapshot; a failed write leaves the displayed library intact.
                    change(.deleteArchived(project.id))
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: { presentation in
                Text("Remove “\(presentation.confirmationName)” and its saved lighting setup from this library? This cannot be undone here. Existing exports and legacy migration backups are not erased.")
            }
            .sheet(item: $naming) { action in
                ProjectNameEditor(title: action.title, initial: action.initial) { name in
                    switch action.kind {
                    case .create: return try apply(.create(name: name, scene: .portrait()))
                    case .rename(let id): return try apply(.rename(id, name: name))
                    case .duplicate(let id): return try apply(.duplicate(id, name: name))
                    }
                }
            }
        }
        .tint(StudioPalette.action)
    }

    private func projectRow(_ presentation: ProjectLibraryRowPresentation, active: Bool) -> some View {
        let project = presentation.project
        return HStack(spacing: 12) {
            if active {
                // This is a status row, not a disabled action. Keep the active
                // project's name readable and expose its selection to VoiceOver.
                projectRowLabel(presentation, active: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current project: \(presentation.name)")
                    .accessibilityValue("\(project.scene.lights.count) lights" + presentation.identityValue(prefix: ". "))
                    .accessibilityAddTraits(.isSelected)
                    .accessibilityIdentifier("activeProjectRow")
            } else {
                Button {
                    change(.select(project.id))
                } label: {
                    projectRowLabel(presentation, active: false)
                }
                .buttonStyle(.borderless).disabled(!canMutate)
                .accessibilityLabel("Open \(presentation.name)")
                .accessibilityValue(presentation.identityValue())
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
                Button("Archive", systemImage: "archivebox") { change(.archive(project.id)) }
                    .disabled(active)
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .disabled(!canMutate)
            .accessibilityLabel("Options for \(presentation.name)")
            .accessibilityValue(presentation.identityValue())
        }
    }

    private func projectRowLabel(_ presentation: ProjectLibraryRowPresentation, active: Bool) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            ProjectLibraryThumbnail(scene: presentation.project.scene)
            projectRowText(presentation, active: active)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func projectRowText(_ presentation: ProjectLibraryRowPresentation, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.name).font(.headline).foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let identifier = presentation.identifier {
                Text("Project ID: \(identifier)")
                    .font(.caption.monospaced()).foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 4) {
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(StudioPalette.selection)
                }
                Text("\(presentation.project.scene.lights.count) lights" + (active ? " · Open" : ""))
                    .foregroundStyle(Color.primary)
            }
            .font(.caption)
        }
    }

    private func archivedProjectRow(_ presentation: ProjectLibraryRowPresentation) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            projectRowLabel(presentation, active: false)
            HStack(spacing: 8) {
                Button("Restore") { change(.restore(presentation.id)) }
                    .buttonStyle(.borderless).disabled(!canMutate)
                    .frame(minHeight: 44)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Restore \(presentation.name)")
                    .accessibilityValue(presentation.identityValue())
                Button(role: .destructive) {
                    // Freeze the name and distinguishing ID with the complete
                    // record, so filtering or refresh cannot relabel this alert.
                    pendingDeletion = presentation
                    confirmDeletion = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(StudioPalette.destructive)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.borderless).disabled(!canMutate)
                .accessibilityLabel("Delete archived \(presentation.name)")
                .accessibilityValue(presentation.identityValue())
            }
        }
    }

    private func apply(_ command: ProjectLibraryCommand) throws -> Task<Void, Error> {
        guard canMutate else { throw ProjectLibraryError.staleSnapshot }
        // The parent reserves synchronously; validation and mutation happen on
        // the worker, including a possibly large imported scene or legacy name.
        return try onApply(command)
    }

    private var boundedSearch: Binding<String> {
        Binding(get: { searchText }, set: { next in
            // Search is transient. Bound a paste by Unicode scalars so even a
            // single unusually long grapheme cannot expand native text layout.
            searchText = String(next.unicodeScalars.prefix(StudioDisplayName.maximumScalars))
        })
    }

    private func change(_ command: ProjectLibraryCommand) {
        perform { try apply(command) }
    }

    private func perform(_ operation: () throws -> Task<Void, Error>) {
        guard !isPerformingOperation else { return }
        do {
            let task = try operation() // Reserves the parent before spawning an observer.
            let request = UUID()
            operationRequest = request
            isPerformingOperation = true
            errorMessage = nil
            Task { @MainActor in
                defer { if operationRequest == request { isPerformingOperation = false } }
                do { try await task.value }
                catch {
                    if acceptingImports, operationRequest == request { errorMessage = error.localizedDescription }
                }
            }
        } catch { errorMessage = error.localizedDescription }
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
            defer {
                if request == importRequest {
                    isImporting = false
                    isCommittingImport = false
                    importTask = nil
                }
            }
            do {
                let document = try await ProjectDocumentIO.read(from: url)
                guard !Task.isCancelled, acceptingImports, request == importRequest else { return }
                guard !hasUnsavedChanges, library != nil, !isWorking,
                      (library?.projects.count ?? ProjectLibrary.maximumProjects) < ProjectLibrary.maximumProjects else {
                    throw ProjectLibraryError.staleSnapshot
                }
                // Reserve the parent while the provider-read gate is still
                // closed. From here the commit belongs to Studio, and closing
                // Projects must not turn a successful write into a cancellation.
                let commit = try onApply(.create(name: document.name, scene: document.scene))
                isCommittingImport = true
                isImporting = false
                try await commit.value
                guard acceptingImports, request == importRequest else { return }
                importMessage = "Imported “\(StudioDisplayName.label(document.name, fallback: "Unnamed project"))” as a new project."
                importTask = nil
            } catch {
                guard acceptingImports, request == importRequest else { return }
                if Task.isCancelled && !isCommittingImport { return }
                isImporting = false
                importTask = nil
                errorMessage = "The project was not imported. Existing projects and studio edits have been kept. \(error.localizedDescription)"
            }
        }
    }

    private func cancelImport() {
        guard !isCommittingImport else { return }
        importRequest = UUID()
        importTask?.cancel()
        importTask = nil
        isImporting = false
    }
}

/// Presentation-only identity. Stored names and UUIDs remain untouched. Build
/// once per library render so each name is sanitized once, including legacy
/// names whose small grapheme count may hide a large number of Unicode scalars.
struct ProjectLibraryRowPresentation: Identifiable {
    let project: LightingProject
    let name: String
    let identifier: String?

    var id: UUID { project.id }

    var confirmationName: String {
        name + (identifier.map { " (ID \($0))" } ?? "")
    }

    func identityValue(prefix: String = "") -> String {
        identifier.map { prefix + "Project ID \($0)" } ?? ""
    }

    func matches(_ query: String) -> Bool {
        query.isEmpty || name.localizedStandardContains(query)
    }

    static func make(for projects: [LightingProject]) -> [Self] {
        let names = projects.map { StudioDisplayName.label($0.name, fallback: "Unnamed project") }
        let comparableNames = names.map { name in
            let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            // Invisible suffixes can leave different names looking identical.
            // Ignore them only in comparison keys: scripts and joined emoji
            // still need their original scalars in the displayed label.
            return String(String.UnicodeScalarView(folded.unicodeScalars.filter {
                !$0.properties.isDefaultIgnorableCodePoint
            }))
        }
        let counts = Dictionary(grouping: comparableNames, by: { $0 }).mapValues(\.count)
        let ids = projects.map { $0.id.uuidString }

        return projects.indices.map { index in
            let needsIdentity = names[index] != projects[index].name || (counts[comparableNames[index]] ?? 0) > 1
            var identifier: String?
            if needsIdentity {
                // A fixed eight-character prefix can itself collide. Expand
                // at UUID group boundaries until the identifier is unambiguous
                // among all records, including those hidden by the search.
                for length in [8, 13, 18, 23, 36] {
                    let candidate = String(ids[index].prefix(length))
                    let collision = ids.indices.contains { other in
                        other != index && ids[other].hasPrefix(candidate)
                    }
                    if !collision {
                        identifier = candidate
                        break
                    }
                }
            }
            return .init(project: projects[index], name: names[index], identifier: identifier)
        }
    }
}

private struct ProjectNameEditor: View {
    let title: String
    let onSubmit: (String) throws -> Task<Void, Error>
    private let initialDisplay: String
    private let requiresNewName: Bool
    @State private var name: String
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var focused = false

    init(title: String, initial: String, onSubmit: @escaping (String) throws -> Task<Void, Error>) {
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
                Section {
                    editorHeading
                    HStack {
                        StudioTextField("Name", text: boundedDraft, isFocused: $focused,
                            accessibility: .init(label: "Name", identifier: "projectNameInput"),
                            returnKeyType: .done) { submit() }
                            .disabled(isSubmitting)
                        if !name.isEmpty {
                            Button {
                                name = ""
                                errorMessage = nil
                                focused = true
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(StudioPalette.secondaryText)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless).accessibilityLabel("Clear project name")
                            .disabled(isSubmitting)
                            .accessibilityIdentifier("clearProjectName")
                        }
                    }
                    if requiresNewName {
                        Text("A shortened version of the name is shown. Enter a new name to save it. Cancelling keeps the complete original saved name.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                            .accessibilityIdentifier("shortenedProjectNameNotice")
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(StudioPalette.destructive)
                            .accessibilityIdentifier("projectNameError")
                    }
                    if isSubmitting {
                        ProgressView("Saving project name")
                        Text("This save finishes before closing. Your entered name stays here if saving fails.")
                            .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    }
                }
                Section {
                    Button { submit() } label: {
                        Text("Save project name").fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(canSubmit ? StudioPalette.prominentActionText : StudioPalette.secondaryText)
                            .background(canSubmit ? StudioPalette.action : Color(uiColor: .tertiarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("confirmProjectName")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.never)
            .interactiveDismissDisabled(isSubmitting)
            .onAppear { focused = true }
        }
        .tint(StudioPalette.action)
    }

    private var canSubmit: Bool {
        !isSubmitting && (try? StudioDisplayName.newInput(name)) != nil &&
            (!requiresNewName || name != initialDisplay)
    }

    /// Form content grows and scrolls at accessibility text sizes, including
    /// while the keyboard is visible; navigation-bar controls cannot grow.
    private var editorHeading: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            Text("Project name")
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(StudioPalette.action)
            .disabled(isSubmitting)
            .accessibilityIdentifier("projectNameCancel")
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        guard !requiresNewName || name != initialDisplay else {
            errorMessage = "Enter a new name, or cancel to keep the complete saved name."
            return
        }
        do {
            let normalized = try StudioDisplayName.newInput(name)
            let task = try onSubmit(normalized) // Reserves before a second submit can enqueue.
            isSubmitting = true
            focused = false
            Task { @MainActor in
                do { try await task.value; dismiss() }
                catch { errorMessage = error.localizedDescription }
                isSubmitting = false
            }
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
            guard next != name else { return }
            name = next
            errorMessage = nil
        })
    }
}
