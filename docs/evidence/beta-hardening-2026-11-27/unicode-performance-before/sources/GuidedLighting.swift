import Foundation

/// These are observations entered by a person, not measurements extracted from pixels.
public struct ReferenceObservations: Equatable, Sendable {
    public enum Direction: String, CaseIterable, Sendable {
        case unknown = "Not sure", left = "Image left", center = "Centered", right = "Image right"
    }
    public enum Softness: String, CaseIterable, Sendable {
        case unknown = "Not sure", hard = "Hard edges", soft = "Soft edges"
    }
    public enum Fill: String, CaseIterable, Sendable {
        case unknown = "Not sure", none = "Minimal fill", restrained = "Restrained fill", balanced = "Balanced fill"
    }
    public enum Rim: String, CaseIterable, Sendable {
        case unknown = "Not sure", absent = "Not visible", visible = "Visible rim"
    }
    public var direction: Direction
    public var softness: Softness
    public var fill: Fill
    public var rim: Rim

    public init(direction: Direction = .unknown, softness: Softness = .unknown,
                fill: Fill = .unknown, rim: Rim = .unknown) {
        self.direction = direction; self.softness = softness; self.fill = fill; self.rim = rim
    }
}

/// The basis of a manually guided candidate, not a confidence score. A person's
/// categorical observation can guide a choice without measuring its geometry,
/// source power or color. All numeric values here are starting assumptions.
public struct GuidedRigBasis: Equatable, Sendable {
    public enum Cue: String, CaseIterable, Sendable {
        case direction = "Key side"
        case softness = "Shadow edges"
        case fill = "Shadow fill"
        case rim = "Rim highlight"
    }

    public enum Provenance: Equatable, Sendable {
        case userObservation, startingAssumption
    }

    /// The original, unmodified answers, including explicit "Not sure" values.
    public let observations: ReferenceObservations
    public let keyDistanceMeters: Double
    /// Angles in the camera-relative basis; these are not room/world angles.
    public let keyAzimuthDegrees: Double
    public let keyElevationDegrees: Double
    /// Incident illuminance on the camera-facing subject plane, not exposure.
    public let keyIlluminanceLux: Double
    /// The chosen ideal source temperature, not a recovered lamp spectrum.
    public let lightKelvin: Double

    /// Provenance applies only to the categorical cue, never to the exact
    /// numeric implementation. For example, "Soft edges" does not measure a
    /// softbox's dimensions, and "Restrained fill" does not measure a 4:1 ratio.
    public func provenance(for cue: Cue) -> Provenance {
        let unknown: Bool
        switch cue {
        case .direction: unknown = observations.direction == .unknown
        case .softness: unknown = observations.softness == .unknown
        case .fill: unknown = observations.fill == .unknown
        case .rim: unknown = observations.rim == .unknown
        }
        return unknown ? .startingAssumption : .userObservation
    }

    public var unobservedCues: [Cue] {
        Cue.allCases.filter { provenance(for: $0) == .startingAssumption }
    }
}

public struct GuidedRig: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let explanation: String
    public let scene: LightingScene
    /// Assumed incident illuminance at the camera-facing subject plane, NOT image exposure.
    public let keyLux: Double
    /// Assumed ratio of the key and fill contributions, not the photograph's contrast.
    public let keyToFillRatio: Double?
    public let basis: GuidedRigBasis
}

public enum GuidedRigError: Error, Equatable {
    case insufficientDirection, unsupportedGeometry
}

