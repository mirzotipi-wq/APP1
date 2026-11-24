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

/// Manual alternative to AR. The studio receives committed, valid room edits.
struct ManualRoomPlacementView: View {
    let scene: LightingScene
    private let onChange: ((ManualRoom) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRawValue = PlanUnits.metric.rawValue
    @State private var room: ManualRoom
    @State private var notesSnapshot: NotesSnapshot?
    private var plan: RoomPlacementPlan? { try? RoomPlacementPlan(scene: scene, room: room) }
    private var units: PlanUnits { StudioPreferences.units(from: unitsRawValue) }

    init(scene: LightingScene, onChange: ((ManualRoom) -> Void)? = nil) {
        self.scene = scene
        self.onChange = onChange
        _room = State(initialValue: scene.placementRoom ?? ManualRoom())
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
                        Text("Enter real wall distances and the subject's floor position. Place each camera and light center using the measurements below, and check rectangular modifier projections.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let plan { placementSummary(plan) }
                    inputs
                    if let plan {
                        VStack(alignment: .leading, spacing: 10) {
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
                    Text("Center coordinates and rectangular emitting-face projections are calculated at 1:1 scale from your entries. Displayed distances are calculated, not a guarantee of measurement precision. These checks do not measure the actual room, detect collisions, include the entire fixture or guarantee clearance. Check housing, stands, booms, cables and ceiling clearance physically. Room measurements are included when you save the lighting project.")
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
            .sheet(item: $notesSnapshot) { snapshot in
                RoomPlacementNotesView(text: snapshot.text)
            }
            .onChange(of: room) { _, next in
                guard next.isValid else { return }
                onChange?(next)
            }
        }
    }

    /// Keep the committed placement result ahead of the editable measurements.
    /// Invalid drafts never masquerade as the actual room geometry.
    private func placementSummary(_ plan: RoomPlacementPlan) -> some View {
        let centerStatus = plan.outsideCount == 0
            ? "All \(plan.points.count) center positions inside room"
            : "\(plan.outsideCount) of \(plan.points.count) center positions outside room"
        return VStack(alignment: .leading, spacing: 8) {
            Text("Current measured layout").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Label(centerStatus,
                  systemImage: plan.outsideCount == 0 ? "checkmark.circle" : "exclamationmark.triangle")
                .font(.headline)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: centerStatus))
                .accessibilityIdentifier("roomPlacementStatus")
            if !plan.modifierFootprints.isEmpty {
                if plan.crossingModifierCount > 0 {
                    Label(plan.crossingModifierCount == 1 ? "1 rectangular modifier crosses a wall" :
                          "\(plan.crossingModifierCount) rectangular modifiers cross a wall",
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
            Text(plan.room.ceilingHeightMeters.map { "Ceiling height: \(distance($0))" } ?? "Ceiling height: Unmeasured")
                .font(.subheadline).foregroundStyle(.secondary)
                .accessibilityIdentifier("roomCeilingStatus")
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
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room dimensions").font(.headline)
            RoomMeasurementField(title: "Width", id: "roomWidth", value: $room.widthMeters,
                                 range: room.widthEditRange, units: units)
            RoomMeasurementField(title: "Depth", id: "roomDepth", value: $room.depthMeters,
                                 range: room.depthEditRange, units: units)
            Text("Room size changes keep the subject's wall offsets. To enter a smaller room, first move the subject closer to the corresponding wall.")
                .font(.caption).foregroundStyle(.secondary)
            RoomMeasurementField(title: "Ceiling height (optional)", id: "roomCeilingHeight",
                                 value: $room.ceilingHeightMeters, range: ManualRoom.dimensionRange, units: units)
            Text("Leave blank and press Set for unmeasured. Ceiling clearance is not calculated; check it physically.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Subject floor position").font(.headline)
            RoomMeasurementField(title: "From left wall", id: "roomSubjectX", value: $room.subjectX,
                                 range: 0...room.widthMeters, units: units)
            RoomMeasurementField(title: "From near wall", id: "roomSubjectZ", value: $room.subjectZ,
                                 range: 0...room.depthMeters, units: units)
            Divider()
            Text("Rig rotation").font(.headline)
            HStack {
                Slider(value: $room.yawDegrees, in: -180...180, step: 5)
                    .accessibilityLabel("Rig rotation")
                    .accessibilityValue("\(Int(room.yawDegrees)) degrees")
                    .accessibilityIdentifier("roomRotation")
                Text("\(Int(room.yawDegrees))°").monospacedDigit().frame(minWidth: 54, alignment: .trailing)
            }
            Button("Rotate 180°") { room.rotate(byDegrees: 180) }
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
                    Text(clearance < 0 ? "Projected wall overhang: \(distance(-clearance))" :
                         "Minimum projected wall distance: \(distance(clearance))")
                        .foregroundStyle(.secondary)
                }
            }
            Text("X from left wall: \(distance(point.xFromLeft))")
            Text("Z from near wall: \(distance(point.zFromNear))")
            Text("Height: \(distance(point.heightMeters)) · Floor distance to subject: \(distance(point.horizontalDistanceFromSubject))")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.monospacedDigit())
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .font(.subheadline).foregroundStyle(.secondary)
                        .accessibilityIdentifier("roomNotesScope")
                    ShareLink(item: text, subject: Text("Key & Fill room measurements")) {
                        Label("Share measurement notes", systemImage: "square.and.arrow.up")
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
    @State private var draft = ""
    @State private var invalid = false
    @FocusState private var focused: Bool

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
                TextField(allowsUnmeasured ? "Unmeasured" : (units == .metric ? "Meters" : "Feet"), text: $draft)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .accessibilityLabel(title + " in " + (units == .metric ? "meters" : "feet"))
                    .accessibilityIdentifier(id)
                    .onSubmit { apply() }
                Button {
                    draft = ""
                    invalid = false
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(draft.isEmpty)
                .accessibilityLabel("Clear " + title.lowercased())
                .accessibilityIdentifier(id + "Clear")
                Text(units.symbol).foregroundStyle(.secondary)
                Button("Set") { apply() }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Set " + title.lowercased())
                    .accessibilityIdentifier(id + "Set")
            }
            if invalid {
                Label("Enter a number from \(format(range.lowerBound)) to \(format(range.upperBound)) \(units.symbol). Current value is \(value.map { format($0) + " " + units.symbol } ?? "unmeasured").",
                      systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.primary)
                    .accessibilityIdentifier(id + "Error")
                Button("Restore current value") {
                    restoreDraft()
                }
                .font(.subheadline)
                .frame(minHeight: 44)
                .accessibilityIdentifier(id + "Reset")
            }
        }
        .onAppear { draft = format(value) }
        .onChange(of: value) { _, next in
            draft = format(next)
            invalid = false
        }
        .onChange(of: units) { _, _ in
            // Discard old-unit digits instead of committing them as a new unit.
            restoreDraft()
        }
        .onChange(of: locale) { _, _ in restoreDraft() }
        .onChange(of: draft) { _, _ in invalid = false }
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
        invalid = false
        focused = false
    }

    private func rejectDraft() {
        // Make the validation result and explicit restore action reachable.
        focused = false
        invalid = true
    }

    private func apply() {
        if allowsUnmeasured, draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            value = nil
            draft = ""
            invalid = false
            focused = false
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
        guard let entered = RoomMeasurementInput.parse(draft, decimalSeparator: locale.decimalSeparator ?? ".",
                                                       in: displayRange) else {
            rejectDraft()
            return
        }
        if let value, value.isFinite, range.contains(value),
           entered.bitPattern == units.fromMeters(value).bitPattern {
            restoreDraft()
            return
        }
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
        draft = format(next)
        invalid = false
        focused = false
    }
}
