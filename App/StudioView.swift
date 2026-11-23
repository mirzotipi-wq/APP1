import SwiftUI
import LightingCore

struct StudioView: View {
    @State private var scene = LightingScene.portrait()
    @State private var selected: UUID?
    @State private var message: String?
    @State private var loaded = false
    @State private var saveBlocked = false
    private let store = ProjectStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("PORTRAIT / TOP VIEW")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    plan
                        .frame(height: 300)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Overhead plan showing subject, camera and lights")
                    Text("Select a light")
                        .font(.headline)
                    ForEach(scene.lights) { light in
                        Button {
                            selected = light.id
                        } label: {
                            HStack {
                                Text(light.name)
                                Spacer()
                                Text("\(light.candela, specifier: "%.0f") cd")
                                    .foregroundStyle(.secondary)
                                if selected == light.id { Image(systemName: "checkmark.circle.fill") }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected == light.id ? .isSelected : [])
                    }
                    if let id = selected, let index = scene.lights.firstIndex(where: { $0.id == id }) {
                        inspector(index)
                    }
                    Text("Ideal point-source estimate only. Not a calibrated light meter or 3D lighting simulation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let message {
                        Text(message).font(.footnote).accessibilityAddTraits(.updatesFrequently)
                    }
                    if saveBlocked {
                        Button("Retry loading saved project") { load() }
                    }
                }.padding()
            }
            .navigationTitle("Key & Fill")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!loaded || saveBlocked)
                }
            }
            .task {
                if !loaded { load() }
            }
        }
    }

    private var plan: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let scale = min(width, height) / 9
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    for step in -4...4 {
                        let offset = CGFloat(step) * scale
                        var line = Path()
                        line.move(to: CGPoint(x: center.x + offset, y: 0))
                        line.addLine(to: CGPoint(x: center.x + offset, y: size.height))
                        line.move(to: CGPoint(x: 0, y: center.y + offset))
                        line.addLine(to: CGPoint(x: size.width, y: center.y + offset))
                        context.stroke(line, with: .color(.secondary.opacity(0.18)), lineWidth: 1)
                    }
                }
                marker("Subject", icon: "person.fill", color: .primary)
                    .position(point(scene.subject, width: width, height: height, scale: scale))
                marker("Camera", icon: "camera.fill", color: .secondary)
                    .position(point(scene.camera, width: width, height: height, scale: scale))
                ForEach(scene.lights) { light in
                    Button {
                        selected = light.id
                    } label: {
                        marker(light.name, icon: selected == light.id ? "lightbulb.fill" : "lightbulb", color: .orange)
                    }.buttonStyle(.plain)
                     .accessibilityLabel("Select \(light.name) light")
                     .position(point(light.position, width: width, height: height, scale: scale))
                }
            }
            .clipped()
        }
    }

    private func point(_ position: Position, width: CGFloat, height: CGFloat, scale: CGFloat) -> CGPoint {
        CGPoint(x: width / 2 + CGFloat(position.x) * scale, y: height / 2 + CGFloat(position.z) * scale)
    }

    private func marker(_ title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(title).font(.caption2.weight(.medium))
        }.frame(minWidth: 44, minHeight: 44)
    }

    private func inspector(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(scene.lights[index].name + " settings").font(.headline)
            control("Horizontal", value: $scene.lights[index].position.x, range: -4...4, unit: "m")
            control("Depth", value: $scene.lights[index].position.z, range: -4...4, unit: "m")
            control("Height", value: $scene.lights[index].position.y, range: 0...4, unit: "m")
            control("Intensity", value: $scene.lights[index].candela, range: 0...3000, unit: "cd")
            control("Temperature", value: $scene.lights[index].kelvin, range: 2000...9000, unit: "K")
            let light = scene.lights[index]
            if let lux = Photometry.normalIlluminance(candela: light.candela,
                    distanceMeters: light.position.distance(to: scene.subject)) {
                Text("Normal-incidence estimate: \(lux, specifier: "%.1f") lx").font(.subheadline)
            } else {
                Text("Estimate unavailable at this distance.").font(.subheadline)
            }
        }
    }

    private func control(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: unit == "m" ? "%.2f" : "%.0f") \(unit)")
                    .monospacedDigit().foregroundStyle(.secondary)
            }.font(.subheadline)
            Slider(value: value, in: range)
                .accessibilityLabel(title)
        }
    }

    private func load() {
        do {
            if let stored = try store.load() { scene = stored }
            selected = scene.lights.first?.id
            saveBlocked = false
            loaded = true
            message = nil
        } catch {
            saveBlocked = true
            loaded = true
            message = "Saved project could not be opened. Saving is disabled to protect existing data."
        }
    }

    private func save() {
        do {
            try store.save(scene)
            message = "Project saved on this device."
        } catch {
            message = "Could not save the project. Your edits remain in this session."
        }
    }
}
