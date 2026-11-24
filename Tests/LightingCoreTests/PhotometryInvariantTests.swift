import Foundation
import XCTest
@testable import LightingCore

/// Coordinate and reciprocity checks complement the absolute analytic fixtures.
/// These validate the ideal model's invariants, not equipment calibration.
final class PhotometryInvariantTests: XCTestCase {
    private func direction(_ value: SIMD3<Double>) throws -> UnitDirection {
        try XCTUnwrap(UnitDirection(x: value.x, y: value.y, z: value.z))
    }

    private func position(_ value: SIMD3<Double>) -> Position {
        .init(x: value.x, y: value.y, z: value.z)
    }

    private func vector(_ value: Position) -> SIMD3<Double> {
        .init(value.x, value.y, value.z)
    }

    private func vector(_ value: UnitDirection) -> SIMD3<Double> {
        .init(value.x, value.y, value.z)
    }

    /// Three elementary proper rotations, independent of production frames.
    private func rotate(_ p: SIMD3<Double>, angles: SIMD3<Double>) -> SIMD3<Double> {
        let (sx, cx) = (sin(angles.x), cos(angles.x))
        let (sy, cy) = (sin(angles.y), cos(angles.y))
        let (sz, cz) = (sin(angles.z), cos(angles.z))
        let x = SIMD3(p.x, cx * p.y - sx * p.z, sx * p.y + cx * p.z)
        let y = SIMD3(cy * x.x + sy * x.z, x.y, -sy * x.x + cy * x.z)
        return .init(cz * y.x - sz * y.y, sz * y.x + cz * y.y, y.z)
    }

