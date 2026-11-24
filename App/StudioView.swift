import SwiftUI
import LightingCore

struct StudioView: View {
    @State private var scene = LightingScene.portrait()
    @State private var selected: UUID?
    @State private var saved: LightingScene?
    @State private var library: ProjectLibrary?
    @State private var showProjects = false
    @State private var showReference = false
    @State private var showRoomPlacement = false
    @State private var history: [LightingScene] = []
    @State private var future: [LightingScene] = []
    @State private var editStart: LightingScene?
    @State private var mode = "Plan"
    @State private var showRecipes = false
    @State private var showMeter = false
    @State private var meterNavigationRequest = 0
    @State private var confirmRemove = false
    @State private var loaded = false
    @State private var saveBlocked = false
    @State private var message: String?
    @State private var saveConflict = false
    @State private var confirmReloadConflict = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let store = ProjectStore()
    private let amber = Color(red: 0.96, green: 0.65, blue: 0.30)
    private let charcoal = Color(red: 0.075, green: 0.085, blue: 0.10)

    var body: some View {
        NavigationStack {
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
                                Button("Retry loading saved project") { load() }
                                    .buttonStyle(.borderedProminent)
                            }
                        } else if !loaded {
                            ProgressView("Opening projects…")
                                .frame(maxWidth: .infinity, minHeight: 160)
                        } else {
                            if saveConflict { conflictRecoveryPanel }
                            workflowActions
                            workspace
                            meter.id("meterPanel")
                            rack
                            if let light = scene.lights.first(where: { $0.id == selected }) {
                                inspector(light)
                            } else {
                                ContentUnavailableView("No light selected", systemImage: "lightbulb",
                                    description: Text("Add a light or choose a recipe."))
                            }
                            Text("Illustrative 3D shading. Lux estimates describe an ideal camera-facing plane, not measured skin exposure or a calibrated fixture.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        if let message, !saveConflict { Text(message).font(.footnote).accessibilityIdentifier("saveMessage") }
                    }
                    .padding(16).frame(maxWidth: 820).frame(maxWidth: .infinity)
                }
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if loaded && !saveBlocked {
                    HStack(spacing: 12) {
                        Text("Edit history").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button { undo() } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward").labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(history.isEmpty).accessibilityLabel("Undo").accessibilityIdentifier("undo")
                        Button { redo() } label: {
                            Label("Redo", systemImage: "arrow.uturn.forward").labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(future.isEmpty).accessibilityLabel("Redo").accessibilityIdentifier("redo")
                    }
                    .padding(.horizontal, 16).background(.bar)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Key & Fill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Recipes", systemImage: "square.stack") { showRecipes = true }
                        .disabled(!loaded || saveBlocked).accessibilityIdentifier("recipes")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                        .disabled(!loaded || saveBlocked).accessibilityIdentifier("saveProject")
                }
            }
            .sheet(isPresented: $showRecipes) { recipeSheet }
            .sheet(isPresented: $showReference) { ReferenceComparisonView(scene: scene) { rig in
                replace(rig); mode = "Study"
            } }
            .sheet(isPresented: $showRoomPlacement) {
                ManualRoomPlacementView(scene: scene)
            }
            .sheet(isPresented: $showProjects) {
                ProjectLibraryView(library: $library, scene: $scene, saved: $saved,
                                   onSave: persistScene, onApply: applyLibrary)
            }
            .confirmationDialog("Remove selected light?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove light", role: .destructive) {
                    var next = scene; next.lights.removeAll { $0.id == selected }; replace(next)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Reload saved project?", isPresented: $confirmReloadConflict) {
                Button("Keep editing", role: .cancel) {}
                Button("Reload and discard edits", role: .destructive) { reloadAfterConflict() }
            } message: {
                Text("Only the unsaved changes in this window will be discarded. The latest saved library will be opened.")
            }
            .task { if !loaded { load() } }
        }
    }

    private var projectName: String { library?.activeProject?.name ?? "Portrait setup" }

    // Keep the editing canvas above the fold on compact phones. Fall back to
    // two rows for long names, narrow widths and accessibility text sizes.
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
                        projectActions
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
            Text("LIGHTING STUDIO").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
            Text(saveBlocked ? "Project unavailable" : projectName)
                .font(.title2.bold())
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .accessibilityIdentifier("projectName")
            Text(saveBlocked ? "Saved data protected" : (saved == scene ? "Saved locally" : "Unsaved changes"))
                .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("projectStatus")
        }
    }

    private var projectActions: some View {
        HStack(spacing: 8) {
            Button { showProjects = true } label: {
                Label("Projects", systemImage: "folder")
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(!loaded || saveBlocked).accessibilityIdentifier("openProjectLibrary")
            LightingPlanExportMenu(scene: scene, title: projectName, textSettings: exportText)
                .disabled(!loaded || saveBlocked)
        }
    }

    private var conflictRecoveryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Saved library changed", systemImage: "exclamationmark.circle").font(.headline)
            Text("Your setup is still in this window. Save a separate project to preserve it without replacing the newer saved version, or reload the latest library.").font(.subheadline)
            Button { saveConflictCopy() } label: {
                Label("Save setup as new project", systemImage: "plus.square.on.square")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("saveConflictCopy")
            Button("Reload latest saved library") { confirmReloadConflict = true }
                .frame(minHeight: 44).accessibilityIdentifier("reloadConflict")
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
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
            Button { showReference = true } label: {
                Label("Reference photo", systemImage: "rectangle.split.2x1")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Compare reference photo")
            .accessibilityIdentifier("openReference")
            Button { showRoomPlacement = true } label: {
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
        VStack(spacing: 10) {
            HStack {
                Label("Scene", systemImage: "viewfinder").font(.headline)
                Spacer(minLength: 8)
                Button {
                    showMeter = true
                    meterNavigationRequest += 1
                } label: {
                    Label("Meter", systemImage: "light.metering.center.weighted")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 8)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel("Open light meter and test card")
                .accessibilityHint("Opens and scrolls to the meter controls")
                .accessibilityIdentifier("openMeter")
                Button { addLight() } label: {
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
            Picker("View", selection: $mode) {
                Text("Plan").tag("Plan")
                Text("3D").tag("3D")
                Text("Camera").tag("Camera")
                Text("Study").tag("Study")
            }.pickerStyle(.segmented).accessibilityIdentifier("viewMode")
            ZStack(alignment: .topLeading) {
                charcoal
                if mode == "Plan" { plan }
                else if mode == "Camera" { cameraPreview }
                else if mode == "Study" { ReferenceStudyPreview(scene: scene) }
                else { SpatialPreview(scene: scene).accessibilityLabel("Illustrative 3D lighting preview") }
                Text(mode == "Plan" ? "OVERHEAD / 1 M GRID" : mode == "Camera" ? "CAMERA / 3:2" : mode == "Study" ? "LIGHT STUDY / DIRECT ONLY" : "3D / DRAG TO ORBIT")
                    .font(.caption2.monospaced().weight(.medium)).foregroundStyle(.white.opacity(0.75))
                    .padding(10).allowsHitTesting(false)
            }
            .frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 16))
            HStack {
                Label("\(scene.lights.count) lights", systemImage: "lightbulb")
                Spacer()
                Text("Meters · cd · K").monospaced()
            }.font(.caption).foregroundStyle(.secondary)
            if mode == "Study" {
                Text("Neutral sphere and panel · direct light, finite-source shadows and relative color. Not a portrait or calibrated exposure.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if mode == "Camera" || mode == "Study" {
                Divider()
                CameraInspector(position: cameraPositionBinding, lens: cameraLensBinding,
                                subject: scene.subject, onEditingChanged: editChanged)
            }
        }.padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
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
            let targets = scene.lights.filter { $0.effectiveOptics.kind.isAimed }.map { $0.target(subject: scene.subject) }
            let positions = [scene.subject, scene.camera] + scene.lights.map(\.position) + targets
            let extent = max(4.0, (positions.map { max(abs($0.x), abs($0.z)) }.max() ?? 4) + 1)
            let scale = min(w, h) / CGFloat(extent * 2 + 2)
            ZStack {
                Canvas { context, size in
                    let radius = min(100, Int(ceil(extent)))
                    for n in -radius...radius {
                        let offset = CGFloat(n) * scale
                        var grid = Path()
                        grid.move(to: CGPoint(x: w / 2 + offset, y: 0))
                        grid.addLine(to: CGPoint(x: w / 2 + offset, y: h))
                        grid.move(to: CGPoint(x: 0, y: h / 2 + offset))
                        grid.addLine(to: CGPoint(x: w, y: h / 2 + offset))
                        context.stroke(grid, with: .color(.white.opacity(n == 0 ? 0.20 : 0.07)), lineWidth: 1)
                    }
                    if let framing = CameraFraming(scene: scene) {
                        let origin = point(scene.camera, w, h, scale)
                        let half = framing.subjectPlaneWidthMeters / 2
                        let left = Position(x: scene.subject.x - framing.right.x * half,
                                            y: scene.subject.y - framing.right.y * half,
                                            z: scene.subject.z - framing.right.z * half)
                        let right = Position(x: scene.subject.x + framing.right.x * half,
                                             y: scene.subject.y + framing.right.y * half,
                                             z: scene.subject.z + framing.right.z * half)
                        var cone = Path()
                        cone.move(to: origin)
                        cone.addLine(to: point(left, w, h, scale))
                        cone.addLine(to: point(right, w, h, scale))
                        cone.closeSubpath()
                        context.fill(cone, with: .color(.white.opacity(0.04)))
                        context.stroke(cone, with: .color(.white.opacity(0.45)),
                                       style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    }
                    for light in scene.lights {
                        let origin = point(light.position, w, h, scale)
                        let optics = light.effectiveOptics
                        let targetPosition = optics.kind.isAimed ? light.target(subject: scene.subject) : scene.subject
                        let target = point(targetPosition, w, h, scale)
                        var line = Path(); line.move(to: origin); line.addLine(to: target)
                        context.stroke(line, with: .color(amber.opacity(light.id == selected ? 0.9 : 0.35)),
                                       style: StrokeStyle(lineWidth: 1, dash: optics.kind.isAimed ? [5, 3] : [2, 5]))
                        if optics.kind.isAimed && optics.aimTarget != nil {
                            var cross = Path()
                            cross.move(to: CGPoint(x: target.x - 5, y: target.y))
                            cross.addLine(to: CGPoint(x: target.x + 5, y: target.y))
                            cross.move(to: CGPoint(x: target.x, y: target.y - 5))
                            cross.addLine(to: CGPoint(x: target.x, y: target.y + 5))
                            context.stroke(cross, with: .color(amber), lineWidth: 1.5)
                        }
                        if optics.kind == .rectangle, let frame = StudioPhotometry.frame(for: light, subject: scene.subject) {
                            var footprint = Path()
                            for (index, corner) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)].enumerated() {
                                let dx = corner.0 * optics.widthMeters / 2
                                let dy = corner.1 * optics.heightMeters / 2
                                let p = Position(x: light.position.x + frame.right.x * dx + frame.up.x * dy,
                                                 y: light.position.y + frame.right.y * dx + frame.up.y * dy,
                                                 z: light.position.z + frame.right.z * dx + frame.up.z * dy)
                                let projected = point(p, w, h, scale)
                                if index == 0 { footprint.move(to: projected) }
                                else { footprint.addLine(to: projected) }
                            }
                            footprint.closeSubpath()
                            context.fill(footprint, with: .color(amber.opacity(0.2)))
                            context.stroke(footprint, with: .color(amber), lineWidth: 2)
                        }
                    }
                }.accessibilityHidden(true)
                marker("Subject", icon: "person.fill", color: .white, active: false)
                    .position(point(scene.subject, w, h, scale))
                Button { mode = "Camera" } label: {
                    marker("Camera", icon: "camera.fill", color: .white, active: false)
                }.buttonStyle(.plain).accessibilityLabel("Edit camera position and lens")
                    .accessibilityIdentifier("editCamera")
                    .position(point(scene.camera, w, h, scale))
                ForEach(scene.lights) { light in
                    Button { selected = light.id } label: {
                        marker(light.name, icon: lightIcon(light), color: amber, active: selected == light.id)
                    }.buttonStyle(.plain)
                        .accessibilityLabel("Select \(light.name) on plan")
                        .accessibilityAddTraits(selected == light.id ? .isSelected : [])
                        .position(point(light.position, w, h, scale))
                }
            }
        }
    }

    private func point(_ p: Position, _ w: CGFloat, _ h: CGFloat, _ scale: CGFloat) -> CGPoint {
        CGPoint(x: w / 2 + CGFloat(p.x) * scale, y: h / 2 + CGFloat(p.z) * scale)
    }
    private func lightIcon(_ light: StudioLight) -> String {
        switch light.effectiveOptics.kind {
        case .point: return "lightbulb.fill"
        case .directional: return "flashlight.on.fill"
        case .rectangle: return "rectangle.inset.filled"
        }
    }

    private func marker(_ name: String, icon: String, color: Color, active: Bool) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 17, weight: .medium)).foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(active ? amber.opacity(0.25) : Color.black.opacity(0.65), in: Circle())
                .overlay { Circle().strokeBorder(color.opacity(active ? 1 : 0.45), lineWidth: active ? 2 : 1) }
            Text(name).font(.caption2.weight(.semibold)).lineLimit(1).foregroundStyle(.white)
                .padding(.horizontal, 4).background(.black.opacity(0.7), in: Capsule())
        }.frame(minWidth: 44, minHeight: 44)
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
                        Label("Light meter & test card", systemImage: "light.metering.center.weighted")
                            .font(.headline)
                        Text("Ideal direct light · relative color preview")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: showMeter ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
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
                NeutralCardInspector(scene: scene, settings: previewSettingsBinding,
                                     onEditingChanged: editChanged)
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
                Button { addLight() } label: {
                    Label("Add light", systemImage: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(scene.lights.count >= 12 || !loaded)
                .accessibilityIdentifier("addLight")
            }
            if scene.lights.isEmpty { Text("Start with one light or choose a recipe.").foregroundStyle(.secondary) }
            ForEach(scene.lights) { light in
                Button { selected = light.id } label: {
                    HStack(spacing: 12) {
                        Image(systemName: lightIcon(light)).foregroundStyle(amber).frame(width: 36, height: 36)
                            .background(amber.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(light.name).font(.subheadline.weight(.semibold))
                            Text(light.effectiveOptics.kind.title).font(.caption.weight(.medium))
                            Text("\(light.position.distance(to: scene.subject), specifier: "%.2f") m · \(light.kelvin, specifier: "%.0f") K")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(light.candela, specifier: "%.0f") cd").font(.caption.monospacedDigit())
                        Image(systemName: selected == light.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected == light.id ? amber : Color.secondary)
                    }.padding(8).frame(minHeight: 52)
                        .background(selected == light.id ? amber.opacity(0.12) : Color(uiColor: .tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).accessibilityIdentifier("light-\(light.name)")
                    .accessibilityAddTraits(selected == light.id ? .isSelected : [])
            }
        }.padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func inspector(_ light: StudioLight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIGHT INSPECTOR").font(.caption2.weight(.semibold)).tracking(1.4).foregroundStyle(.secondary)
                    Text(light.name).font(.title3.bold())
                }
                Spacer()
                Button(role: .destructive) { confirmRemove = true } label: {
                    Image(systemName: "trash").frame(width: 44, height: 44)
                }.accessibilityLabel("Remove selected light")
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("CAMERA-FACING PLANE · IDEAL").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                if let lux = StudioPhotometry.illuminance(for: light, in: scene) {
                    Text("\(lux, specifier: "%.1f") lx")
                        .font(.system(.title2, design: .monospaced).weight(.semibold))
                        .accessibilityIdentifier("idealLux")
                    Text("Direct incident light at the subject center. Rim lights may read zero on this plane.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Label("Estimate unavailable", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold)).accessibilityIdentifier("idealLux")
                    Text("Check the aim and separation of the emitter, subject and camera. Near-field geometry can fall outside the model.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            OpticsInspector(optics: opticsBinding(for: light.id), subject: scene.subject, onEditingChanged: editChanged)
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
        let value = Binding<Double>(
            get: { scene.lights.first(where: { $0.id == id })?[keyPath: key] ?? range.lowerBound },
            set: { new in
                guard let i = scene.lights.firstIndex(where: { $0.id == id }),
                      new.isFinite, domain.contains(new), new != scene.lights[i][keyPath: key] else { return }
                var next = scene.lights[i]
                next[keyPath: key] = new
                guard next.isValid else { return }
                if editStart == nil { remember(scene) }
                scene.lights[i] = next
            })
        let bounds = StudioNumericInput.sliderBounds(usual: range, current: value.wrappedValue)
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                PrecisionValueButton(title: title, unit: unit, id: fieldID,
                                     value: value, range: domain)
                    .id(id)
            }
            Slider(value: value, in: bounds, step: step, onEditingChanged: editChanged)
                .accessibilityLabel(title)
                .accessibilityValue(value.wrappedValue.formatted(.number.precision(.fractionLength(0...6)).grouping(.never)) + " " + unit)
                .accessibilityIdentifier(fieldID)
        }
    }

    private func opticsBinding(for id: UUID) -> Binding<LightOptics> {
        Binding(get: { scene.lights.first(where: { $0.id == id })?.effectiveOptics ?? LightOptics() },
                set: { new in
                    guard new.isValid, let i = scene.lights.firstIndex(where: { $0.id == id }),
                          scene.lights[i].effectiveOptics != new else { return }
                    if editStart == nil { remember(scene) }
                    scene.lights[i].optics = new
                })
    }

    private var cameraPositionBinding: Binding<Position> {
        Binding(get: { scene.camera }, set: { new in
            guard new.isValid, new != scene.camera else { return }
            if editStart == nil { remember(scene) }
            scene.camera = new
        })
    }

    private var previewSettingsBinding: Binding<PreviewSettings> {
        Binding(get: { scene.effectivePreviewSettings }, set: { new in
            guard new.isValid, new != scene.effectivePreviewSettings else { return }
            if editStart == nil { remember(scene) }
            scene.previewSettings = new
        })
    }

    private var cameraLensBinding: Binding<CameraLens> {
        Binding(get: { scene.effectiveCameraLens }, set: { new in
            guard new.isValid, new != scene.effectiveCameraLens else { return }
            if editStart == nil { remember(scene) }
            scene.cameraLens = new
        })
    }

    private func editChanged(_ editing: Bool) {
        if editing {
            if editStart == nil { editStart = scene }
        } else {
            if let start = editStart, start != scene { remember(start) }
            editStart = nil
        }
    }

    private var recipeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Replace current setup").font(.headline)
                    Text("Choose a starting rig. Undo restores your previous setup.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ForEach(LightingRecipe.allCases, id: \.self) { recipe in
                        Button {
                            replace(recipe.makeScene()); showRecipes = false
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(recipe.rawValue).font(.headline).foregroundStyle(.primary)
                                    Text(recipe.detail).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(recipe.rawValue)
                        .accessibilityHint(recipe.detail + " Replaces the current setup; undo is available.")
                        .accessibilityIdentifier("recipe-\(recipe.rawValue)")
                    }
                }
                .padding(16).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Lighting recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showRecipes = false }.accessibilityIdentifier("closeRecipes")
                }
            }
        }
    }

    private var exportText: String? {
        (try? LightingPlan(scene: scene, title: projectName))?.plainText
    }
    private func remember(_ previous: LightingScene) {
        if history.last != previous { history.append(previous) }
        if history.count > 60 { history.removeFirst() }
        future.removeAll()
    }
    private func replace(_ next: LightingScene) {
        guard next != scene else { return }
        remember(scene); scene = next; repairSelection()
    }
    private func repairSelection() {
        if !scene.lights.contains(where: { $0.id == selected }) { selected = scene.lights.first?.id }
    }
    private func undo() {
        guard let previous = history.popLast() else { return }
        future.append(scene); scene = previous; repairSelection()
    }
    private func redo() {
        guard let next = future.popLast() else { return }
        history.append(scene); scene = next; repairSelection()
    }
    private func addLight() {
        guard scene.lights.count < 12 else { return }
        var next = scene
        var n = 1
        while next.lights.contains(where: { $0.name == "Light \(n)" }) { n += 1 }
        let light = StudioLight(name: "Light \(n)", position: .init(x: 1, y: 2, z: 1), candela: 500, kelvin: 5600)
        next.lights.append(light); replace(next); selected = light.id
    }
    private func load() {
        do {
            library = try store.load()
            if let stored = library?.activeProject?.scene { scene = stored; saved = stored }
            else { saved = nil }
            history.removeAll(); future.removeAll(); selected = scene.lights.first?.id
            saveBlocked = false; loaded = true; saveConflict = false; message = nil
        } catch {
            saveBlocked = true; loaded = true
            message = "Saved project could not be opened. Saving is disabled to protect existing data."
        }
    }
    private func persistScene() throws {
        guard loaded, !saveBlocked else { throw ProjectLibraryError.invalidLibrary }
        var next: ProjectLibrary
        if let library { next = library }
        else { next = try ProjectLibrary(name: "Portrait setup", scene: scene) }
        try next.updateActiveScene(scene)
        try saveLibrarySnapshot(next)
        library = next; saved = scene
        message = "Project saved on this device."
    }

    private func applyLibrary(_ next: ProjectLibrary) throws {
        guard loaded, !saveBlocked, saved == scene, let active = next.activeProject else {
            throw ProjectLibraryError.staleSnapshot
        }
        let switching = next.activeID != library?.activeID
        try saveLibrarySnapshot(next)
        library = next
        if switching {
            scene = active.scene; saved = active.scene
            history.removeAll(); future.removeAll(); editStart = nil
            selected = scene.lights.first?.id
            mode = "Plan"; showMeter = false
        }
        message = nil
    }

    private func saveLibrarySnapshot(_ next: ProjectLibrary) throws {
        do {
            try store.save(next, replacing: library)
            saveConflict = false
        } catch {
            if (error as? ProjectLibraryError) == .staleSnapshot {
                saveConflict = true
                message = "The newer saved library was not overwritten."
            }
            throw error
        }
    }

    private func saveConflictCopy() {
        guard saveConflict, loaded, !saveBlocked else { return }
        let suffix = " recovery"
        let name = String(projectName.prefix(ProjectLibrary.maximumNameLength - suffix.count)) + suffix
        do {
            let latest = try store.saveRecoveryCopy(name: name, scene: scene)
            adoptRecoveredLibrary(latest)
            message = "Your setup was saved as a separate project."
        } catch {
            message = "Could not save a recovery copy. Your edits remain in this window. \(error.localizedDescription)"
        }
    }

    private func reloadAfterConflict() {
        guard saveConflict, loaded, !saveBlocked else { return }
        do {
            guard let latest = try store.load(), latest.activeProject != nil else {
                throw ProjectLibraryError.invalidLibrary
            }
            adoptRecoveredLibrary(latest)
            message = "Latest saved library opened."
        } catch {
            message = "Could not reload. Your edits remain in this window. \(error.localizedDescription)"
        }
    }

    private func adoptRecoveredLibrary(_ latest: ProjectLibrary) {
        guard let active = latest.activeProject else { return }
        library = latest; scene = active.scene; saved = active.scene
        history.removeAll(); future.removeAll(); editStart = nil
        selected = scene.lights.first?.id
        mode = "Plan"; showMeter = false; saveConflict = false
    }

    private func save() {
        do { try persistScene() }
        catch { message = "Could not save the project. Your edits remain in this session. \(error.localizedDescription)" }
    }
}
