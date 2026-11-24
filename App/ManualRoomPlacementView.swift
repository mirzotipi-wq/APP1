import SwiftUI
import LightingCore

/// Manual, session-only alternative to AR. Nothing changes the lighting scene.
struct ManualRoomPlacementView: View {
    let scene: LightingScene
    @Environment(\.dismiss) private var dismiss
    @State private var room = ManualRoom()
    private var plan: RoomPlacementPlan? { try? RoomPlacementPlan(scene: scene, room: room) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Measure the room").font(.title2.bold())
                        Text("Enter real wall distances and the subject's floor position. Place each camera and light center using the measurements below, and check rectangular modifier projections.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    inputs
                    if let plan {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(plan.outsideCount == 0 ? "All \(plan.points.count) center positions inside room" :
                                  "\(plan.outsideCount) of \(plan.points.count) center positions outside room",
                                  systemImage: plan.outsideCount == 0 ? "checkmark.circle" : "exclamationmark.triangle")
                                .font(.headline)
                                .accessibilityIdentifier("roomPlacementStatus")
                            if !plan.modifierFootprints.isEmpty {
                                if plan.crossingModifierCount > 0 {
                                    Label("\(plan.crossingModifierCount) rectangular modifiers cross a wall",
                                          systemImage: "exclamationmark.triangle")
                                        .foregroundStyle(.orange)
                                        .accessibilityIdentifier("modifierCrossingStatus")
                                } else if plan.unavailableModifierCount == 0 {
                                    Label("Rectangular emitting faces within room outline",
                                          systemImage: "checkmark.circle")
                                        .foregroundStyle(.secondary)
                                        .accessibilityIdentifier("modifierCrossingStatus")
                                }
                                if plan.unavailableModifierCount > 0 {
                                    Label("\(plan.unavailableModifierCount) modifier projections unavailable; check aim",
                                          systemImage: "questionmark.circle")
                                        .foregroundStyle(.secondary)
                                        .accessibilityIdentifier("modifierUnavailableStatus")
                                }
                            }
                            map(plan)
                            Text("Near wall at bottom · left wall at left. Rectangular emitting faces are projected to the floor and clipped to the room outline; dashed orange outlines cross a wall.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(plan.points) { point in
                            measurements(point, footprint: plan.modifierFootprints.first { $0.id.uuidString == point.id })
                            Divider()
                        }
                    } else {
                        Label("Check room measurements and scene geometry.", systemImage: "exclamationmark.triangle")
                    }
                    Label("Manual measurements only", systemImage: "ruler")
                        .font(.headline)
                    Text("Center coordinates and rectangular emitting-face projections are calculated at 1:1 scale from your entries. These checks do not measure the actual room, detect collisions, include the entire fixture or guarantee clearance. Check housing, stands, booms, cables and ceiling clearance physically. Room settings are session-only and do not change the saved lighting setup.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(16).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Room placement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("closeRoomPlacement")
                }
            }
        }
    }

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room dimensions").font(.headline)
            RoomMeasurementField(title: "Width", id: "roomWidth", value: Binding(
                get: { room.widthMeters }, set: {
                    room.widthMeters = $0
                    room.subjectX = min(room.subjectX, $0)
                }), range: ManualRoom.dimensionRange)
            RoomMeasurementField(title: "Depth", id: "roomDepth", value: Binding(
                get: { room.depthMeters }, set: {
                    room.depthMeters = $0
                    room.subjectZ = min(room.subjectZ, $0)
                }), range: ManualRoom.dimensionRange)
            Divider()
            Text("Subject floor position").font(.headline)
            RoomMeasurementField(title: "From left wall", id: "roomSubjectX", value: $room.subjectX,
                                 range: 0...room.widthMeters)
            RoomMeasurementField(title: "From near wall", id: "roomSubjectZ", value: $room.subjectZ,
                                 range: 0...room.depthMeters)
            Divider()
            Text("Rig rotation").font(.headline)
            HStack {
                Slider(value: $room.yawDegrees, in: -180...180, step: 5)
                    .accessibilityLabel("Rig rotation")
                    .accessibilityValue("\(Int(room.yawDegrees)) degrees")
                    .accessibilityIdentifier("roomRotation")
                Text("\(Int(room.yawDegrees))°").monospacedDigit().frame(minWidth: 54, alignment: .trailing)
            }
            Button("Rotate 180°") { room.yawDegrees = room.yawDegrees == 180 ? 0 : 180 }
                .frame(minHeight: 44)
                .accessibilityIdentifier("roomHalfTurn")
            Text("Positive rotation turns the scene's +Z direction toward the room's right wall.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func map(_ plan: RoomPlacementPlan) -> some View {
        GeometryReader { proxy in
            let scale = max(0, min((proxy.size.width - 36) / CGFloat(plan.room.widthMeters),
                                   (proxy.size.height - 36) / CGFloat(plan.room.depthMeters)))
            let w = CGFloat(plan.room.widthMeters) * scale
            let h = CGFloat(plan.room.depthMeters) * scale
            let left = (proxy.size.width - w) / 2
            let top = (proxy.size.height - h) / 2
            ZStack(alignment: .topLeading) {
                Color(red: 0.075, green: 0.085, blue: 0.10)
                Rectangle().stroke(Color.white.opacity(0.55), lineWidth: 1)
                    .frame(width: w, height: h)
                    .position(x: left + w / 2, y: top + h / 2)
                Canvas { context, _ in
                    for footprint in plan.modifierFootprints where footprint.isAvailable {
                        var outline = Path()
                        for (index, corner) in footprint.corners.enumerated() {
                            let p = CGPoint(x: CGFloat(corner.xFromLeft) * scale,
                                            y: h - CGFloat(corner.zFromNear) * scale)
                            if index == 0 { outline.move(to: p) } else { outline.addLine(to: p) }
                        }
                        outline.closeSubpath()
                        let crosses = !footprint.crossedWalls.isEmpty
                        context.stroke(outline, with: .color(crosses ? .orange : .white.opacity(0.75)),
                                       style: StrokeStyle(lineWidth: 2, dash: crosses ? [4, 3] : []))
                    }
                }
                .frame(width: w, height: h)
                .clipped()
                .position(x: left + w / 2, y: top + h / 2)
                .accessibilityHidden(true)
                ForEach(plan.points.filter(\.insideRoom)) { point in
                    Image(systemName: symbol(point.kind))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(point.kind == .light ? Color.orange.opacity(0.8) : Color.gray, in: Circle())
                        .position(x: left + CGFloat(point.xFromLeft) * scale,
                                  y: top + h - CGFloat(point.zFromNear) * scale)
                }
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overhead room diagram. Detailed coordinates follow.")
        .accessibilityIdentifier("roomPlacementMap")
    }

    private func measurements(_ point: RoomPlacementPoint, footprint: RoomModifierFootprint?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(point.name, systemImage: symbol(point.kind)).font(.headline)
            if !point.insideRoom {
                Label("Outside room", systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(.orange)
            }
            if let footprint {
                if !footprint.isAvailable {
                    Label("Modifier projection unavailable", systemImage: "questionmark.circle")
                        .foregroundStyle(.secondary)
                } else if !footprint.crossedWalls.isEmpty {
                    Label("Emitting face crosses " + footprint.crossedWalls.map(\.rawValue).joined(separator: ", ") + " wall boundary",
                          systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if let clearance = footprint.minimumWallClearanceMeters {
                    Text(clearance < 0 ? "Projected wall overhang: \(meters(-clearance))" :
                         "Minimum projected wall distance: \(meters(clearance))")
                        .foregroundStyle(.secondary)
                }
            }
            Text("X from left wall: \(meters(point.xFromLeft))")
            Text("Z from near wall: \(meters(point.zFromNear))")
            Text("Height: \(meters(point.heightMeters)) · Floor distance to subject: \(meters(point.horizontalDistanceFromSubject))")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.monospacedDigit())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func meters(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " m"
    }

    private func symbol(_ kind: RoomPlacementPoint.Kind) -> String {
        switch kind {
        case .subject: return "person.fill"
        case .camera: return "camera.fill"
        case .light: return "lightbulb.fill"
        }
    }
}

/// Draft text is separate from the committed measurement. Typing malformed
/// input never updates the room or clamps a user's value without notice.
private struct RoomMeasurementField: View {
    let title: String
    let id: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    @Environment(\.locale) private var locale
    @State private var draft = ""
    @State private var invalid = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                TextField("Meters", text: $draft)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .accessibilityLabel(title + " in meters")
                    .accessibilityIdentifier(id)
                    .onSubmit { apply() }
                Text("m").foregroundStyle(.secondary)
                Button("Set") { apply() }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Set " + title.lowercased())
                    .accessibilityIdentifier(id + "Set")
            }
            if invalid {
                Text("Enter a number from \(format(range.lowerBound)) to \(format(range.upperBound)) m.")
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityIdentifier(id + "Error")
            }
        }
        .onAppear { draft = format(value) }
        .onChange(of: value) { _, next in
            draft = format(next)
            invalid = false
        }
        .onChange(of: draft) { _, _ in invalid = false }
    }

    private func format(_ number: Double) -> String {
        number.formatted(.number.precision(.fractionLength(0...6)).grouping(.never).locale(locale))
    }

    private func apply() {
        guard let next = RoomMeasurementInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                                    in: range) else {
            invalid = true
            return
        }
        value = next
        draft = format(next)
        invalid = false
        focused = false
    }
}