    private func assertSame(_ actual: Double, _ expected: Double,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual, expected, accuracy: max(1, abs(expected)) * 1e-9,
                       file: file, line: line)
    }

    func testPointAndClippedRectangleAreInvariantUnderRigidCoordinateChanges() throws {
        let source = SIMD3<Double>(0, 0, 0)
        let receiver = SIMD3<Double>(0.27, -0.11, 0.8)
        let normals: [SIMD3<Double>] = [.init(0.2, 0.1, -1), .init(1, 0.5, 0.1), .init(0, 0, 1)]
        let baseline = try XCTUnwrap(LambertianRectangle(
            center: position(source), right: direction(.init(1, 0, 0)), up: direction(.init(0, 1, 0)),
            widthMeters: 1.2, heightMeters: 0.8, onAxisCandela: 1375))
        let transforms: [(SIMD3<Double>, SIMD3<Double>)] = [
            (.init(0, 0, 0), .init(73, -68, 64)),
            (.init(0.37, -1.21, 2.03), .init(-12.3, 8.7, 20.2)),
            (.init(-1.7, 0.81, -0.42), .init(4.5, -3.25, 1.75)),
            (.init(.pi / 2, -.pi / 2, .pi), .zero)
        ]
        for normalVector in normals {
            let normal = try direction(normalVector)
            let pointLux = try XCTUnwrap(Photometry.pointIlluminance(
                candela: 1375, source: position(source), receiver: position(receiver), receiverNormal: normal))
            let rectangleLux = try XCTUnwrap(Photometry.rectangularIlluminance(
                emitter: baseline, receiver: position(receiver), receiverNormal: normal))
            for (angles, offset) in transforms {
                let changedSource = position(rotate(source, angles: angles) + offset)
                let changedReceiver = position(rotate(receiver, angles: angles) + offset)
                let changedNormal = try direction(rotate(vector(normal), angles: angles))
                let changedEmitter = try XCTUnwrap(LambertianRectangle(
                    center: changedSource,
                    right: direction(rotate(.init(1, 0, 0), angles: angles)),
                    up: direction(rotate(.init(0, 1, 0), angles: angles)),
                    widthMeters: 1.2, heightMeters: 0.8, onAxisCandela: 1375))
                assertSame(try XCTUnwrap(Photometry.pointIlluminance(
                    candela: 1375, source: changedSource, receiver: changedReceiver,
                    receiverNormal: changedNormal)), pointLux)
                assertSame(try XCTUnwrap(Photometry.rectangularIlluminance(
                    emitter: changedEmitter, receiver: changedReceiver,
                    receiverNormal: changedNormal)), rectangleLux)
            }
        }
    }

    func testGeometricallySimilarFiniteSourcesFollowInverseAreaScaling() throws {
        let source = SIMD3<Double>(0.1, -0.2, 0.3)
        let receiver = SIMD3<Double>(0.3, -0.3, 1.0)
        let right = try direction(.init(1, 0, 0)), up = try direction(.init(0, 1, 0))
        for normalVector in [SIMD3<Double>(0.2, -0.1, -1), .init(1, 0.5, 0.1)] {
            let normal = try direction(normalVector)
            let base = try XCTUnwrap(LambertianRectangle(center: position(source), right: right, up: up,
                widthMeters: 0.8, heightMeters: 0.5, onAxisCandela: 875))
            let expected = try XCTUnwrap(Photometry.rectangularIlluminance(
                emitter: base, receiver: position(receiver), receiverNormal: normal))
            XCTAssertGreaterThan(expected, 0)
            for scale in [0.25, 0.5, 2.0, 4.0] {
                let scaled = try XCTUnwrap(LambertianRectangle(center: position(source * scale), right: right, up: up,
                    widthMeters: 0.8 * scale, heightMeters: 0.5 * scale, onAxisCandela: 875))
                let actual = try XCTUnwrap(Photometry.rectangularIlluminance(
                    emitter: scaled, receiver: position(receiver * scale), receiverNormal: normal))
                // Fixed on-axis intensity with all lengths scaled by s gives E/s².
                assertSame(actual * scale * scale, expected)
            }
        }
    }

    func testOffNormalDielectricResponseIsReciprocalAfterIncidenceNormalization() throws {
        let receiver = Position(x: 0, y: 0, z: 0)
        let normal = try direction(.init(0, 0, 1))
        let pairs: [(SIMD3<Double>, SIMD3<Double>)] = [
            (.init(0.4, -0.2, 1), .init(-0.3, 0.6, 1)),
            (.init(1, 0, 0.04), .init(-0.8, 0.3, 0.07)),
            (.init(-0.2, 1, 0.3), .init(0.5, -0.7, 0.2))
        ]
        func response(light: UnitDirection, view: UnitDirection, material: StudyMaterial) throws -> Double {
            let scene = LightingScene(subject: receiver, camera: position(vector(view) * 3), lights: [
                .init(name: "Reciprocity source", position: position(vector(light) * 2), candela: 1250, kelvin: 5600)
            ])
            let sample = try StudyLighting(scene: scene).evaluate(
                receiver: receiver, normal: normal, view: view, material: material)
            XCTAssertGreaterThan(sample.visibleLux, 0)
            // Y is normalized to one for the source color. Removing incident
            // illuminance isolates π·BRDF, which is reciprocal in L and V.
            return sample.signalXYZ.y * 1000 / sample.visibleLux
        }
        for (lightVector, viewVector) in pairs {
            let light = try direction(lightVector), view = try direction(viewVector)
            for roughness in [0.05, 0.32, 1.0] {
                for f0 in [0.0, 0.04, 0.08] {
                    let material = StudyMaterial.dielectric(reflectance: 0.18, roughness: roughness, f0: f0)
                    let forward = try response(light: light, view: view, material: material)
                    let reverse = try response(light: view, view: light, material: material)
                    XCTAssertTrue(forward.isFinite)
                    XCTAssertGreaterThanOrEqual(forward, 0)
                    assertSame(reverse, forward)
                }
            }
        }
    }

    func testMixedStudioRigKeepsMeterAndStudyValuesAfterYawAndTranslation() throws {
        let subject = Position(x: 0.3, y: 1.4, z: -0.2)
        let scene = LightingScene(subject: subject, camera: .init(x: 0.7, y: 1.6, z: 3.1), lights: [
            .init(name: "Point", position: .init(x: -1.2, y: 2.3, z: 1.8), candela: 740, kelvin: 3200),
            .init(name: "Manual aimed", position: .init(x: 1.4, y: 1.9, z: 1.5), candela: 430, kelvin: 6500,
                  optics: .init(kind: .directional, aimTarget: .init(x: 0.1, y: 1.6, z: -0.4))),
            .init(name: "Subject aimed", position: .init(x: -0.4, y: 2.7, z: 0.9), candela: 980, kelvin: 5000,
                  optics: .init(kind: .rectangle, widthMeters: 0.7, heightMeters: 1.1))
        ])
        let normal = try XCTUnwrap(StudioPhotometry.receiverNormal(in: scene))
        let reference = try StudyLighting(scene: scene, quality: .reference).evaluate(
            receiver: subject, normal: normal, view: normal,
            material: .dielectric(reflectance: 0.18, roughness: 0.37, f0: 0.04))
        let meters = try scene.lights.map { try XCTUnwrap(StudioPhotometry.illuminance(for: $0, in: scene)) }
        // Studio modifier roll is fixed by world up, so its rigid-scene contract
        // is yaw plus translation, not arbitrary pitch/roll of the entire rig.
        for yaw in [-2.43, -0.31, 1.17, .pi] {
            let angles = SIMD3<Double>(0, yaw, 0), offset = SIMD3<Double>(51, -48, 63)
            func changed(_ p: Position) -> Position { position(rotate(vector(p), angles: angles) + offset) }
            var moved = scene
            moved.subject = changed(scene.subject)
            moved.camera = changed(scene.camera)
            for index in moved.lights.indices {
                moved.lights[index].position = changed(scene.lights[index].position)
                if let target = scene.lights[index].optics?.aimTarget {
                    moved.lights[index].optics?.aimTarget = changed(target)
                }
            }
            _ = try moved.validated()
            for index in moved.lights.indices {
                assertSame(try XCTUnwrap(StudioPhotometry.illuminance(for: moved.lights[index], in: moved)), meters[index])
            }
            let movedNormal = try XCTUnwrap(StudioPhotometry.receiverNormal(in: moved))
            let actual = try StudyLighting(scene: moved, quality: .reference).evaluate(
                receiver: moved.subject, normal: movedNormal, view: movedNormal,
                material: .dielectric(reflectance: 0.18, roughness: 0.37, f0: 0.04))
            assertSame(actual.visibleLux, reference.visibleLux)
            assertSame(actual.unoccludedLux, reference.unoccludedLux)
            assertSame(actual.signalXYZ.x, reference.signalXYZ.x)
            assertSame(actual.signalXYZ.y, reference.signalXYZ.y)
            assertSame(actual.signalXYZ.z, reference.signalXYZ.z)
        }
    }
}
