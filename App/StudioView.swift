import SwiftUI
import LightingCore

@MainActor
struct StudioView: View {
    @State private var session = StudioSession()
    @EnvironmentObject private var entitlements: EntitlementStore
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRaw = PlanUnits.metric.rawValue
    @Environment(\.locale) private var locale
    @State private var planNeedsLabelNotice = false
    @State private var planGridTitle = StudioPlanGridTitleKey.defaultValue
    @State private var showProjects = false
    @State private var showRoomPlacement = false
    @State private var showSubject = false
    @State private var renamingLightID: UUID?
    @State private var lightNameDraft = ""
    @State private var lightNameInputTooLong = false
    @State private var showRenameLight = false
    @State private var renameGeneration: UUID?
    @State private var luxTarget: LuxTarget?
    @State private var showARPlacement = false
    @State private var showSettings = false
    @State private var mode = "Plan"
    @State private var studySubject: StudySubject = .sphere
    @State private var orbitFitRequest = 0
    @State private var showRecipes = false
    @State private var recipeUsesCurrentPlacement = true
    @State private var recipeMessage: String?
    @State private var showStudioGuide = false
    @State private var showMeter = false
    @State private var meterNavigationRequest = 0
    @State private var confirmRemove = false
    @State private var removalTarget: RemovalTarget?
    @State private var referenceContext: SceneContext?
    @State private var roomContext: SceneContext?
    @State private var arrangementContext: SceneContext?
    @State private var arContext: SceneContext?
    @State private var confirmReloadConflict = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    // Read-through projections, never independently stored copies of the editor.
    private var scene: LightingScene {
        get { session.scene }
        nonmutating set { session.update(newValue, from: session.generation) }
    }
    private var selected: UUID? {
        get { session.selection }
        nonmutating set { session.select(newValue, from: session.generation) }
    }
    private var library: ProjectLibrary? { session.library }
    private var saved: LightingScene? { session.saved }
    private var editHistory: SceneEditHistory { session.history }
    private var libraryOperation: ProjectLibraryOperationState { session.libraryOperation }
    private var loaded: Bool { session.loaded }
    private var saveBlocked: Bool { session.saveBlocked }
    private var saveConflict: Bool { session.saveConflict }
    private var planDrag: StudioSession.PlanDrag? { session.planDrag }
    private var message: String? {
        get { session.message }
        nonmutating set { session.message = newValue }
    }

    private struct LuxTarget: Identifiable {
        let id = UUID()
        let light: StudioLight
        let scene: LightingScene
        let generation: UUID
    }

    private struct RemovalTarget {
        let lightID: UUID
        let generation: UUID
    }

    private struct SceneContext: Identifiable {
        let scene: LightingScene
        let generation: UUID
        let owner = UUID().uuidString
        var id: String { owner }
    }

