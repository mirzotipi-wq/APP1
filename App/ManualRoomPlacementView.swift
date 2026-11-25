import SwiftUI
import LightingCore

/// Placement geometry stays in meters. Keep the established signed, bounded
/// room readout in either display unit so tiny overhangs never appear as zero.
enum PlacementMeasurementDisplay {
    static func distance(_ meters: Double, units: PlanUnits, locale: Locale = .current) -> String {
        if units == .metric { return RoomMeasurementDisplay.distance(meters, locale: locale) }
        let value = units.fromMeters(meters)
        guard value.isFinite else { return "Unavailable" }
        let limit = 0.000001
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2...6))
            .grouping(.never).locale(locale)
        if value != 0, abs(value) < limit {
            let threshold = limit.formatted(style)
            let negativeThreshold = (-limit).formatted(style)
            return value < 0 ? "between \(negativeThreshold) and 0 \(units.symbol)"
                : "less than \(threshold) \(units.symbol)"
        }
        return (value == 0 ? 0.0 : value).formatted(style) + " " + units.symbol
    }
}

/// The slider's gesture step does not limit a stored room angle's precision.
struct RoomRotationReadout {
    let text: String
    let accessibilityValue: String

    init(degrees: Double, locale: Locale = .current) {
        let number = StudioNumericInput.formattedValue(degrees, locale: locale)
        text = number + "°"
        accessibilityValue = number + " degrees"
    }
}

/// Manual alternative to AR. The studio receives committed, valid room edits.
struct ManualRoomPlacementView: View {
    let scene: LightingScene
    private let onChange: ((ManualRoom) -> Bool)?
    private let onRemove: (() -> Bool)?
    private let onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue
    @State private var room: ManualRoom
    @State private var keptRoom: ManualRoom?
    @State private var roomCommitRejected = false
    @State private var showingRemoveConfirmation = false
    @State private var notesSnapshot: NotesSnapshot?
    private var plan: RoomPlacementPlan? { try? RoomPlacementPlan(scene: scene, room: room) }
    private var units: PlanUnits { StudioPreferences.units(from: unitsRawValue) }
    private var roomIsKept: Bool { !roomCommitRejected && keptRoom == room }

    init(scene: LightingScene, onRemove: (() -> Bool)? = nil,
         onClose: (() -> Void)? = nil, onChange: ((ManualRoom) -> Bool)? = nil) {
        self.scene = scene
        self.onChange = onChange
        self.onRemove = onRemove
        self.onClose = onClose
        _room = State(initialValue: scene.placementRoom ?? ManualRoom())
        _keptRoom = State(initialValue: scene.placementRoom)
    }