/// An explicitly assumption-based manual starting point. Two arrangements illustrate
/// ambiguity in source size, distance and intensity. Neither is an image reconstruction
/// or a statistically ranked hypothesis. The original scene is never mutated.
public enum GuidedLighting {
    public static func candidates(from observations: ReferenceObservations, in source: LightingScene) throws -> [GuidedRig] {
        guard observations.direction != .unknown else { throw GuidedRigError.insufficientDirection }
        guard let scene = try? source.validated(), let camera = CameraFraming(scene: scene) else {
            throw GuidedRigError.unsupportedGeometry
        }
        let sign: Double = observations.direction == .left ? -1 : observations.direction == .right ? 1 : 0
        let azimuthDegrees = sign * 35.0
        let elevationDegrees = 25.0
        let azimuth = azimuthDegrees * .pi / 180
        let elevation = elevationDegrees * .pi / 180
        let targetLux = 400.0 // Deliberately chosen working scale; not inferred from the photo.
        let lightKelvin = 5600.0

        func position(distance: Double, azimuth: Double, elevation: Double) -> Position {
            let r = distance * sin(azimuth) * cos(elevation)
            let u = distance * sin(elevation)
            let f = distance * cos(azimuth) * cos(elevation)
            return Position(x: scene.subject.x + r * camera.right.x + u * camera.up.x - f * camera.forward.x,
                            y: scene.subject.y + r * camera.right.y + u * camera.up.y - f * camera.forward.y,
                            z: scene.subject.z + r * camera.right.z + u * camera.up.z - f * camera.forward.z)
        }

        func light(name: String, at position: Position, optics: LightOptics, target: Double) throws -> StudioLight {
            var result = StudioLight(name: name, position: position, candela: 1, kelvin: lightKelvin, optics: optics)
            guard position.y >= 0.1, result.isValid,
                  let unitLux = StudioPhotometry.illuminance(for: result, in: scene),
                  unitLux.isFinite, unitLux > 1e-9 else { throw GuidedRigError.unsupportedGeometry }
            result.candela = target / unitLux
            guard result.isValid else { throw GuidedRigError.unsupportedGeometry }
            return result
        }

        func candidate(far: Bool) throws -> GuidedRig {
            let distance = far ? 2.25 : 1.5
            let ratio: Double?
            switch observations.fill {
            case .none: ratio = nil
            case .restrained: ratio = 4
            case .balanced: ratio = 2
            case .unknown: ratio = far ? 4 : nil
            }
            let soft = observations.softness == .soft || (observations.softness == .unknown && far)
            let optics = soft
                ? LightOptics(kind: .rectangle, widthMeters: 0.5 * distance, heightMeters: 0.7 * distance)
                : LightOptics(kind: .directional)
            let key = try light(name: "Key", at: position(distance: distance, azimuth: azimuth, elevation: elevation),
                                optics: optics, target: targetLux)
            var lights = [key]
            if let ratio {
                let fillAngle = sign == 0 ? -10.0 * .pi / 180 : -azimuth * 0.7
                lights.append(try light(name: "Fill",
                    at: position(distance: 1.8, azimuth: fillAngle, elevation: 0.1),
                    optics: .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 1.0),
                    target: targetLux / ratio))
            }
            if observations.rim == .visible {
                let rimPosition = position(distance: 1.8, azimuth: sign >= 0 ? -2.6 : 2.6, elevation: 0.35)
                let rim = StudioLight(name: "Rim", position: rimPosition, candela: 450, kelvin: lightKelvin,
                                      optics: .init(kind: .directional))
                guard rimPosition.y >= 0.1, rim.isValid else { throw GuidedRigError.unsupportedGeometry }
                lights.append(rim)
            }
            var candidate = scene
            candidate.lights = lights
            guard let valid = try? candidate.validated() else { throw GuidedRigError.unsupportedGeometry }
            let fillText = ratio.map { String(format: "%.0f:1 key-to-fill plane ratio", $0) } ?? "no fill source"
            let rimText = observations.rim == .visible ? "nominal rim" : "no rim source"
            let modifierText = soft ? "ideal rectangular emitter" : "ideal directional emitter"
            let explanation = String(format: "%.2f m key · %@ · %@ · %@. Assumed 400 lx key and 5600 K; neither is measured from the image.",
                                     distance, modifierText, fillText, rimText)
            return GuidedRig(id: far ? "far" : "near", title: far ? "Farther starting rig" : "Closer starting rig",
                             explanation: explanation, scene: valid, keyLux: targetLux, keyToFillRatio: ratio,
                             basis: GuidedRigBasis(observations: observations, keyDistanceMeters: distance,
                                                   keyAzimuthDegrees: azimuthDegrees,
                                                   keyElevationDegrees: elevationDegrees,
                                                   keyIlluminanceLux: targetLux, lightKelvin: lightKelvin))
        }

        // An unsupported alternative must not discard a usable arrangement.
        // Keep the original order and abstain only when neither rig is valid.
        let candidates = [false, true].compactMap { try? candidate(far: $0) }
        guard !candidates.isEmpty else { throw GuidedRigError.unsupportedGeometry }
        return candidates
    }
}
