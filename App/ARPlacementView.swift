import LightingCore
import RealityKit
import SwiftUI
import UIKit

@MainActor
struct ARPlacementView: View {
    let scene: LightingScene
    private let onRoomChange: ((ManualRoom) -> Void)?
    @StateObject private var controller: ARPlacementController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue
    @State private var showingManual = false

    private var units: PlanUnits { StudioPreferences.units(from: unitsRawValue) }

    init(scene: LightingScene, onRoomChange: ((ManualRoom) -> Void)? = nil) {
        self.scene = scene
        self.onRoomChange = onRoomChange
        _controller = StateObject(wrappedValue: ARPlacementController(scene: scene))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introduction
                    if controller.cameraEnabled { cameraPreview }
                    status
                    controls
                    manualOption
                    if let layout = controller.layout { measurements(layout) }
                    Text("The setup uses authored distances at 1:1 scale. AR tracking can drift; displayed distances are calculated from the plan and do not measure actual equipment or tracking accuracy. Check the physical floor, stands, cables and clearances. No LiDAR is required. Camera frames stay on this device and are not saved by this view. AR anchors are cleared when you leave or pause the camera.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("arPlacementLimitations")
                }
                .padding(16)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("AR placement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        controller.disappeared()
                        dismiss()
                    }
                    .accessibilityIdentifier("closeARPlacement")
                }
            }
            .sheet(isPresented: $showingManual) {
                ManualRoomPlacementView(scene: scene, onChange: onRoomChange)
            }
            .onAppear { controller.appeared(isActive: scenePhase == .active) }
            .onDisappear { controller.disappeared() }
            .onChange(of: scenePhase) { _, phase in controller.setActive(phase == .active) }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bring the setup into your room").font(.title2.bold())
            Text("Choose the subject’s floor position, then follow the subject, camera and light markers. Heights refer to equipment centers above your chosen floor.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var cameraPreview: some View {
        ZStack {
            PlacementCameraView(controller: controller)
            ForEach(controller.labels) { label in
                Text(label.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1).truncationMode(.tail)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .frame(maxWidth: 150)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 5))
                    .position(label.point)
            }
            if !controller.hasPlacement {
                Image(systemName: controller.canPlace ? "scope" : "plus")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2)
            }
            if !controller.trackingNormal {
                VStack {
                    Spacer()
                    Label("Placement hidden until tracking recovers", systemImage: "eye.slash")
                        .font(.caption.weight(.semibold))
                        .padding(10).foregroundStyle(.white)
                        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                        .padding(12)
                }
            }
        }
        .frame(height: 330)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        // Every marker and calculated distance has a full accessible row below.
        .accessibilityHidden(true)
        .accessibilityIdentifier("arCameraPreview")
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(controller.statusTitle, systemImage: statusSymbol)
                .font(.headline)
                .accessibilityIdentifier("arTrackingStatus")
            Text(controller.statusDetail).font(.subheadline).foregroundStyle(.secondary)
                .accessibilityIdentifier("arTrackingGuidance")
            if let error = controller.placementError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.subheadline).accessibilityIdentifier("arPlacementError")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var statusSymbol: String {
        if controller.phase != .running { return "viewfinder" }
        return controller.trackingNormal && !controller.needsPlacementReview ? "viewfinder" : "exclamationmark.triangle"
    }

    @ViewBuilder private var controls: some View {
        if controller.phase == .running {
            if !controller.hasPlacement {
                Button { controller.placeOnFloor() } label: {
                    Label("Place subject on this floor point", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!controller.canPlace)
                .accessibilityHint("Aim the center crosshair at the physical floor where the subject will stand.")
                .accessibilityIdentifier("placeARFloor")
                Text("AR detects horizontal surfaces; you must choose the floor. A table or shelf would put every height above the wrong surface.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup direction").font(.headline)
                    HStack {
                        Slider(value: Binding(get: { controller.yawDegrees }, set: { controller.rotate(to: $0) }),
                               in: -180...180, step: 1)
                            .disabled(!controller.trackingNormal)
                            .accessibilityLabel("AR setup rotation")
                            .accessibilityValue("\(Int(controller.yawDegrees)) degrees")
                            .accessibilityIdentifier("arSetupRotation")
                        Text("\(Int(controller.yawDegrees))°").monospacedDigit().frame(minWidth: 54)
                    }
                    Text("The initial direction points the planned camera toward your position. Rotate the whole setup to suit the room; distances stay unchanged.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if controller.needsPlacementReview && controller.trackingNormal {
                    Button("I checked the recovered placement") { controller.confirmRecoveredPlacement() }
                        .frame(minHeight: 44).buttonStyle(.bordered)
                        .accessibilityIdentifier("confirmARPlacementRecovery")
                }
            }
            HStack {
                Button("Reset and scan again") { controller.reset() }
                    .frame(minHeight: 44).accessibilityIdentifier("resetARPlacement")
                Spacer()
                Button("Stop camera") { controller.stop() }
                    .frame(minHeight: 44).accessibilityIdentifier("stopARCamera")
            }
            .buttonStyle(.bordered)
        } else if controller.phase == .denied {
            Button("Open Camera Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .frame(minHeight: 44).buttonStyle(.bordered)
            .accessibilityIdentifier("openARCameraSettings")
            startButton
        } else if controller.phase != .unsupported && controller.phase != .restricted && controller.phase != .invalidScene {
            startButton
        }
    }

    private var startButton: some View {
        Button { controller.start() } label: {
            Label(controller.phase == .requestingPermission ? "Waiting for permission…" : "Start AR camera",
                  systemImage: "camera")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!controller.canStart)
        .accessibilityIdentifier("startARCamera")
    }

    private var manualOption: some View {
        Button {
            controller.stop()
            showingManual = true
        } label: {
            Label("Use manual room measurements", systemImage: "ruler")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("arManualMeasurements")
    }

    private func measurements(_ layout: ARPlacementLayout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned placement measurements").font(.headline)
            Text("Calculated from your setup. Floor distances start at the subject’s floor position; center distances connect equipment centers.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(layout.items) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Label(StudioDisplayName.label(item.name, fallback: item.role.rawValue.capitalized),
                          systemImage: symbol(item.role)).font(.subheadline.weight(.semibold))
                    Text("Height above floor: \(distance(item.heightAboveFloorMeters))")
                    if item.role != .subject {
                        Text("Floor distance to subject: \(distance(item.horizontalDistanceFromSubjectMeters))")
                        Text("Center distance to subject: \(distance(item.distanceFromSubjectMeters))")
                    }
                    if item.heightAboveFloorMeters < 0 {
                        Label("This authored center is below the chosen floor. Adjust its height in the studio.",
                              systemImage: "exclamationmark.triangle")
                    }
                }
                .font(.subheadline.monospacedDigit())
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("arMeasurement_" + item.id)
                if item.id != layout.items.last?.id { Divider() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func distance(_ value: Double) -> String {
        PlacementMeasurementDisplay.distance(value, units: units, locale: locale)
    }

    private func symbol(_ role: ARPlacementItem.Role) -> String {
        switch role {
        case .subject: return "person.fill"
        case .camera: return "camera.fill"
        case .light: return "lightbulb.fill"
        }
    }
}

@MainActor
private struct PlacementCameraView: UIViewRepresentable {
    let controller: ARPlacementController
    func makeCoordinator() -> ARPlacementController { controller }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        view.isAccessibilityElement = false
        controller.attach(view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: ARPlacementController) {
        coordinator.detach(uiView)
    }
}
