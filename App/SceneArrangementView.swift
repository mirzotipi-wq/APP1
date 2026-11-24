import LightingCore
import SwiftUI

struct SceneArrangementView: View {
    let scene: LightingScene
    let onApply: (LightingScene) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var destination: Position
    @State private var yaw = 0.0
    @State private var mirror = false
    @State private var error: String?

    init(scene: LightingScene, onApply: @escaping (LightingScene) -> Void) {
        self.scene = scene
        self.onApply = onApply
        _destination = State(initialValue: scene.subject)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Move the whole setup") {
                    Text("Choose a new subject center. The camera, lights and manual aiming points move by the same distance.")
                        .font(.footnote).foregroundStyle(.secondary)
                    coordinate("Horizontal", id: "setupX", value: $destination.x)
                    coordinate("Height", id: "setupY", value: $destination.y)
                    coordinate("Depth", id: "setupZ", value: $destination.z)
                }
                Section("Change the lighting arrangement") {
                    HStack {
                        Text("Rotate lights around subject")
                        Spacer()
                        PrecisionValueButton(title: "Lighting rotation", unit: "°", id: "setupYaw",
                                             value: $yaw, range: -180...180)
                    }
                    Slider(value: $yaw, in: -180...180, step: 5)
                        .accessibilityLabel("Lighting rotation")
                        .accessibilityValue(StudioNumericInput.formattedValue(yaw, unit: "degrees"))
                    Toggle("Mirror lights across camera center", isOn: $mirror)
                    Text("Rotation and mirroring change lights and manual aims. The camera keeps its current angle. All changes apply together as one undoable edit.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let error { Section { Label(error, systemImage: "exclamationmark.triangle") } }
                Section {
                    Button("Apply arrangement") { apply() }
                        .accessibilityIdentifier("applyArrangement")
                    Button("Reset changes") {
                        destination = scene.subject; yaw = 0; mirror = false; error = nil
                    }
                }
            }
            .navigationTitle("Arrange setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func coordinate(_ label: String, id: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            DistanceValueButton(title: "Setup " + label.lowercased(), id: id,
                                value: value, range: Position.coordinateRange)
        }
    }

    private func apply() {
        do {
            var next = scene
            if yaw != 0 { next = try SceneTransform.rotatingLights(next, byDegrees: yaw) }
            if mirror { next = try SceneTransform.mirroringLights(next) }
            next = try SceneTransform.translated(next, by: .init(
                x: destination.x - scene.subject.x,
                y: destination.y - scene.subject.y,
                z: destination.z - scene.subject.z))
            onApply(next)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
