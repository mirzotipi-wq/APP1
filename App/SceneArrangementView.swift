import LightingCore
import SwiftUI

struct SceneArrangementView: View {
    let scene: LightingScene
    let onApply: (LightingScene) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var destination: Position
    @State private var yaw = 0.0
    @State private var mirror = false
    @State private var error: String?
    @State private var didFinish = false

    private var fieldLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

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
                    fieldLayout {
                        Text("Rotate lights around subject")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        PrecisionValueButton(title: "Lighting rotation", unit: "°", id: "setupYaw",
                                             value: $yaw, range: -180...180)
                    }
                    Slider(value: $yaw, in: -180...180, step: 5)
                        .accessibilityLabel("Lighting rotation")
                        .accessibilityValue(StudioNumericInput.formattedValue(yaw, unit: "degrees", locale: locale))
                    Toggle("Mirror lights across camera center", isOn: $mirror)
                    Text("Rotation and mirroring change lights and manual aims. The camera keeps its current angle. All changes apply together as one undoable edit.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .accessibilityIdentifier("arrangementError")
                    }
                }
                Section {
                    Button("Apply arrangement") { apply() }
                        .accessibilityIdentifier("applyArrangement")
                    Button("Reset changes") {
                        guard !didFinish else { return }
                        destination = scene.subject; yaw = 0; mirror = false; error = nil
                    }
                }
            }
            .disabled(didFinish)
            .onChange(of: destination) { _, _ in error = nil }
            .onChange(of: yaw) { _, _ in error = nil }
            .onChange(of: mirror) { _, _ in error = nil }
            .navigationTitle("Arrange setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        guard !didFinish else { return }
                        didFinish = true
                        dismiss()
                    }
                    .disabled(didFinish)
                    .accessibilityIdentifier("cancelArrangement")
                }
            }
        }
    }

    private func coordinate(_ label: String, id: String, value: Binding<Double>) -> some View {
        fieldLayout {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            DistanceValueButton(title: "Setup " + label.lowercased(), id: id,
                                value: value, range: Position.coordinateRange, compactReadout: true)
        }
    }

    private func apply() {
        guard !didFinish else { return }
        do {
            let next = try SceneTransform.arranged(scene, subjectAt: destination,
                                                  rotatingLightsByDegrees: yaw,
                                                  mirroringLights: mirror)
            // Close the transaction before invoking the parent, which can
            // synchronously update the scene or dismiss this editor.
            didFinish = true
            onApply(next)
            dismiss()
        } catch let error as SceneTransformError {
            self.error = error.localizedDescription
        } catch {
            self.error = "This setup could not be arranged. Cancel and reopen the setup, then try again."
        }
    }
}
