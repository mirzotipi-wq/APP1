import Foundation

/// An ideal rectilinear full-frame camera. Focal length is actual millimeters,
/// not a zoom factor; distortion, focus breathing and depth of field are excluded.
public struct CameraLens: Codable, Equatable, Sendable {
    public static let sensorWidthMillimeters = 36.0
    public static let sensorHeightMillimeters = 24.0
    public static let focalLengthRange: ClosedRange<Double> = 14...200
    public var focalLengthMillimeters: Double

    public init(focalLengthMillimeters: Double = 50) {
        self.focalLengthMillimeters = focalLengthMillimeters
    }

    public var isValid: Bool {
        focalLengthMillimeters.isFinite && Self.focalLengthRange.contains(focalLengthMillimeters)
    }
}

extension LightingScene {
    public var effectiveCameraLens: CameraLens { cameraLens ?? .init() }
}

/// Coordinates on the ideal sensor: +x image right, +y image up, [-1, 1]
/// across the image. Values outside that interval are off-frame, not clamped.
public struct CameraProjection: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let depthMeters: Double
    public var isInsideFrame: Bool { abs(x) <= 1 && abs(y) <= 1 }
}

/// A camera aimed at the subject center. The world is right-handed; camera
/// forward is local -Z, so camera right is the negative of emitter-frame right.
public struct CameraFraming: Equatable, Sendable {
    public static let minimumDepthMeters = 0.05
    public static let aspectRatio = CameraLens.sensorWidthMillimeters / CameraLens.sensorHeightMillimeters
    public let position: Position
    public let target: Position
    public let lens: CameraLens
    public let right: UnitDirection
    public let up: UnitDirection
    public let forward: UnitDirection
    public let subjectDistanceMeters: Double

    public init?(scene: LightingScene) {
        let lens = scene.effectiveCameraLens
        let distance = scene.camera.distance(to: scene.subject)
        guard lens.isValid, distance >= Self.minimumDepthMeters,
              let frame = EmitterFrame(source: scene.camera, target: scene.subject),
              let right = UnitDirection(x: -frame.right.x, y: -frame.right.y, z: -frame.right.z) else { return nil }
        self.position = scene.camera; self.target = scene.subject; self.lens = lens
        self.right = right; self.up = frame.up; self.forward = frame.normal
        self.subjectDistanceMeters = distance
    }

    public var horizontalFieldOfViewDegrees: Double {
        2 * atan(CameraLens.sensorWidthMillimeters / (2 * lens.focalLengthMillimeters)) * 180 / .pi
    }
    public var verticalFieldOfViewDegrees: Double {
        2 * atan(CameraLens.sensorHeightMillimeters / (2 * lens.focalLengthMillimeters)) * 180 / .pi
    }
    /// Width and height of the subject plane perpendicular to the optical axis.
    public var subjectPlaneWidthMeters: Double {
        subjectDistanceMeters * CameraLens.sensorWidthMillimeters / lens.focalLengthMillimeters
    }
    public var subjectPlaneHeightMeters: Double {
        subjectDistanceMeters * CameraLens.sensorHeightMillimeters / lens.focalLengthMillimeters
    }

    public func project(_ world: Position) -> CameraProjection? {
        guard world.isValid else { return nil }
        let dx = world.x - position.x, dy = world.y - position.y, dz = world.z - position.z
        func dot(_ direction: UnitDirection) -> Double { dx * direction.x + dy * direction.y + dz * direction.z }
        let depth = dot(forward)
        guard depth >= Self.minimumDepthMeters else { return nil }
        return CameraProjection(x: 2 * lens.focalLengthMillimeters * dot(right) / (CameraLens.sensorWidthMillimeters * depth),
                                y: 2 * lens.focalLengthMillimeters * dot(up) / (CameraLens.sensorHeightMillimeters * depth),
                                depthMeters: depth)
    }
}
