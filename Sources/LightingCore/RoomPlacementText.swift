import Foundation

public extension RoomVerticalClearance {
    /// Shared wording for manual-placement UI and exports. The caller supplies
    /// a formatter so PDF/export units can differ without changing the geometry.
    /// Label the result as a center or ideal-face check, not equipment clearance.
    func statusSummary(distance: (Double) -> String) -> String {
        guard let floorDistance = minimumFloorClearanceMeters else {
            return isCeilingMeasured
                ? "Floor and measured ceiling distances unavailable; check aim."
                : "Floor distance unavailable; check aim. Ceiling unmeasured."
        }
        let floor: String
        if floorDistance < 0 {
            floor = "Below floor by \(distance(-floorDistance))"
        } else if floorDistance == 0 {
            floor = "Touches floor (\(distance(0)))"
        } else {
            floor = "Floor distance: \(distance(floorDistance))"
        }

        let ceiling: String
        if let ceilingDistance = minimumCeilingClearanceMeters {
            if ceilingDistance < 0 {
                ceiling = "Above measured ceiling by \(distance(-ceilingDistance))"
            } else if ceilingDistance == 0 {
                ceiling = "Touches measured ceiling (\(distance(0)))"
            } else {
                ceiling = "Measured ceiling distance: \(distance(ceilingDistance))"
            }
        } else {
            ceiling = isCeilingMeasured ? "Measured ceiling distance unavailable" : "Ceiling unmeasured"
        }
        return "\(floor); \(ceiling)."
    }

    func textSummary(locale: Locale = .current) -> String {
        statusSummary { RoomMeasurementDisplay.distance($0, locale: locale) }
    }
}

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
            room.ceilingHeightMeters.map { "Ceiling height: \(distance($0))" } ?? "Ceiling height: Unmeasured",
            "Subject floor position: X \(distance(room.subjectX)) from left wall; Z \(distance(room.subjectZ)) from near wall",
            "Rig rotation: \(rotation)°",
            "Positive rotation turns scene +Z toward room +X (the right wall).",
            "X is measured from the left wall; Z from the near wall. Negative coordinates lie beyond those walls. Height is above the studio floor.",
            "Center inside/outside labels describe the floor projection; height checks are listed separately.",
            "",
            "Centers outside room: \(outsideCount) of \(points.count)"
        ]
        if !modifierFootprints.isEmpty {
            lines.append("Rectangular emitting-face projections crossing a wall: \(crossingModifierCount); unavailable: \(unavailableModifierCount)")
        }
        let verticalExtent = room.ceilingHeightMeters == nil ? "below floor" : "below floor or above measured ceiling"
        let contactBoundaries = room.ceilingHeightMeters == nil ? "floor" : "floor or ceiling"
        lines.append("Centers \(verticalExtent): \(verticalOutsideCount); touching \(contactBoundaries): \(verticalTouchingPointCount)")
        if !modifierFootprints.isEmpty {
            lines.append("Rectangular emitting faces \(verticalExtent): \(verticalCrossingModifierCount); touching \(contactBoundaries): \(verticalTouchingModifierCount)")
        }
        if room.ceilingHeightMeters == nil {
            lines.append("Ceiling checks unavailable until a height is measured.")
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
                "Floor distance to subject: \(distance(point.horizontalDistanceFromSubject))",
                "Center height check: \(point.verticalClearance.textSummary(locale: locale))"
            ]
            guard let footprint = modifierFootprints.first(where: { $0.id.uuidString == point.id }) else {
                continue
            }
            lines.append("Emitting-face height check: \(footprint.verticalClearance.textSummary(locale: locale))")
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
            "Only center positions and ideal rectangular emitting faces are checked. Check complete fixtures, stands, booms, cables and working clearance physically. Displayed precision does not guarantee measurement accuracy.",
            "Height checks use face corners and center positions against a flat floor and, when measured, a flat horizontal ceiling. Contact means zero distance, not positive clearance.",
            "Save the lighting project to keep the editable room measurements with the setup. These notes are a snapshot of the placement."
        ]
        return lines.joined(separator: "\n")
    }
}