    private struct NotesSnapshot: Identifiable {
        let id = UUID()
        let text: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Measure the room").font(.title2.bold())
                        Text("Enter real wall distances and the subject's floor position. Add a ceiling height to check centers and ideal rectangular emitting faces against the floor and ceiling.")
                            .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                    }
                    if let plan { placementSummary(plan) }
                    inputs
                    if onChange != nil { roomCommitControls }
                    if keptRoom != nil, onRemove != nil { roomRemovalControls }
                    if roomCommitRejected {
                        Label("The setup changed or this editor closed. Your change was not applied. Close and reopen room placement to edit the current setup.",
                              systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .accessibilityIdentifier("roomCommitError")
                    }
                    if let plan {
                        VStack(alignment: .leading, spacing: 10) {
                            map(plan)
                            Text("Near wall at bottom · left wall at left. Rectangular emitting faces are projected to the floor and clipped to the room outline; dashed orange outlines cross a wall.")
                                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
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
                    Text("Center coordinates and ideal rectangular emitting faces are calculated at 1:1 scale from your entries. Height checks assume a flat floor and, when measured, a flat horizontal ceiling. Touching means zero distance. These checks do not measure the actual room, detect equipment collisions or guarantee complete fixture clearance. Check housing, stands, booms, cables and working clearance physically. Displayed precision does not guarantee measurement accuracy. Room measurements kept with the setup are included when you save the lighting project.")
                        .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                }
                .padding(16).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Room placement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onClose?()
                        dismiss()
                    }.accessibilityIdentifier("closeRoomPlacement")
                }
            }
            .sheet(item: $notesSnapshot) { snapshot in
                RoomPlacementNotesView(text: snapshot.text)
            }
            .alert("Remove room measurements from setup?", isPresented: $showingRemoveConfirmation) {
                Button("Remove room measurements", role: .destructive) { removeRoom() }
                    .accessibilityIdentifier("confirmRemoveRoomFromSetup")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The displayed measurements stay here for planning. Save the lighting project to keep the removal for future sessions. Undo in the studio steps back through the applied room changes.")
            }
            .onChange(of: room) { _, next in
                keepRoom(next)
            }
        }
        .tint(StudioPalette.action)
    }

    private var roomCommitControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                // An unchanged default room still needs an explicit callback
                // before it belongs to the setup. Never read field drafts here.
                keepRoom(room)
            } label: {
                Label(roomIsKept ? "Room kept with setup" : "Keep room with setup",
                      systemImage: roomIsKept ? "checkmark.circle" : "plus.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!room.isValid || roomIsKept)
            .accessibilityIdentifier("keepRoomWithSetup")
            .accessibilityHint("Keeps the current valid room measurements in this setup. Save the lighting project to keep them for future sessions.")
            Text("If the displayed values already match your room, use Keep room with setup. Press Set to include each changed entry; unfinished or invalid field text is excluded. Save the lighting project to keep the applied measurements for future sessions.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                .accessibilityIdentifier("keepRoomWithSetupHelp")
        }
    }

    private func keepRoom(_ next: ManualRoom) {
        guard next.isValid, let onChange else { return }
        guard onChange(next) else {
            roomCommitRejected = true
            return
        }
        roomCommitRejected = false
        keptRoom = next
    }

    private var roomRemovalControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(role: .destructive) {
                showingRemoveConfirmation = true
            } label: {
                Label("Remove room from setup", systemImage: "minus.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("removeRoomFromSetup")
            .accessibilityHint("Asks for confirmation before removing the room measurements from this setup. The displayed measurements remain available for planning.")
            Text("Save the lighting project to keep a removal for future sessions. Undo in the studio steps back through the applied room changes.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
                .accessibilityIdentifier("removeRoomFromSetupHelp")
        }
    }

    private func removeRoom() {
        guard keptRoom != nil, let onRemove else { return }
        guard onRemove() else {
            roomCommitRejected = true
            return
        }
        // Acknowledge removal only after the current presentation accepts it.
        // Keep the measured planning draft available for review and sharing.
        roomCommitRejected = false
        keptRoom = nil
    }

    /// Keep the committed placement result ahead of the editable measurements.
    /// Invalid drafts never masquerade as the actual room geometry.
    private func placementSummary(_ plan: RoomPlacementPlan) -> some View {
        let centerStatus = plan.outsideCount == 0
            ? "All \(plan.points.count) center positions inside room"
            : "\(plan.outsideCount) of \(plan.points.count) center positions outside room"
        return VStack(alignment: .leading, spacing: 8) {
            Text("Current measured layout").font(.caption.weight(.semibold)).foregroundStyle(StudioPalette.secondaryText)
            Text("Wall checks · floor projection")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
            Label(centerStatus,
                  systemImage: plan.outsideCount == 0 ? "checkmark.circle" : "exclamationmark.triangle")
                .font(.headline)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: centerStatus))
                .accessibilityHint("Checks the floor projection against walls. Height checks follow separately.")
                .accessibilityIdentifier("roomPlacementStatus")
            if !plan.modifierFootprints.isEmpty {
                if plan.crossingModifierCount > 0 {
                    Label(plan.crossingModifierCount == 1 ? "1 rectangular modifier crosses a wall" :
                          "\(plan.crossingModifierCount) rectangular modifiers cross a wall",
                          systemImage: "exclamationmark.triangle")
                        .foregroundStyle(StudioPalette.warning)
                        .accessibilityIdentifier("modifierCrossingStatus")
                } else if plan.unavailableModifierCount == 0 {
                    Label("Rectangular emitting faces within room outline",
                          systemImage: "checkmark.circle")
                        .foregroundStyle(StudioPalette.secondaryText)
                        .accessibilityIdentifier("modifierCrossingStatus")
                }
                if plan.unavailableModifierCount > 0 {
                    Label("\(plan.unavailableModifierCount) modifier projections unavailable; check aim",
                          systemImage: "questionmark.circle")
                        .foregroundStyle(StudioPalette.secondaryText)
                        .accessibilityIdentifier("modifierUnavailableStatus")
                }
            }
            Text(plan.room.ceilingHeightMeters.map { "Ceiling height: \(distance($0))" } ?? "Ceiling height: Unmeasured")
                .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                .accessibilityIdentifier("roomCeilingStatus")
            heightSummary(plan)
            Button {
                // Capture the committed plan, never a partially typed field.
                // The presented notes and share item use the same immutable text.
                notesSnapshot = .init(text: plan.textSummary(locale: locale))
            } label: {
                Label("Review and share notes", systemImage: "doc.text")
                    .frame(minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("reviewRoomNotes")
            Text("Notes use the current measured layout in meters. Press Set to include a changed entry. Save the lighting project to keep room measurements with the setup.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var inputs: some View {
        let rotation = RoomRotationReadout(degrees: room.yawDegrees, locale: locale)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Room dimensions").font(.headline)
            RoomMeasurementField(title: "Width", id: "roomWidth", value: $room.widthMeters,
                                 range: room.widthEditRange, units: units)
            RoomMeasurementField(title: "Depth", id: "roomDepth", value: $room.depthMeters,
                                 range: room.depthEditRange, units: units)
            Text("Room size changes keep the subject's wall offsets. To enter a smaller room, first move the subject closer to the corresponding wall.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
            RoomMeasurementField(title: "Ceiling height (optional)", id: "roomCeilingHeight",
                                 value: $room.ceilingHeightMeters, range: ManualRoom.dimensionRange, units: units)
            Text("Leave blank and press Set for unmeasured. A measured height enables ceiling checks for centers and ideal emitting faces; floor checks remain available without it.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
            Divider()
            Text("Subject floor position").font(.headline)
            RoomMeasurementField(title: "From left wall", id: "roomSubjectX", value: $room.subjectX,
                                 range: 0...room.widthMeters, units: units)
            RoomMeasurementField(title: "From near wall", id: "roomSubjectZ", value: $room.subjectZ,
                                 range: 0...room.depthMeters, units: units)
            Divider()
            Text("Rig rotation").font(.headline)
            HStack {
                StudioSlider(value: $room.yawDegrees, in: -180...180, step: 5,
                             accessibility: .init(label: "Rig rotation",
                                 value: { [locale] in RoomRotationReadout(degrees: $0, locale: locale).accessibilityValue },
                                 identifier: "roomRotation")) { _ in }
                Text(rotation.text).monospacedDigit().frame(minWidth: 54, alignment: .trailing)
            }
            Button { room.rotate(byDegrees: 180) } label: {
                Text("Rotate 180°")
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
                .accessibilityIdentifier("roomHalfTurn")
            Text("Positive rotation turns the scene's +Z direction toward the room's right wall.")
                .font(.caption).foregroundStyle(StudioPalette.secondaryText)
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
                StudioPalette.planBackground
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
                        context.stroke(outline, with: .color(crosses ? StudioPalette.planLight : .white.opacity(0.75)),
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
                        .foregroundStyle(point.kind == .light ? StudioPalette.planLight : .white)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.65), in: Circle())
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

    private func pointDisplayName(_ point: RoomPlacementPoint) -> String {
        let fallback = scene.lights.firstIndex(where: { $0.id.uuidString == point.id })
            .map { "Light \($0 + 1)" } ?? point.kind.rawValue.capitalized
        return StudioDisplayName.label(point.name, fallback: fallback)
    }

    private func measurements(_ point: RoomPlacementPoint, footprint: RoomModifierFootprint?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(pointDisplayName(point), systemImage: symbol(point.kind)).font(.headline)
            if !point.insideRoom {
                Label("Outside room", systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(StudioPalette.warning)
            }
            Text("X from left wall: \(distance(point.xFromLeft))")
            Text("Z from near wall: \(distance(point.zFromNear))")
            Text("Height: \(distance(point.heightMeters)) · Floor distance to subject: \(distance(point.horizontalDistanceFromSubject))")
                .foregroundStyle(StudioPalette.secondaryText)
            verticalCheck(point.verticalClearance, title: "Center height check",
                          id: "roomCenterHeightCheck_" + point.id)
            if let footprint {
                if !footprint.isAvailable {
                    Label("Modifier projection unavailable", systemImage: "questionmark.circle")
                        .foregroundStyle(StudioPalette.secondaryText)
                } else if !footprint.crossedWalls.isEmpty {
                    Label("Emitting face crosses " + footprint.crossedWalls.map(\.rawValue).joined(separator: ", ") + " wall boundary",
                          systemImage: "exclamationmark.triangle")
                        .foregroundStyle(StudioPalette.warning)
                }
                if let clearance = footprint.minimumWallClearanceMeters {
                    Text(clearance < 0 ? "Projected wall overhang: \(distance(-clearance))" :
                         "Minimum projected wall distance: \(distance(clearance))")
                        .foregroundStyle(StudioPalette.secondaryText)
                }
                verticalCheck(footprint.verticalClearance, title: "Ideal emitting-face height check",
                              id: "roomFaceHeightCheck_" + point.id)
            }
        }
        .font(.subheadline.monospacedDigit())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heightSummary(_ plan: RoomPlacementPlan) -> some View {
        let extent = plan.room.ceilingHeightMeters == nil ? "below floor" : "below floor or above measured ceiling"
        let boundaries = plan.room.ceilingHeightMeters == nil ? "floor" : "floor or ceiling"
        let unavailableFaces = plan.modifierFootprints.filter { !$0.verticalClearance.isAvailable }.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("Height checks").font(.subheadline.weight(.semibold))
            Label("Centers \(extent): \(plan.verticalOutsideCount); touching \(boundaries): \(plan.verticalTouchingPointCount)",
                  systemImage: plan.verticalOutsideCount > 0 ? "exclamationmark.triangle" : "arrow.up.and.down")
                .foregroundStyle(plan.verticalOutsideCount > 0 ? StudioPalette.warning : StudioPalette.secondaryText)
                .accessibilityIdentifier("roomCenterHeightStatus")
            if !plan.modifierFootprints.isEmpty {
                Label("Ideal emitting faces \(extent): \(plan.verticalCrossingModifierCount); touching \(boundaries): \(plan.verticalTouchingModifierCount)",
                      systemImage: plan.verticalCrossingModifierCount > 0 ? "exclamationmark.triangle" : "arrow.up.and.down")
                    .foregroundStyle(plan.verticalCrossingModifierCount > 0 ? StudioPalette.warning : StudioPalette.secondaryText)
                    .accessibilityIdentifier("roomFaceHeightStatus")
            }
            if plan.room.ceilingHeightMeters == nil {
                Text("Ceiling checks unavailable until a height is measured.")
                    .foregroundStyle(StudioPalette.secondaryText)
                    .accessibilityIdentifier("roomCeilingUnmeasured")
            }
            if unavailableFaces > 0 {
                Text("\(unavailableFaces) ideal emitting-face height checks unavailable; check aim.")
                    .foregroundStyle(StudioPalette.secondaryText)
                    .accessibilityIdentifier("roomFaceHeightUnavailable")
            }
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func verticalCheck(_ report: RoomVerticalClearance, title: String, id: String) -> some View {
        let hasCrossing = !report.crossedBoundaries.isEmpty
        let symbol = !report.isAvailable ? "questionmark.circle"
            : hasCrossing ? "exclamationmark.triangle" : "arrow.up.and.down"
        return VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption.weight(.semibold))
            Label(report.statusSummary(distance: distance), systemImage: symbol)
                .foregroundStyle(hasCrossing ? StudioPalette.warning : StudioPalette.secondaryText)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
    }

    private func distance(_ value: Double) -> String {
        PlacementMeasurementDisplay.distance(value, units: units, locale: locale)
    }

    private func symbol(_ kind: RoomPlacementPoint.Kind) -> String {
        switch kind {
        case .subject: return "person.fill"
        case .camera: return "camera.fill"
        case .light: return "lightbulb.fill"
        }
    }
}

/// A read-only snapshot. Reviewing or sharing never saves or changes the room
/// or studio, and dismissing this sheet leaves the room editor open.
private struct RoomPlacementNotesView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("These notes contain the committed room measurements and calculated placement coordinates in meters. Save the lighting project to keep the editable room measurements with the setup.")
                        .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
                        .accessibilityIdentifier("roomNotesScope")
                    ShareLink(item: text, subject: Text("Key & Fill room measurements")) {
                        Label("Share measurement notes", systemImage: "square.and.arrow.up")
                            .foregroundStyle(StudioPalette.prominentActionText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("shareRoomNotes")
                    Text(text)
                        .font(.body.monospacedDigit())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Give the selectable preview the same complete content
                        // as the visible text and share item, independently of
                        // the platform's inferred selectable-text description.
                        .accessibilityLabel(Text(verbatim: text))
                        .accessibilityIdentifier("roomNotesText")
                }
                .padding(16).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .navigationTitle("Room notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("closeRoomNotes")
                }
            }
        }
        .tint(StudioPalette.action)
    }
}

/// Draft text is separate from the committed measurement. Typing malformed
/// input never updates the room or clamps a user's value without notice.
private struct RoomMeasurementField: View {
    let title: String
    let id: String
    @Binding private var value: Double?
    let range: ClosedRange<Double>
    let units: PlanUnits
    private let allowsUnmeasured: Bool
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var draft = ""
    @State private var draftUnits: PlanUnits?
    @State private var draftLocale: Locale?
    @State private var draftValueBits: UInt64?
    @State private var invalid = false
    @State private var rejectedOversizedDraft = false
    @State private var focused = false

    init(title: String, id: String, value: Binding<Double>, range: ClosedRange<Double>, units: PlanUnits) {
        self.title = title
        self.id = id
        _value = Binding(get: { value.wrappedValue }, set: { next in
            if let next { value.wrappedValue = next }
        })
        self.range = range
        self.units = units
        allowsUnmeasured = false
    }

    init(title: String, id: String, value: Binding<Double?>, range: ClosedRange<Double>, units: PlanUnits) {
        self.title = title
        self.id = id
        _value = value
        self.range = range
        self.units = units
        allowsUnmeasured = true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                StudioTextField(allowsUnmeasured ? "Unmeasured" : (units == .metric ? "Meters" : "Feet"),
                    text: boundedDraft, isFocused: $focused,
                    accessibility: .init(label: title + " in " + (units == .metric ? "meters" : "feet"),
                                         identifier: id), keyboardType: .decimalPad,
                    textAlignment: layoutDirection == .rightToLeft ? .left : .right,
                    monospacedDigits: true) { apply() }
                    .padding(.horizontal, 8)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(StudioPalette.secondaryText, lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                Button {
                    draft = ""
                    invalid = false
                    rejectedOversizedDraft = false
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(StudioPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(draft.isEmpty && !rejectedOversizedDraft)
                .accessibilityLabel("Clear " + title.lowercased())
                .accessibilityIdentifier(id + "Clear")
                Text(units.symbol).foregroundStyle(StudioPalette.secondaryText)
                Button { apply() } label: {
                    Text("Set")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                    .disabled(rejectedOversizedDraft)
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Set " + title.lowercased())
                    .accessibilityIdentifier(id + "Set")
            }
            if invalid || rejectedOversizedDraft {
                Label(rejectedOversizedDraft
                      ? "That entry is too long. Your previous entry was kept. Edit the value, clear it or restore the current value before setting."
                      : "Enter a number from \(format(range.lowerBound)) to \(format(range.upperBound)) \(units.symbol). Current value is \(value.map { format($0) + " " + units.symbol } ?? "unmeasured").",
                      systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.primary)
                    .accessibilityIdentifier(id + "Error")
                Button { restoreDraft() } label: {
                    Text("Restore current value")
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .font(.subheadline)
                .accessibilityIdentifier(id + "Reset")
            }
        }
        .tint(StudioPalette.action)
        .onAppear { restoreDraft() }
        .onChange(of: value) { _, _ in restoreDraft() }
        .onChange(of: units) { _, _ in
            // Discard old-unit digits instead of committing them as a new unit.
            restoreDraft()
        }
        .onChange(of: locale) { _, _ in restoreDraft() }
    }

    private var boundedDraft: Binding<String> {
        Binding(get: { draft }, set: { replacement in
            guard StudioNumericInput.isWithinDraftLimit(replacement) else {
                rejectedOversizedDraft = true
                invalid = false
                return
            }
            // Focus changes can echo the same text through the binding. Only
            // an actual edit may clear a validation or oversize rejection.
            guard replacement != draft else { return }
            draft = replacement
            rejectedOversizedDraft = false
            invalid = false
        })
    }

    private func format(_ number: Double?) -> String {
        guard let number else { return "" }
        let displayed = units.fromMeters(number)
        guard displayed.isFinite else { return "Unavailable" }
        let separator = locale.decimalSeparator ?? "."
        // Keep existing metric drafts unchanged. Converted feet use a complete
        // decimal when it fits the room input grammar, including exact bounds.
        if units == .imperial,
           let exact = StudioNumericInput.editableText(displayed, decimalSeparator: separator),
           exact.count <= 24 {
            return exact
        }
        return RoomMeasurementInput.draft(displayed, decimalSeparator: separator)
    }

    private var displayRange: ClosedRange<Double>? {
        let lower = units.fromMeters(range.lowerBound)
        let upper = units.fromMeters(range.upperBound)
        guard range.lowerBound.isFinite, range.upperBound.isFinite,
              lower.isFinite, upper.isFinite, lower <= upper,
              units.toMeters(lower).isFinite, units.toMeters(upper).isFinite else { return nil }
        return lower...upper
    }

    private func restoreDraft() {
        draft = format(value)
        draftUnits = units
        draftLocale = locale
        draftValueBits = value?.bitPattern
        invalid = false
        rejectedOversizedDraft = false
        focused = false
    }

    private func rejectDraft() {
        // Make the validation result and explicit restore action reachable.
        focused = false
        invalid = true
    }

    private func apply() {
        // Environment and binding changes may render before their onChange
        // handlers run. Never interpret old digits in the new input context.
        guard draftUnits == units, draftLocale == locale,
              draftValueBits == value?.bitPattern else {
            restoreDraft()
            return
        }
        // A rejected paste must not commit the preceding draft, including an
        // empty draft that would otherwise clear an optional measurement.
        guard !rejectedOversizedDraft else { return }
        if allowsUnmeasured, draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if value != nil { value = nil }
            restoreDraft()
            return
        }
        // Applying an untouched formatted draft must not round its value.
        guard let displayRange else { rejectDraft(); return }
        if let value, value.isFinite, units.fromMeters(value).isFinite,
           draft == format(value), range.contains(value) {
            invalid = false
            focused = false
            return
        }
        let separator = locale.decimalSeparator ?? "."
        guard let entered = RoomMeasurementInput.parse(draft, decimalSeparator: separator,
                                                       in: 0...Double.greatestFiniteMagnitude) else {
            rejectDraft()
            return
        }
        if let value, value.isFinite, range.contains(value),
           entered == units.fromMeters(value) || entered == RoomMeasurementInput.parse(
               format(value), decimalSeparator: separator, in: 0...Double.greatestFiniteMagnitude) {
            // Numerically equivalent text (including added trailing zeroes)
            // must preserve the original SI precision and signed zero. A
            // rounded display may itself fall just outside the edit bounds.
            restoreDraft()
            return
        }
        guard displayRange.contains(entered) else { rejectDraft(); return }
        // Use the exact SI endpoints when their converted representation
        // would otherwise round one ULP outside the allowed meter range.
        let next: Double
        if entered == displayRange.lowerBound {
            next = range.lowerBound
        } else if entered == displayRange.upperBound {
            next = range.upperBound
        } else {
            next = units.toMeters(entered)
        }
        guard next.isFinite, range.contains(next), units.fromMeters(next).isFinite else {
            rejectDraft()
            return
        }
        value = next
        restoreDraft()
    }
}
