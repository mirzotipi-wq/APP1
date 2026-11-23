import SwiftUI
import LightingCore

struct StudioView: View {
    @State private var scene = LightingScene.portrait()
    @State private var selected: UUID?
    @State private var saved: LightingScene?
    @State private var history: [LightingScene] = []
    @State private var future: [LightingScene] = []
    @State private var editStart: LightingScene?
    @State private var mode = "Plan"
    @State private var showRecipes = false
    @State private var confirmRemove = false
    @State private var loaded = false
    @State private var saveBlocked = false
    @State private var message: String?
    private let store = ProjectStore()
    private let amber = Color(red: 0.96, green: 0.65, blue: 0.30)
    private let charcoal = Color(red: 0.075, green: 0.085, blue: 0.10)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    workspace
                    rack
                    if let light = scene.lights.first(where: { $0.id == selected }) {
                        inspector(light)
                    } else {
                        ContentUnavailableView("No light selected", systemImage: "lightbulb",
                            description: Text("Add a light or choose a recipe."))
                    }
                    Text("Illustrative preview. Illuminance is an ideal point-source estimate, not a calibrated measurement.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let message { Text(message).font(.footnote).accessibilityIdentifier("saveMessage") }
                    if saveBlocked { Button("Retry loading saved project") { load() } }
                }
                .padding(16).frame(maxWidth: 820).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Key & Fill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Recipes", systemImage: "square.stack") { showRecipes = true }
                        .disabled(!loaded).accessibilityIdentifier("recipes")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                        .disabled(!loaded || saveBlocked).accessibilityIdentifier("saveProject")
                }
            }
            .sheet(isPresented: $showRecipes) { recipeSheet }
            .confirmationDialog("Remove selected light?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove light", role: .destructive) {
                    var next = scene; next.lights.removeAll { $0.id == selected }; replace(next)
                }
                Button("Cancel", role: .cancel) {}
            }
            .task { if !loaded { load() } }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LIGHTING STUDIO").font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                Text("Portrait setup").font(.title2.bold())
                Text(saveBlocked ? "Saved data protected" : (saved == scene ? "Saved locally" : "Unsaved changes"))
                    .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("projectStatus")
            }
            Spacer()
            ShareLink(item: exportText) {
                Image(systemName: "square.and.arrow.up").font(.headline).frame(width: 44, height: 44)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }.accessibilityLabel("Share lighting settings").disabled(!loaded)
        }
    }

    private var workspace: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Scene", systemImage: "viewfinder").font(.headline)
                Spacer()
                Button { undo() } label: { Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44) }
                    .disabled(history.isEmpty).accessibilityLabel("Undo").accessibilityIdentifier("undo")
                Button { redo() } label: { Image(systemName: "arrow.uturn.forward").frame(width: 44, height: 44) }
                    .disabled(future.isEmpty).accessibilityLabel("Redo").accessibilityIdentifier("redo")
            }
            Picker("View", selection: $mode) {
                Text("Plan").tag("Plan")
                Text("3D").tag("3D")
            }.pickerStyle(.segmented)
            ZStack(alignment: .topLeading) {
                charcoal
                if mode == "Plan" { plan }
                else { SpatialPreview(scene: scene).accessibilityLabel("Illustrative 3D lighting preview") }
                Text(mode == "Plan" ? "OVERHEAD / 1 M GRID" : "3D / DRAG TO ORBIT")
                    .font(.caption2.monospaced().weight(.medium)).foregroundStyle(.white.opacity(0.75))
                    .padding(10).allowsHitTesting(false)
            }
            .frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 16))
            HStack {
                Label("\(scene.lights.count) lights", systemImage: "lightbulb")
                Spacer()
                Text("Meters · cd · K").monospaced()
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var plan: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let extent = max(4.0, ([scene.subject, scene.camera] + scene.lights.map(\.position)).map { max(abs($0.x), abs($0.z)) }.max() ?? 4)
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
                    for light in scene.lights {
                        let origin = point(light.position, w, h, scale)
                        let target = point(scene.subject, w, h, scale)
                        var beam = Path()
                        beam.move(to: origin)
                        beam.addLine(to: CGPoint(x: target.x - 9, y: target.y - 9))
                        beam.addLine(to: CGPoint(x: target.x + 9, y: target.y + 9))
                        beam.closeSubpath()
                        context.fill(beam, with: .color(amber.opacity(light.id == selected ? 0.22 : 0.07)))
                        var line = Path(); line.move(to: origin); line.addLine(to: target)
                        context.stroke(line, with: .color(amber.opacity(light.id == selected ? 0.9 : 0.35)),
                                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }.accessibilityHidden(true)
                marker("Subject", icon: "person.fill", color: .white, active: false)
                    .position(point(scene.subject, w, h, scale))
                marker("Camera", icon: "camera.fill", color: .white, active: false)
                    .position(point(scene.camera, w, h, scale))
                ForEach(scene.lights) { light in
                    Button { selected = light.id } label: {
                        marker(light.name, icon: "lightbulb.fill", color: amber, active: selected == light.id)
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

    private var rack: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Lights").font(.headline)
                Spacer()
                Button("Add light", systemImage: "plus") { addLight() }
                    .disabled(scene.lights.count >= 12 || !loaded).accessibilityIdentifier("addLight")
            }
            if scene.lights.isEmpty { Text("Start with one light or choose a recipe.").foregroundStyle(.secondary) }
            ForEach(scene.lights) { light in
                Button { selected = light.id } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(amber).frame(width: 36, height: 36)
                            .background(amber.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(light.name).font(.subheadline.weight(.semibold))
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
            if let lux = Photometry.normalIlluminance(candela: light.candela, distanceMeters: light.position.distance(to: scene.subject)) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("IDEAL NORMAL-INCIDENCE ESTIMATE").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                    Text("\(lux, specifier: "%.0f") lx").font(.system(.title2, design: .monospaced).weight(.semibold))
                }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            control("Horizontal", id: light.id, key: \.position.x, range: -4...4, step: 0.05, unit: "m")
            control("Depth", id: light.id, key: \.position.z, range: -4...4, step: 0.05, unit: "m")
            control("Height", id: light.id, key: \.position.y, range: 0...4, step: 0.05, unit: "m")
            Divider()
            control("Intensity", id: light.id, key: \.candela, range: 0...3000, step: 25, unit: "cd")
            control("Temperature", id: light.id, key: \.kelvin, range: 2000...9000, step: 100, unit: "K")
        }.padding(14).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func control(_ title: String, id: UUID, key: WritableKeyPath<StudioLight, Double>, range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        let value = Binding<Double>(
            get: { scene.lights.first(where: { $0.id == id })?[keyPath: key] ?? range.lowerBound },
            set: { new in
                guard let i = scene.lights.firstIndex(where: { $0.id == id }), new.isFinite else { return }
                if editStart == nil { remember(scene) }
                scene.lights[i][keyPath: key] = min(range.upperBound, max(range.lowerBound, new))
            })
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value.wrappedValue, specifier: unit == "m" ? "%.2f" : "%.0f") \(unit)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step, onEditingChanged: { editing in
                if editing { editStart = scene }
                else {
                    if let start = editStart, start != scene { remember(start) }
                    editStart = nil
                }
            }).accessibilityLabel(title)
        }
    }

    private var recipeSheet: some View {
        NavigationStack {
            List {
                Section("Replace current setup") {
                    ForEach(LightingRecipe.allCases, id: \.self) { recipe in
                        Button {
                            replace(recipe.makeScene()); showRecipes = false
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(recipe.rawValue).font(.headline)
                                Text(recipe.detail).font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.vertical, 8)
                        }.accessibilityIdentifier("recipe-\(recipe.rawValue)")
                    }
                }
                Section { Text("Undo restores your previous setup.").font(.footnote) }
            }.navigationTitle("Lighting recipes")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showRecipes = false } } }
        }
    }

    private var exportText: String {
        let entries = scene.lights.map { light in
            "\(light.name): \(String(format: "(%.2f, %.2f, %.2f)", light.position.x, light.position.y, light.position.z)) m, \(Int(light.candela)) cd, \(Int(light.kelvin)) K"
        }
        return (["Key & Fill — Portrait lighting plan", "Coordinates: x, y, z in meters."] + entries + ["Illustrative plan; not calibrated photometry."]).joined(separator: "\n")
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
            if let stored = try store.load() { scene = stored; saved = stored }
            history.removeAll(); future.removeAll(); selected = scene.lights.first?.id
            saveBlocked = false; loaded = true; message = nil
        } catch {
            saveBlocked = true; loaded = true
            message = "Saved project could not be opened. Saving is disabled to protect existing data."
        }
    }
    private func save() {
        do {
            try store.save(scene); saved = scene; message = "Project saved on this device."
        } catch { message = "Could not save the project. Your edits remain in this session." }
    }
}
