import Foundation

public extension RoomPlacementPlan {
    /// A human-readable snapshot of the committed, validated placement. This is
    /// not an editable project document and does not change the room or scene.
    /// Point numbers disambiguate duplicate or display-truncated light names.
    func textSummary(locale: Locale = .current) -> String {
        func distance(_ value: Double) -> String {
            RoomMeasurementDisplay.distance(value, locale: locale)
        }
        let rotation = StudioNumericInput.formattedValue(room.yawDegrees, locale: locale)
        var lines = [
            "Key & Fill — Manual room placement",
            "",
            "Room width: \(distance(room.widthMeters))",
            "Room depth: \(distance(room.depthMeters))",
            "Subject floor position: X \(distance(room.subjectX)) from left wall; Z \(distance(room.subjectZ)) from near wall",
            "Rig rotation: \(rotation)°",
            "Positive rotation turns scene +Z toward room +X (the right wall).",
            "X is measured from the left wall; Z from the near wall. Negative coordinates lie beyond those walls. Height is above the studio floor.",
            "",
            "Centers outside room: \(outsideCount) of \(points.count)"
        ]
        if !modifierFootprints.isEmpty {
            lines.append("Rectangular emitting-face projections crossing a wall: \(crossingModifierCount); unavailable: \(unavailableModifierCount)")
        }
        for (index, point) in points.enumerated() {
            let boundedName = StudioDisplayName.display(point.name)
            let label = boundedName.isEmpty ? point.kind.rawValue.capitalized : boundedName
            lines += [
                "",
                "\(index + 1). \(label)",
                point.insideRoom ? "Center inside room" : "CENTER OUTSIDE ROOM",
                "X from left wall: \(distance(point.xFromLeft))",
                "Z from near wall: \(distance(point.zFromNear))",
                "Height: \(distance(point.heightMeters))",
                "Floor distance to subject: \(distance(point.horizontalDistanceFromSubject))"
            ]
            guard let footprint = modifierFootprints.first(where: { $0.id.uuidString == point.id }) else {
                continue
            }
            guard footprint.isAvailable else {
                lines.append("Emitting-face projection unavailable; check aim.")
                continue
            }
            if footprint.crossedWalls.isEmpty {
                lines.append("Emitting-face projection within room outline.")
            } else {
                let walls = footprint.crossedWalls.map(\.rawValue).joined(separator: ", ")
                lines.append("Emitting-face projection crosses \(walls) wall boundaries.")
            }
            if let clearance = footprint.minimumWallClearanceMeters {
                lines.append(clearance < 0
                    ? "Projected wall overhang: \(distance(-clearance))"
                    : "Minimum projected wall distance: \(distance(clearance))")
            }
        }
        lines += [
            "",
            "Computed at 1:1 scale from your entries. Manual measurements only; no room sensing or collision checking.",
            "Only equipment centers and ideal rectangular emitting faces are checked. Check complete fixtures, stands, booms, cables and ceiling clearance physically. Displayed precision does not guarantee measurement accuracy.",
            "Room settings are session-only. These notes preserve this placement without changing the saved lighting setup."
        ]
        return lines.joined(separator: "\n")
    }
}