    var body: some View {
        let generation = libraryOperation.generation
        return NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header
                            if saveBlocked {
                                ContentUnavailableView {
                                    Label("Saved project unavailable", systemImage: "externaldrive.badge.exclamationmark")
                                } description: {
                                    Text("Your saved data is protected. Editing and export are unavailable until the library can be opened.")
                                } actions: {
                                    Button { load(from: generation) } label: {
                                        Text("Retry loading saved project")
                                            .foregroundStyle(StudioPalette.prominentActionText)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(minWidth: 44, minHeight: 44)
                                    }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(libraryOperation.isBusy)
                                }
                            } else if !loaded {
                                ProgressView("Opening projects…")
                                    .frame(maxWidth: .infinity, minHeight: 160)
                            } else {
                                if saveConflict { conflictRecoveryPanel.disabled(libraryOperation.isBusy) }
                                workflowActions.disabled(libraryOperation.isBusy)
                                workspace.disabled(libraryOperation.isBusy)
                                meter.id("meterPanel").disabled(libraryOperation.isBusy)
                                rack.disabled(libraryOperation.isBusy)
                                if let light = scene.lights.first(where: { $0.id == selected }) {
                                    inspector(light).disabled(libraryOperation.isBusy)
                                } else {
                                    ContentUnavailableView("No light selected", systemImage: "lightbulb",
                                        description: Text("Add a light or choose a recipe."))
                                }
                                Text("Illustrative 3D shading. Lux estimates describe an ideal camera-facing plane, not measured skin exposure or a calibrated fixture.")
                                    .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                            }
                            if let message, !saveConflict { Text(message).font(.footnote).accessibilityIdentifier("saveMessage") }
                        }
                        .padding(16).frame(maxWidth: 820).frame(maxWidth: .infinity)
                    }
                    .scrollDisabled(planDrag != nil)
                    .onChange(of: meterNavigationRequest) { _, _ in
                        if reduceMotion {
                            proxy.scrollTo("meterPanel", anchor: .top)
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo("meterPanel", anchor: .top)
                            }
                        }
                    }
                }
                .clipped()
                editingBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .tint(StudioPalette.action)
            .navigationTitle("Key & Fill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Recipes", systemImage: "square.stack") { showRecipes = true }
                        .disabled(!loaded || saveBlocked || libraryOperation.isBusy).accessibilityIdentifier("recipes")
                }
            }
            .sheet(isPresented: $showRecipes) { recipeSheet }
            .sheet(isPresented: $showStudioGuide) { StudioGuideView() }
            .sheet(isPresented: $showSettings) { StudioSettingsView(store: entitlements) }
            .sheet(item: $referenceContext) { context in
                ReferenceComparisonView(scene: context.scene) { rig in
                    guard acceptsSceneResult(from: context) else { return }
                    replace(rig); mode = "Study"
                }
            }
            .background {
                if let context = roomContext {
                    Color.clear
                        .sheet(isPresented: roomPresentationBinding(for: context), onDismiss: {
                            finishRoomEditing(context)
                        }) {
                            ManualRoomPlacementView(scene: scene,
                                onRemove: { removeRoom(from: context) },
                                onClose: { retireRoomPresentation(context) }) { room in
                                    applyRoom(room, from: context)
                                }
                        }
                        .id(context.owner)
                }
            }
            .sheet(item: $luxTarget) { target in
                LightTargetLuxView(light: target.light, scene: target.scene) { adjusted in
                    guard libraryOperation.allowsSceneMutation(from: target.generation),
                          scene == target.scene,
                          let index = scene.lights.firstIndex(where: { $0.id == target.light.id }),
                          scene.lights[index] == target.light else {
                        message = "The setup changed while adjusting output. Open the light's target again."
                        return
                    }
                    var next = scene
                    next.lights[index] = adjusted
                    replace(next)
                }
            }
            .sheet(item: $arrangementContext) { context in
                SceneArrangementView(scene: context.scene) { next in
                    guard acceptsSceneResult(from: context) else { return }
                    replace(next)
                }
            }
            .background {
                if let context = arContext {
                    Color.clear
                        .sheet(isPresented: roomPresentationBinding(for: context, isAR: true), onDismiss: {
                            finishRoomEditing(context)
                        }) {
                            ARPlacementView(scene: scene,
                                onRoomRemove: { removeRoom(from: context) },
                                onClose: { retireRoomPresentation(context) }) { room in
                                    applyRoom(room, from: context)
                                }
                        }
                        .id(context.owner)
                }
            }
            .sheet(isPresented: $showSubject) {
                NavigationStack {
                    ScrollView {
                        let owner = editOwner("subject")
                        SubjectInspector(position: subjectPositionBinding,
                                         onEditingChanged: editHandler(owner: owner))
                            .id(owner).padding(20)
                            .disabled(libraryOperation.isBusy)
                    }
                    .navigationTitle("Subject position")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSubject = false }
                        }
                    }
                }
            }
            .alert("Rename light", isPresented: $showRenameLight) {
                TextField("Light name", text: boundedLightNameDraft)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) { renamingLightID = nil }
                Button("Rename", action: sceneAction { renameSelectedLight() })
                    .disabled(lightNameInputTooLong || !isValidLightName(lightNameDraft))
            } message: {
                Text(lightNameInputTooLong
                     ? "That name is too long. Your previous entry was kept. Edit the name before renaming."
                     : "Use a descriptive name of up to 80 characters.")
            }
            .sheet(isPresented: $showProjects) {
                // This feature's legacy Binding inputs are read-only: mutations
                // use onSave/onApply. Read the live session after awaited work,
                // rather than freeze the values in Binding.constant snapshots.
                ProjectLibraryView(library: Binding(get: { session.library }, set: { _ in }),
                                   scene: Binding(get: { session.scene }, set: { _ in }),
                                   saved: Binding(get: { session.saved }, set: { _ in }),
                                   isWorking: libraryOperation.isBusy,
                                   onSave: { try persistScene(from: generation) },
                                   onApply: { try applyLibrary($0, from: generation) })
            }
            .sheet(isPresented: $session.showRecoveryCapacity) {
                RecoveryCapacityView(onLoad: {
                    try await session.recoveryProjects()
                }, onReplace: { candidate in
                    try beginLibraryOperation(.recover(name: recoveryProjectName, replacing: candidate), from: generation)
                })
            }
            .confirmationDialog("Remove selected light?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove light", role: .destructive) {
                    guard let target = removalTarget,
                          libraryOperation.allowsSceneMutation(from: target.generation) else { return }
                    var next = scene
                    next.lights.removeAll { $0.id == target.lightID }
                    replace(next)
                    removalTarget = nil
                }
                Button("Cancel", role: .cancel) { removalTarget = nil }
            }
            .alert("Reload saved project?", isPresented: $confirmReloadConflict) {
                Button("Keep editing", role: .cancel) {}
                Button("Reload and discard edits", role: .destructive) { reloadAfterConflict(from: generation) }
            } message: {
                Text("Only the unsaved changes in this window will be discarded. The latest saved library will be opened.")
            }
            .task { if !loaded { load(from: generation) } }
            .onChange(of: session.generation) { _, _ in dismissSceneEditors() }
            .onChange(of: session.workspaceResetID) { _, _ in mode = "Plan"; showMeter = false }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { finishPlanDrag(); session.endEditing() }
            }
            .onChange(of: mode) { _, _ in finishPlanDrag(); session.endEditing() }
            .onChange(of: selected) { _, _ in finishPlanDrag(); session.endEditing() }
            .onDisappear { finishPlanDrag(); session.endEditing() }
        }
    }

    private var projectName: String { session.projectName }
    private var displayUnits: PlanUnits { StudioPreferences.units(from: unitsRaw) }

    /// Keep Save reachable while scrolling, with content-sized text rather
    /// than a navigation-bar height limit. It remains visible while blocked.
    private var editingBar: some View {
        let generation = libraryOperation.generation
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            if loaded && !saveBlocked {
                HStack(spacing: 12) {
                    Text("Edit history")
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button(action: sceneAction { undo() }) {
                        Label("Undo", systemImage: "arrow.uturn.backward").labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(libraryOperation.isBusy || !editHistory.canUndo || editHistory.isEditing || planDrag != nil).accessibilityLabel("Undo").accessibilityIdentifier("undo")
                    Button(action: sceneAction { redo() }) {
                        Label("Redo", systemImage: "arrow.uturn.forward").labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(libraryOperation.isBusy || !editHistory.canRedo || editHistory.isEditing || planDrag != nil).accessibilityLabel("Redo").accessibilityIdentifier("redo")
                }
                .frame(maxWidth: .infinity)
            }
            Button { save(from: generation) } label: {
                Text("Save")
                    .font(.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(StudioPalette.action)
            .disabled(!loaded || saveBlocked || libraryOperation.isBusy)
            .accessibilityIdentifier("saveProject")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // Prefer one row when the full title and action labels fit. At narrower
    // widths or larger text sizes, place the title above the adaptive actions.
    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    projectHeading
                    projectActions
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 8) {
                        projectHeading.fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 0)
                        projectActions.fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        projectHeading
                        projectActions
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var projectHeading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LIGHTING STUDIO").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(StudioPalette.secondaryText)
            Text(saveBlocked ? "Project unavailable" : StudioDisplayName.label(projectName, fallback: "Unnamed project"))
                .font(.title2.bold())
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .accessibilityIdentifier("projectName")
            Text(saveBlocked ? "Saved data protected" : (saved == scene ? "Saved locally" : "Unsaved changes"))
                .font(.caption).foregroundStyle(StudioPalette.secondaryText).accessibilityIdentifier("projectStatus")
            if let operation = libraryOperation.pending?.operation {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(operation.progressTitle).font(.caption)
                }.accessibilityElement(children: .combine).accessibilityIdentifier("projectOperationProgress")
            }
        }
    }

    private var projectActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                projectLibraryButton
                projectUtilityActions
            }
            .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 8) {
                projectLibraryButton
                projectUtilityActions
            }
        }
    }

    private var projectLibraryButton: some View {
        Button { showProjects = true } label: {
            Label("Projects", systemImage: "folder")
                .font(.subheadline)
                .padding(.horizontal, 8)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .disabled(!loaded || saveBlocked || libraryOperation.isBusy).accessibilityIdentifier("openProjectLibrary")
    }

    private var projectUtilityActions: some View {
        HStack(spacing: 8) {
            LightingPlanExportMenu(scene: scene, title: projectName, textSettings: exportText)
                .disabled(!loaded || saveBlocked || libraryOperation.isBusy)
            Menu {
                Button("Subject position", systemImage: "person.crop.rectangle") { showSubject = true }
                Button("Arrange setup", systemImage: "arrow.triangle.2.circlepath") {
                    arrangementContext = sceneContext()
                }
                Button("Place in AR", systemImage: "arkit") {
                    arContext = sceneContext(); showARPlacement = true
                }
                Divider()
                Button("Settings", systemImage: "gearshape") { showSettings = true }
            } label: {
                Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Studio tools")
            .accessibilityIdentifier("studioTools")
            .disabled(!loaded || saveBlocked || libraryOperation.isBusy || editHistory.isEditing)
            Button { showStudioGuide = true } label: {
                Label("Guide", systemImage: "questionmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(libraryOperation.isBusy || editHistory.isEditing)
            .accessibilityLabel("Studio guide")
            .accessibilityHint("Read the workflow while keeping your current setup open")
            .accessibilityIdentifier("openStudioGuide")
        }
    }

    private var conflictRecoveryPanel: some View {
        let generation = libraryOperation.generation
        return VStack(alignment: .leading, spacing: 8) {
            Label("Saved library changed", systemImage: "exclamationmark.circle").font(.headline)
            Text("Your setup is still in this window. Save a separate project to preserve it without replacing the newer saved version, or reload the latest library.").font(.subheadline)
            Button { saveConflictCopy(from: generation) } label: {
                Label("Save setup as new project", systemImage: "plus.square.on.square")
                    .foregroundStyle(StudioPalette.prominentActionText)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("saveConflictCopy")
            Button("Reload latest saved library") { confirmReloadConflict = true }
                .frame(minHeight: 44).accessibilityIdentifier("reloadConflict")
            if let message {
                Text(message).font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    .accessibilityIdentifier("conflictMessage")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    /// Reference and measured-room placement are primary workflow actions,
    /// not controls hidden below the canvas or the sticky edit-history bar.
    private var workflowActions: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
        return layout {
            Button { referenceContext = sceneContext() } label: {
                Label("Reference photo", systemImage: "rectangle.split.2x1")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Compare reference photo")
            .accessibilityIdentifier("openReference")
            Button { roomContext = sceneContext(); showRoomPlacement = true } label: {
                Label("Room placement", systemImage: "ruler")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Room placement")
            .accessibilityHint("Enter measured room dimensions and check equipment positions")
            .accessibilityIdentifier("openRoomPlacement")
        }
    }

    private var workspace: some View {
        let generation = libraryOperation.generation
        return VStack(spacing: 10) {
            workspaceHeader
            viewModeChoices
            VStack(spacing: 0) {
                if mode == "Plan" {
                    // The title grows outside the diagram, so larger text
                    // cannot cover equipment or change the world projection.
                    Text(planGridTitle)
                        .font(.caption2.monospaced().weight(.medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(StudioPalette.planBackground)
                        .allowsHitTesting(false)
                }
                ZStack(alignment: .topLeading) {
                    StudioPalette.planBackground
                    if mode == "Plan" { plan }
                    else if mode == "Camera" { cameraPreview }
                    else if mode == "Study" { ReferenceStudyPreview(scene: scene, subject: studySubject).id(generation) }
                    else {
                        RealityStudioPreview(scene: scene, selected: selected, fitRequest: orbitFitRequest) { id in
                            guard libraryOperation.allowsSceneMutation(from: generation),
                                  scene.lights.contains(where: { $0.id == id }) else { return }
                            selected = id
                        }
                        .id(generation)
                        .accessibilityLabel("Illustrative 3D lighting preview")
                    }
                    if mode != "Plan" {
                        Text(mode == "Camera" ? "CAMERA / 3:2" : mode == "Study" ? "LIGHT STUDY / DIRECT ONLY" : "3D / DRAG TO ORBIT")
                            .font(.caption2.monospaced().weight(.medium)).foregroundStyle(.white.opacity(0.75))
                            .padding(10).allowsHitTesting(false)
                    }
                }
                .frame(height: 280)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onPreferenceChange(StudioPlanLabelNoticeKey.self) { value in
                if planNeedsLabelNotice != value { planNeedsLabelNotice = value }
            }
            .onPreferenceChange(StudioPlanGridTitleKey.self) { value in
                if mode == "Plan", planGridTitle != value { planGridTitle = value }
            }
            if mode == "Plan" {
                if let light = scene.lights.first(where: { $0.id == selected }) {
                    Text("Selected: " + lightDisplayName(light) + " · Drag its marker to move")
                        .font(.caption.weight(.medium))
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("planSelectedLight")
                    if lightDisplayName(light) != light.name {
                        Text("Light ID: \(light.id.uuidString.prefix(8))")
                            .font(.caption2.monospaced()).foregroundStyle(StudioPalette.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if planNeedsLabelNotice {
                    Text("Use the light list below to select lights in crowded positions.")
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("planLabelNotice")
                }
            }
            HStack {
                Label("\(scene.lights.count) lights", systemImage: "lightbulb")
                Spacer()
                if mode == "3D" {
                    Button("Fit setup", systemImage: "arrow.up.left.and.arrow.down.right") { orbitFitRequest += 1 }
                        .frame(minHeight: 44)
                        .accessibilityHint("Frames the entire rig and resets the orbit camera")
                        .accessibilityIdentifier("fitStudioSetup")
                }
                Text(displayUnits == .metric ? "Meters · cd · K" : "Feet · cd · K").monospaced()
            }.font(.caption).foregroundStyle(StudioPalette.secondaryText)
            if mode == "3D" {
                Text("Drag to orbit · Pinch to zoom · Two fingers to pan · Tap a light to select")
                    .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if mode == "Study" {
                studySubjectChoices
                Text(studySubject == .sphere
                     ? "Neutral sphere and panel · direct light, finite-source shadows and relative color. Not calibrated exposure."
                     : "Neutral mannequin · head, nose, ears, shoulders and matte clothing. Uses your actual camera framing. CPU direct-light diagnostic, not calibrated skin or a reconstructed person.")
                    .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if mode == "Camera" || mode == "Study" {
                Divider()
                let owner = editOwner("camera")
                CameraInspector(position: cameraPositionBinding, lens: cameraLensBinding,
                                subject: scene.subject, onEditingChanged: editHandler(owner: owner))
                    .id(owner)
            }
        }.padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    /// Keep the title above the actions at accessibility sizes. Giving each
    /// group its own width avoids compressing short words into letter columns.
    private var workspaceHeader: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
        return layout {
            HStack(spacing: 8) {
                Image(systemName: "viewfinder").accessibilityHidden(true)
                Text("Scene")
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("workspaceSceneTitle")
            }
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    workspaceMeterButton
                    workspaceAddButton
                }
                .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 8) {
                    workspaceMeterButton
                    workspaceAddButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspaceHeader")
    }

    private var workspaceMeterButton: some View {
        Button {
            showMeter = true
            meterNavigationRequest += 1
        } label: {
            Label {
                Text("Meter")
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .studioTextLayoutProbe("workspaceMeterTitle")
            } icon: {
                Image(systemName: "sun.max")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 8)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(StudioPalette.action)
        .accessibilityLabel("Open light meter and test card")
        .accessibilityHint("Opens and scrolls to the meter controls")
        .accessibilityIdentifier("openMeter")
        .studioTextLayoutValue("workspaceMeterTitle")
    }

    private var workspaceAddButton: some View {
        Button(action: sceneAction { addLight() }) {
            Image(systemName: "plus")
                .font(.headline)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .disabled(scene.lights.count >= 12 || !loaded)
        .accessibilityLabel("Add light")
        .accessibilityHint("Adds and selects a new light in the setup")
        .accessibilityIdentifier("addLightShortcut")
    }

    private var choiceLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
    }

    private var viewModeChoices: some View {
        choiceLayout {
            ForEach(["Plan", "3D", "Camera", "Study"], id: \.self) { choice in
                choiceButton(choice, id: "viewMode-" + choice, isSelected: mode == choice) {
                    mode = choice
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("View")
        .accessibilityIdentifier("viewMode")
    }

    private var studySubjectChoices: some View {
        choiceLayout {
            choiceButton("Sphere", id: "studySubject-Sphere", isSelected: studySubject == .sphere) {
                studySubject = .sphere
            }
            choiceButton("Mannequin", id: "studySubject-Mannequin", isSelected: studySubject == .bust) {
                studySubject = .bust
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study subject")
        .accessibilityIdentifier("studySubject")
    }

    /// The label itself owns the target size; the group keeps each choice
    /// available as a separate action when the layout becomes vertical.
    private func choiceButton(_ title: String, id: String, isSelected: Bool,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minWidth: 44,
                   maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                   minHeight: 44)
            .background(Color(uiColor: .tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(StudioPalette.action)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private var cameraPreview: some View {
        GeometryReader { geo in
            if CameraFraming(scene: scene) != nil {
                let aspect = CGFloat(CameraFraming.aspectRatio)
                let width = min(geo.size.width, geo.size.height * aspect)
                SpatialPreview(scene: scene, cameraMode: true)
                    .frame(width: width, height: width / aspect)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Illustrative full-frame camera preview")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.metering.unknown").font(.title)
                    Text("Camera framing unavailable").font(.headline)
                    Text("Move the camera away from the subject.").font(.caption)
                }.multilineTextAlignment(.center).padding(24)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var plan: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let bounds = try? StudioSceneBounds(scene: planDrag?.scene ?? scene)
            let fit = bounds?.overheadFit(width: Double(w), height: Double(h), padding: min(48, Double(min(w, h)) * 0.2), minimumSpanMeters: 4)
            let grid = fit?.grid()
            let center = bounds?.center ?? scene.subject
            let scale = CGFloat(fit?.pointsPerMeter ?? 1)
            ZStack {
                Canvas { context, size in
                    // Bounded grid work at every viewport size. Its caption
                    // states the real spacing when a wide rig needs a coarser grid.
                    for worldX in grid?.verticalWorldCoordinates ?? [] {
                        let x = w / 2 + CGFloat(worldX - center.x) * scale
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: h))
                        context.stroke(line, with: .color(.white.opacity(worldX == 0 ? 0.20 : 0.07)), lineWidth: 1)
                    }
                    for worldZ in grid?.horizontalWorldCoordinates ?? [] {
                        let y = h / 2 + CGFloat(worldZ - center.z) * scale
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: w, y: y))
                        context.stroke(line, with: .color(.white.opacity(worldZ == 0 ? 0.20 : 0.07)), lineWidth: 1)
                    }
                    if let framing = CameraFraming(scene: scene) {
                        let origin = point(scene.camera, w, h, scale, center)
                        let half = framing.subjectPlaneWidthMeters / 2
                        let left = Position(x: scene.subject.x - framing.right.x * half,
                                            y: scene.subject.y - framing.right.y * half,
                                            z: scene.subject.z - framing.right.z * half)
                        let right = Position(x: scene.subject.x + framing.right.x * half,
                                             y: scene.subject.y + framing.right.y * half,
                                             z: scene.subject.z + framing.right.z * half)
                        var cone = Path()
                        cone.move(to: origin)
                        cone.addLine(to: point(left, w, h, scale, center))
                        cone.addLine(to: point(right, w, h, scale, center))
                        cone.closeSubpath()
                        context.fill(cone, with: .color(.white.opacity(0.04)))
                        context.stroke(cone, with: .color(.white.opacity(0.45)),
                                       style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    }
                    for light in scene.lights {
                        let origin = point(light.position, w, h, scale, center)
                        let optics = light.effectiveOptics
                        let targetPosition = optics.kind.isAimed ? light.target(subject: scene.subject) : scene.subject
                        let target = point(targetPosition, w, h, scale, center)
                        var line = Path(); line.move(to: origin); line.addLine(to: target)
                        context.stroke(line, with: .color(StudioPalette.planLight.opacity(light.id == selected ? 0.9 : 0.35)),
                                       style: StrokeStyle(lineWidth: 1, dash: optics.kind.isAimed ? [5, 3] : [2, 5]))
                        if optics.kind.isAimed && optics.aimTarget != nil {
                            var cross = Path()
                            cross.move(to: CGPoint(x: target.x - 5, y: target.y))
                            cross.addLine(to: CGPoint(x: target.x + 5, y: target.y))
                            cross.move(to: CGPoint(x: target.x, y: target.y - 5))
                            cross.addLine(to: CGPoint(x: target.x, y: target.y + 5))
                            context.stroke(cross, with: .color(StudioPalette.planLight), lineWidth: 1.5)
                        }
                        if optics.kind == .rectangle, let frame = StudioPhotometry.frame(for: light, subject: scene.subject) {
                            var footprint = Path()
                            for (index, corner) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)].enumerated() {
                                let dx = corner.0 * optics.widthMeters / 2
                                let dy = corner.1 * optics.heightMeters / 2
                                let p = Position(x: light.position.x + frame.right.x * dx + frame.up.x * dy,
                                                 y: light.position.y + frame.right.y * dx + frame.up.y * dy,
                                                 z: light.position.z + frame.right.z * dx + frame.up.z * dy)
                                let projected = point(p, w, h, scale, center)
                                if index == 0 { footprint.move(to: projected) }
                                else { footprint.addLine(to: projected) }
                            }
                            footprint.closeSubpath()
                            context.fill(footprint, with: .color(StudioPalette.planLight.opacity(0.2)))
                            context.stroke(footprint, with: .color(StudioPalette.planLight), lineWidth: 2)
                        }
                    }
                }.accessibilityHidden(true)
                StudioPlanMarkers(markers: planMarkers(width: w, height: h, scale: scale, center: center))
            }
            .preference(key: StudioPlanGridTitleKey.self,
                        value: grid.map { "OVERHEAD / " + PlanUnits.number(displayUnits.fromMeters($0.spacingMeters), decimals: 2) + " " + displayUnits.symbol.uppercased() + " GRID" } ?? "OVERHEAD")
        }
    }

    private func point(_ p: Position, _ w: CGFloat, _ h: CGFloat, _ scale: CGFloat, _ center: Position) -> CGPoint {
        CGPoint(x: w / 2 + CGFloat(p.x - center.x) * scale, y: h / 2 + CGFloat(p.z - center.z) * scale)
    }
    private func lightIcon(_ light: StudioLight) -> String {
        switch light.effectiveOptics.kind {
        case .point: return "lightbulb.fill"
        case .directional: return "flashlight.on.fill"
        case .rectangle: return "rectangle.inset.filled"
        }
    }

    private func lightDisplayName(_ light: StudioLight) -> String {
        let fallback = scene.lights.firstIndex(where: { $0.id == light.id })
            .map { "Light \($0 + 1)" } ?? "Light \(light.id.uuidString.prefix(8))"
        return StudioDisplayName.label(light.name, fallback: fallback)
    }

    private func planMarkers(width: CGFloat, height: CGFloat, scale: CGFloat, center: Position) -> [StudioPlanMarker] {
        let generation = libraryOperation.generation
        var markers = [
            StudioPlanMarker(id: "subject", anchor: point(scene.subject, width, height, scale, center),
                             name: "Subject", icon: "person.fill", color: .white, selected: false,
                             accessibilityLabel: "Edit subject position", accessibilityIdentifier: "editSubject",
                             action: { showSubject = true }),
            StudioPlanMarker(id: "camera", anchor: point(scene.camera, width, height, scale, center),
                             name: "Camera", icon: "camera.fill", color: .white, selected: false,
                             accessibilityLabel: "Edit camera position and lens", accessibilityIdentifier: "editCamera",
                             action: { mode = "Camera" })
        ]
        markers += scene.lights.map { light in
            StudioPlanMarker(id: light.id.uuidString, anchor: point(light.position, width, height, scale, center),
                             name: lightDisplayName(light), icon: lightIcon(light), color: StudioPalette.planLight,
                             selected: selected == light.id,
                             accessibilityLabel: "Select \(lightDisplayName(light)) on plan",
                             action: sceneAction {
                                 guard scene.lights.contains(where: { $0.id == light.id }) else { return }
                                 selected = light.id
                             },
                             onDragChanged: selected == light.id ? { translation in
                                 dragLight(light.id, translation: translation, scale: Double(scale), generation: generation)
                             } : nil,
                             onDragEnded: { finishPlanDrag(lightID: light.id, generation: generation) })
        }
        return markers
    }

    private var meter: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Scope the disclosure identifier to the actual button. Applying it
            // to DisclosureGroup can propagate it into the expanded children.
            Button {
                showMeter.toggle()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Light meter & test card", systemImage: "sun.max")
                            .font(.headline)
                        Text("Ideal direct light · relative color preview")
                            .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: showMeter ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StudioPalette.secondaryText)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Light meter and test card")
            .accessibilityValue(showMeter ? "Expanded" : "Collapsed")
            .accessibilityHint(showMeter ? "Hides light meter controls" : "Shows light meter controls")
            .accessibilityIdentifier("meterDisclosure")
            if showMeter {
                Divider().padding(.vertical, 12)
                let owner = editOwner("preview")
                NeutralCardInspector(scene: scene, settings: previewSettingsBinding,
                                     onEditingChanged: editHandler(owner: owner))
                    .id(owner)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var rack: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Lights").font(.headline)
                Spacer()
                Button(action: sceneAction { addLight() }) {
                    Label("Add light", systemImage: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(scene.lights.count >= 12 || !loaded)
                .accessibilityIdentifier("addLight")
            }
            if scene.lights.isEmpty { Text("Start with one light or choose a recipe.").foregroundStyle(StudioPalette.secondaryText) }
            ForEach(scene.lights) { light in
                Button(action: sceneAction {
                    guard scene.lights.contains(where: { $0.id == light.id }) else { return }
                    selected = light.id
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: lightIcon(light)).foregroundStyle(StudioPalette.selection).frame(width: 36, height: 36)
                            .background(StudioPalette.selection.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lightDisplayName(light)).font(.subheadline.weight(.semibold))
                            Text(light.effectiveOptics.kind.title).font(.caption.weight(.medium))
                            Text("\(displayUnits.fromMeters(light.position.distance(to: scene.subject)), specifier: "%.2f") \(displayUnits.symbol) · \(light.kelvin, specifier: "%.0f") K")
                                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                        }
                        Spacer()
                        Text(StudioMeterReadout.candela(light.candela, locale: locale)).font(.caption.monospacedDigit())
                        Image(systemName: selected == light.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected == light.id ? StudioPalette.selection : StudioPalette.secondaryText)
                    }.padding(8).frame(minHeight: 52)
                        .background(selected == light.id ? StudioPalette.selection.opacity(0.12) : Color(uiColor: .tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).accessibilityIdentifier("light-\(lightDisplayName(light))")
                    .accessibilityAddTraits(selected == light.id ? .isSelected : [])
            }
        }.padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func inspector(_ light: StudioLight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIGHT INSPECTOR").font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(StudioPalette.secondaryText)
                    Text(lightDisplayName(light)).font(.title3.bold())
                }
                Spacer()
                Menu {
                    Button("Rename light", systemImage: "pencil", action: sceneAction {
                        renamingLightID = light.id
                        renameGeneration = libraryOperation.generation
                        lightNameDraft = lightDisplayName(light)
                        lightNameInputTooLong = false
                        showRenameLight = true
                    })
                    Button("Duplicate light", systemImage: "plus.square.on.square",
                           action: sceneAction { duplicateLight(light.id) })
                        .disabled(scene.lights.count >= 12)
                    Button("Set ideal lux", systemImage: "sun.max", action: sceneAction {
                        guard scene.lights.contains(light) else { return }
                        luxTarget = LuxTarget(light: light, scene: scene, generation: libraryOperation.generation)
                    })
                } label: {
                    Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Light actions")
                .accessibilityIdentifier("lightActions")
                Button(role: .destructive, action: sceneAction {
                    removalTarget = RemovalTarget(lightID: light.id, generation: libraryOperation.generation)
                    confirmRemove = true
                }) {
                    Image(systemName: "trash").frame(width: 44, height: 44)
                }.accessibilityLabel("Remove selected light")
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("CAMERA-FACING PLANE · IDEAL").font(.caption2.weight(.medium)).foregroundStyle(StudioPalette.secondaryText)
                if let lux = StudioPhotometry.illuminance(for: light, in: scene) {
                    Text(StudioMeterReadout.lux(lux, locale: locale))
                        .font(.system(.title2, design: .monospaced).weight(.semibold))
                        .accessibilityLabel("Ideal illuminance")
                        .accessibilityValue(StudioNumericInput.formattedValue(lux, unit: "lx", locale: locale))
                        .accessibilityIdentifier("idealLux")
                    Text("Direct incident light at the subject center. Rim lights may read zero on this plane.")
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                } else {
                    Label("Estimate unavailable", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold)).accessibilityIdentifier("idealLux")
                    Text("Check the aim and separation of the emitter, subject and camera. Near-field geometry can fall outside the model.")
                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(StudioPalette.selection.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            let opticsOwner = editOwner("light.\(light.id.uuidString).optics")
            OpticsInspector(optics: opticsBinding(for: light.id), subject: scene.subject,
                            onEditingChanged: editHandler(owner: opticsOwner))
                .id(opticsOwner)
            Divider()
            control("Horizontal", id: light.id, key: \.position.x, range: -4...4, domain: Position.coordinateRange, step: 0.05, unit: "m", fieldID: "lightX")
            control("Depth", id: light.id, key: \.position.z, range: -4...4, domain: Position.coordinateRange, step: 0.05, unit: "m", fieldID: "lightZ")
            control("Height", id: light.id, key: \.position.y, range: 0...4, domain: Position.coordinateRange, step: 0.05, unit: "m", fieldID: "lightY")
            Divider()
            control("Intensity", id: light.id, key: \.candela, range: 0...3000, domain: 0...100_000, step: 25, unit: "cd", fieldID: "lightIntensity")
            control("Temperature", id: light.id, key: \.kelvin, range: 2000...9000, domain: 1000...20_000, step: 100, unit: "K", fieldID: "lightTemperature")
        }.padding(14).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func control(_ title: String, id: UUID, key: WritableKeyPath<StudioLight, Double>,
                         range: ClosedRange<Double>, domain: ClosedRange<Double>,
                         step: Double, unit: String, fieldID: String) -> some View {
        let generation = libraryOperation.generation
        let value = Binding<Double>(
            get: { scene.lights.first(where: { $0.id == id })?[keyPath: key] ?? range.lowerBound },
            set: { new in
                guard libraryOperation.allowsSceneMutation(from: generation),
                      let i = scene.lights.firstIndex(where: { $0.id == id }),
                      new.isFinite, domain.contains(new), new != scene.lights[i][keyPath: key] else { return }
                var next = scene.lights[i]
                next[keyPath: key] = new
                guard next.isValid else { return }
                scene.lights[i] = next
            })
        let bounds = StudioNumericInput.sliderBounds(usual: range, current: value.wrappedValue)
        // Capture this project, light and field identity. A late callback must
        // not consult a newer selected light or project that shares light IDs.
        let owner = editOwner("light.\(id.uuidString).\(fieldID)")
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
        return VStack(alignment: .leading, spacing: 5) {
            layout {
                Text(title).font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if unit == "m" {
                    DistanceValueButton(title: title, id: fieldID, value: value, range: domain).id(owner)
                } else {
                    PrecisionValueButton(title: title, unit: unit, id: fieldID,
                                         value: value, range: domain).id(owner)
                }
            }
            StudioSlider(value: value, in: bounds, step: step,
                         accessibility: .init(label: title,
                                              value: { unit == "m"
                                                  ? DistanceValueButton.formattedValue($0, units: displayUnits, locale: locale)
                                                  : StudioNumericInput.formattedValue($0, unit: unit, locale: locale) },
                                              identifier: fieldID)) { [owner] editing in
                editChanged(editing, owner: owner, generation: generation)
            }
                .id(owner)
        }
    }

    private func opticsBinding(for id: UUID) -> Binding<LightOptics> {
        let generation = libraryOperation.generation
        return Binding(get: { scene.lights.first(where: { $0.id == id })?.effectiveOptics ?? LightOptics() },
                set: { new in
                    guard libraryOperation.allowsSceneMutation(from: generation),
                          new.isValid, let i = scene.lights.firstIndex(where: { $0.id == id }),
                          scene.lights[i].effectiveOptics != new else { return }
                    var next = scene
                    next.lights[i].optics = new
                    scene = next
                })
    }

    private var cameraPositionBinding: Binding<Position> {
        let generation = libraryOperation.generation
        return Binding(get: { scene.camera }, set: { new in
            guard libraryOperation.allowsSceneMutation(from: generation), new.isValid, new != scene.camera else { return }
            scene.camera = new
        })
    }

    private var subjectPositionBinding: Binding<Position> {
        let generation = libraryOperation.generation
        return Binding(get: { scene.subject }, set: { new in
            guard libraryOperation.allowsSceneMutation(from: generation), new.isValid,
                  new != scene.subject else { return }
            scene.subject = new
        })
    }

    private var previewSettingsBinding: Binding<PreviewSettings> {
        let generation = libraryOperation.generation
        return Binding(get: { scene.effectivePreviewSettings }, set: { new in
            guard libraryOperation.allowsSceneMutation(from: generation), new.isValid, new != scene.effectivePreviewSettings else { return }
            var next = scene
            next.previewSettings = new
            scene = next
        })
    }

    private var cameraLensBinding: Binding<CameraLens> {
        let generation = libraryOperation.generation
        return Binding(get: { scene.effectiveCameraLens }, set: { new in
            guard libraryOperation.allowsSceneMutation(from: generation), new.isValid, new != scene.effectiveCameraLens else { return }
            var next = scene
            next.cameraLens = new
            scene = next
        })
    }

    /// Controls retain identity through first save; intentional document
    /// switching resets the scope even when copied rigs share light UUIDs.
    private func editOwner(_ control: String) -> String {
        session.editOwner(control)
    }

    /// The owner is captured while constructing the control, never looked up
    /// from the current selection when an old callback eventually arrives.
    private func editHandler(owner: String) -> (Bool, String) -> Void {
        let generation = libraryOperation.generation
        return { [owner] editing, fieldID in
            editChanged(editing, owner: "\(owner).\(fieldID)", generation: generation)
        }
    }

    private func editChanged(_ editing: Bool, owner: String, generation: UUID) {
        session.editChanged(editing, owner: owner, from: generation)
    }

    private var recipeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipeUsesCurrentPlacement ? "Replace current lights" : "Replace current setup").font(.headline)
                    Toggle("Keep subject and camera placement", isOn: $recipeUsesCurrentPlacement)
                        .accessibilityIdentifier("recipeKeepPlacement")
                    Text(recipeUsesCurrentPlacement
                         ? "Place a starting rig around your subject, facing your camera. Camera settings and measured room stay with the setup. Undo restores the previous lights."
                         : "Start from the recipe's subject, camera and lights. This also resets measured room and preview settings. Undo restores your previous setup.")
                        .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                    if let recipeMessage {
                        Text(recipeMessage).font(.subheadline).foregroundStyle(StudioPalette.destructive)
                            .accessibilityIdentifier("recipeMessage")
                    }
                    ForEach(LightingRecipe.allCases, id: \.self) { recipe in
                        Button(action: sceneAction {
                            do {
                                let next = recipeUsesCurrentPlacement
                                    ? try recipe.scene(applyingTo: scene) : recipe.makeScene()
                                replace(next); recipeMessage = nil; showRecipes = false
                            } catch { recipeMessage = error.localizedDescription }
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(recipe.rawValue).font(.headline).foregroundStyle(.primary)
                                    Text(recipe.detail).font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                                    Text("\(recipe.lightCount) \(recipe.lightCount == 1 ? "light" : "lights")")
                                        .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right").foregroundStyle(StudioPalette.secondaryText)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(recipe.rawValue)
                        .accessibilityHint(recipe.detail + (recipeUsesCurrentPlacement
                            ? " Replaces the lights around your current subject and camera; undo is available."
                            : " Replaces the current setup; undo is available."))
                        .accessibilityIdentifier("recipe-\(recipe.rawValue)")
                    }
                    Text(LightingRecipe.threePoint.assumptions)
                        .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                }
                .padding(16).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Lighting recipes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { recipeMessage = nil }
            .onChange(of: recipeUsesCurrentPlacement) { _, _ in recipeMessage = nil }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showRecipes = false }.accessibilityIdentifier("closeRecipes")
                }
            }
        }
    }

    private var exportText: String? {
        (try? LightingPlan(scene: scene, title: projectName, units: displayUnits))?.plainText
    }

    /// Capture the editor generation while creating each action. Disabling a
    /// control cannot alone reject callbacks already queued by an older view.
    private func sceneAction(_ action: @escaping () -> Void) -> () -> Void {
        let generation = libraryOperation.generation
        return {
            guard libraryOperation.allowsSceneMutation(from: generation) else { return }
            action()
        }
    }

    private func sceneContext() -> SceneContext {
        finishPlanDrag()
        session.endEditing()
        return SceneContext(scene: scene, generation: libraryOperation.generation)
    }

    private func acceptsSceneResult(from context: SceneContext) -> Bool {
        guard libraryOperation.allowsSceneMutation(from: context.generation) else { return false }
        guard scene == context.scene else {
            message = "The setup changed while this editor was open. Reopen it to apply changes to the current setup."
            return false
        }
        return true
    }

    private func roomPresentationBinding(for context: SceneContext, isAR: Bool = false) -> Binding<Bool> {
        Binding(get: {
            isAR ? (showARPlacement && arContext?.owner == context.owner)
                : (showRoomPlacement && roomContext?.owner == context.owner)
        }, set: { presented in
            // A delayed dismissal belongs only to its original presentation.
            if isAR {
                guard arContext?.owner == context.owner else { return }
                showARPlacement = presented
            } else {
                guard roomContext?.owner == context.owner else { return }
                showRoomPlacement = presented
            }
        })
    }

    private func retireRoomPresentation(_ context: SceneContext) {
        if roomContext?.owner == context.owner { showRoomPlacement = false }
        if arContext?.owner == context.owner { showARPlacement = false }
    }

    private func acceptsRoomResult(from context: SceneContext) -> Bool {
        guard libraryOperation.allowsSceneMutation(from: context.generation),
              (showRoomPlacement && roomContext?.owner == context.owner)
                || (showARPlacement && arContext?.owner == context.owner) else { return false }
        // Repeated room changes belong to this presentation; other rig edits
        // invalidate its snapshot even if the project generation is unchanged.
        var current = scene
        current.placementRoom = context.scene.placementRoom
        return current == context.scene
    }

    private func applyRoom(_ room: ManualRoom, from context: SceneContext) -> Bool {
        guard room.isValid, acceptsRoomResult(from: context) else { return false }
        guard room != scene.placementRoom else { return true }
        session.editChanged(true, owner: context.owner, from: context.generation)
        scene.placementRoom = room
        return true
    }

    private func finishRoomEditing(_ context: SceneContext?) {
        guard let context else { return }
        session.endEditing(owner: context.owner)
        if roomContext?.owner == context.owner {
            showRoomPlacement = false
            roomContext = nil
        }
        if arContext?.owner == context.owner {
            showARPlacement = false
            arContext = nil
        }
    }

    private func removeRoom(from context: SceneContext) -> Bool {
        guard acceptsRoomResult(from: context) else { return false }
        guard scene.placementRoom != nil else { return true }
        session.editChanged(true, owner: context.owner, from: context.generation)
        scene.placementRoom = nil
        return true
    }

    private func dismissSceneEditors() {
        showRoomPlacement = false
        showSubject = false
        showARPlacement = false
        showRecipes = false
        showRenameLight = false
        confirmRemove = false
        renamingLightID = nil
        renameGeneration = nil
        removalTarget = nil
        luxTarget = nil
        referenceContext = nil
        roomContext = nil
        arrangementContext = nil
        arContext = nil
    }

    private func replace(_ next: LightingScene) {
        session.replace(next, from: session.generation)
    }
    private func undo() {
        guard planDrag == nil else { return }
        session.undo(from: session.generation)
    }
    private func redo() {
        guard planDrag == nil else { return }
        session.redo(from: session.generation)
    }
    private func addLight() {
        guard !libraryOperation.isBusy, scene.lights.count < 12 else { return }
        do {
            let next = try SceneLightCreation.addingLight(to: scene)
            replace(next)
            selected = next.lights.last?.id
        } catch {
            message = error.localizedDescription
        }
    }

    private func isValidLightName(_ value: String) -> Bool {
        (try? StudioDisplayName.newInput(value)) != nil
    }

    private var boundedLightNameDraft: Binding<String> {
        Binding(get: { lightNameDraft }, set: { replacement in
            guard replacement.unicodeScalars.prefix(StudioDisplayName.maximumScalars + 1).count
                    <= StudioDisplayName.maximumScalars else {
                lightNameInputTooLong = true
                return
            }
            guard replacement != lightNameDraft else { return }
            lightNameDraft = replacement
            lightNameInputTooLong = false
        })
    }

    private func renameSelectedLight() {
        guard !lightNameInputTooLong, let id = renamingLightID,
              let name = try? StudioDisplayName.newInput(lightNameDraft),
              renameGeneration == libraryOperation.generation,
              let index = scene.lights.firstIndex(where: { $0.id == id }) else { return }
        var next = scene
        next.lights[index].name = name
        replace(next)
        renamingLightID = nil
    }

    private func duplicateLight(_ id: UUID) {
        guard scene.lights.count < 12, let original = scene.lights.first(where: { $0.id == id }) else { return }
        var copy = original
        copy.id = UUID()
        var stem = StudioDisplayName.display(lightDisplayName(original), maximumCharacters: 65)
        var number = 1
        repeat {
            let suffix = number == 1 ? " copy" : " copy \(number)"
            // Leave room for the suffix under the scalar and byte limits too;
            // one imported grapheme can contain hundreds of combining marks.
            while !stem.isEmpty && (try? StudioDisplayName.newInput(stem + suffix)) == nil {
                stem.removeLast()
            }
            copy.name = (stem.isEmpty ? "Light" : stem) + suffix
            number += 1
        } while scene.lights.contains(where: { $0.name == copy.name })
        // Preserve exact equipment geometry; duplicating never silently moves a rig.
        var next = scene
        next.lights.append(copy)
        replace(next)
        selected = copy.id
    }

    private func dragLight(_ id: UUID, translation: CGSize, scale: Double, generation: UUID) {
        session.dragLight(id, translationX: Double(translation.width),
                          translationZ: Double(translation.height), scale: scale, from: generation)
    }

    private func finishPlanDrag(lightID: UUID? = nil, generation: UUID? = nil) {
        session.finishPlanDrag(lightID: lightID, generation: generation)
    }
    private func load(from generation: UUID) {
        guard !libraryOperation.isBusy else { return }
        do { _ = try beginLibraryOperation(.load, from: generation) }
        catch { message = error.localizedDescription }
    }

    private func persistScene(from generation: UUID) throws -> Task<Void, Error> {
        try beginLibraryOperation(.save, from: generation)
    }

    private func applyLibrary(_ command: ProjectLibraryCommand, from generation: UUID) throws -> Task<Void, Error> {
        try session.applyLibrary(command, from: generation)
    }

    private func beginLibraryOperation(_ operation: ProjectLibraryOperation,
                                       from generation: UUID) throws -> Task<Void, Error> {
        try session.beginLibraryOperation(operation, from: generation)
    }

    private func saveConflictCopy(from generation: UUID) {
        guard saveConflict, loaded, !saveBlocked else { return }
        do { _ = try beginLibraryOperation(.recover(name: recoveryProjectName, replacing: nil), from: generation) }
        catch { message = error.localizedDescription }
    }

    private var recoveryProjectName: String { session.recoveryProjectName }

    private func reloadAfterConflict(from generation: UUID) {
        guard saveConflict, loaded, !saveBlocked else { return }
        do { _ = try beginLibraryOperation(.reload, from: generation) }
        catch { message = error.localizedDescription }
    }

    private func save(from generation: UUID) {
        do { _ = try persistScene(from: generation) }
        catch { message = error.localizedDescription }
    }
}
