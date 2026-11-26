import Foundation

/// Scalar light controls in scene units: meters, candela and kelvin.
public enum StudioLightField: CaseIterable, Equatable, Sendable {
    case x, y, z, candela, kelvin

    public var domain: ClosedRange<Double> {
        switch self {
        case .x, .y, .z: return Position.coordinateRange
        case .candela: return 0...100_000
        case .kelvin: return 1_000...20_000
        }
    }

    public func value(in light: StudioLight) -> Double {
        switch self {
        case .x: return light.position.x
        case .y: return light.position.y
        case .z: return light.position.z
        case .candela: return light.candela
        case .kelvin: return light.kelvin
        }
    }
}

/// Closed field edits for an already validated editor scene. Light commands
/// resolve a live UUID; they cannot change names, identity, schema or light count.
public enum StudioFieldCommand: Equatable, Sendable {
    case lightValue(id: UUID, field: StudioLightField, value: Double)
    case lightPosition(id: UUID, position: Position)
    case lightOptics(id: UUID, optics: LightOptics)
    case cameraPosition(Position)
    case subjectPosition(Position)
    case cameraLens(CameraLens)
    case previewSettings(PreviewSettings)
    case room(ManualRoom?)
}
