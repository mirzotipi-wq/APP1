import Foundation
import XCTest
import LightingCore
@testable import KeyAndFill

final class SpatialViewportStateTests: XCTestCase {
    func testCoincidentAimBoundsIncludeTheVisibleFourMeterHousing() throws {
        let light = StudioLight(name: "Coincident softbox", position: .init(x: 0, y: 2, z: 0),
                                candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 2, z: 0),
                                              widthMeters: 4, heightMeters: 4))
        let scene = LightingScene(subject: .init(x: 0, y: 2, z: -0.1),
                                  camera: .init(x: 0, y: 2, z: 0.1), lights: [light])
        let bounds = try SpatialViewportBounds(scene: scene)
        XCTAssertLessThan(bounds.minimum.x, -2)
        XCTAssertGreaterThan(bounds.maximum.x, 2)
        XCTAssertLessThanOrEqual(bounds.minimum.y, 0)
        XCTAssertGreaterThan(bounds.maximum.y, 4)
        try assertFits(scene)
    }

    func testHorizontalWorldTranslationPreservesFitScaleAndRelativePose() throws {
        let scene = LightingScene.portrait()
        var moved = scene
        func move(_ p: Position) -> Position { .init(x: p.x + 80, y: p.y, z: p.z + 75) }
        moved.subject = move(scene.subject)
        moved.camera = move(scene.camera)
        for index in moved.lights.indices { moved.lights[index].position = move(scene.lights[index].position) }
        var original = SpatialOrbitState(), translated = SpatialOrbitState()
        original.fit(try SpatialViewportBounds(scene: scene))
        translated.fit(try SpatialViewportBounds(scene: moved))
        XCTAssertEqual(original.distance, translated.distance, accuracy: 1e-12)
        XCTAssertEqual(translated.position.x - original.position.x, 80, accuracy: 1e-12)
        XCTAssertEqual(translated.position.z - original.position.z, 75, accuracy: 1e-12)
        XCTAssertEqual(original.farDistance, translated.farDistance, accuracy: 1e-12)
        try assertFits(moved)
    }

    func testFitIncludesHighStandBasesAndExtremeSparseAndCrowdedRigs() throws {
        var high = LightingScene.portrait()
        high.subject.y = 90
        high.camera.y = 90
        for index in high.lights.indices { high.lights[index].position.y = 90 }
        XCTAssertEqual(try SpatialViewportBounds(scene: high).minimum.y, 0)
        try assertFits(high)
        try assertFits(.init(subject: .init(x: 100, y: -100, z: 100),
                             camera: .init(x: 100, y: -100, z: 100), lights: []))
        var crowded = LightingScene.portrait()
        crowded.lights = (0..<12).map { index in
            StudioLight(name: "Light \(index)",
                        position: .init(x: index.isMultiple(of: 2) ? -99 : 99,
                                        y: Double(index) * 8, z: Double(index) * 17 - 95),
                        candela: 900, kelvin: 5600,
                        optics: .init(kind: .rectangle, widthMeters: 4, heightMeters: 0.05,
                                      rollDegrees: Double(index) * 29 - 170))
        }
        try assertFits(crowded)
    }

    func testNonGeometricEditsDoNotChangeViewportBounds() throws {
        var scene = LightingScene.portrait()
        let bounds = try SpatialViewportBounds(scene: scene)
        scene.lights[0].name = "Renamed key"
        scene.lights[0].candela = 0
        scene.lights[1].kelvin = 3200
        scene.lights.reverse()
        scene.cameraLens = .init(focalLengthMillimeters: 200)
        XCTAssertEqual(try SpatialViewportBounds(scene: scene), bounds)
    }

    func testInvalidSceneIsRejectedBeforeBoundsConstruction() {
        var scene = LightingScene.portrait()
        scene.lights.append(scene.lights[0])
        XCTAssertThrowsError(try SpatialViewportBounds(scene: scene))
        scene = .portrait(); scene.camera.x = .nan
        XCTAssertThrowsError(try SpatialViewportBounds(scene: scene))
    }

    func testAimTargetSphereIsContainedBeyondItsAuthoredCenter() throws {
        let light = StudioLight(name: "Aimed", position: .init(x: 0, y: 2, z: 0), candela: 900, kelvin: 5600,
                                optics: .init(kind: .directional, aimTarget: .init(x: 1, y: 2, z: 0)))
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0), camera: .init(x: 0, y: 1.5, z: 3),
                                  lights: [light])
        let bounds = try SpatialViewportBounds(scene: scene)
        // The native marker is a 55 mm diameter sphere; a center-only bound
        // would stop at x=1 and fail this actual displayed-volume contract.
        XCTAssertEqual(bounds.maximum.x, 1.0275, accuracy: 1e-12)
        try assertFits(scene)
    }

    func testPanUsesTheSmallerViewportAxisAndDoesNotChangeCameraDistance() throws {
        var landscape = SpatialOrbitState(), portrait = SpatialOrbitState()
        let before = landscape
        landscape.pan(horizontal: 10, vertical: 0, width: 600, height: 240)
        portrait.pan(horizontal: 10, vertical: 0, width: 240, height: 600)
        XCTAssertEqual(landscape, portrait)
        XCTAssertEqual(landscape.distance, before.distance)
        let displacement = before.target.distance(to: landscape.target)
        XCTAssertEqual(displacement, 10 * 2 * before.distance * tan(24 * .pi / 180) / 240, accuracy: 1e-12)
        XCTAssertLessThan(landscape.target.x, before.target.x)
        XCTAssertGreaterThan(landscape.target.z, before.target.z)
    }

    func testInvalidGestureSamplesCannotPoisonNavigation() {
        var orbit = SpatialOrbitState()
        let before = orbit
        for invalid in [Double.nan, .infinity, -.infinity] {
            orbit.orbit(horizontal: invalid, vertical: 1)
            orbit.orbit(horizontal: 1, vertical: invalid)
            orbit.pan(horizontal: invalid, vertical: 1, width: 360, height: 240)
            orbit.pan(horizontal: 1, vertical: 1, width: invalid, height: 240)
            orbit.zoom(scale: invalid)
        }
        orbit.zoom(scale: 0)
        orbit.zoom(scale: -1)
        orbit.pan(horizontal: 10, vertical: 10, width: 0, height: 240)
        XCTAssertEqual(orbit, before)
        XCTAssertNil(SpatialOrbitState.verticalFieldOfView(width: 0, height: 240))
        XCTAssertNil(SpatialOrbitState.verticalFieldOfView(width: .infinity, height: 240))
    }

    func testGestureLimitsAndFitRecoveryRemainFinite() throws {
        var orbit = SpatialOrbitState()
        orbit.orbit(horizontal: .greatestFiniteMagnitude, vertical: .greatestFiniteMagnitude)
        orbit.zoom(scale: .leastNonzeroMagnitude)
        XCTAssertEqual(orbit.distance, 1_500)
        XCTAssertLessThanOrEqual(abs(orbit.pitch), 1.35)
        XCTAssertTrue(orbit.position.x.isFinite && orbit.position.y.isFinite && orbit.position.z.isFinite)
        orbit.zoom(scale: .greatestFiniteMagnitude)
        XCTAssertEqual(orbit.distance, 0.45)
        orbit.pan(horizontal: 100_000, vertical: 100_000, width: 120, height: 600)
        XCTAssertLessThanOrEqual(abs(orbit.target.x), 300)
        XCTAssertLessThanOrEqual(abs(orbit.target.y), 300)
        XCTAssertLessThanOrEqual(abs(orbit.target.z), 300)
        let bounds = try SpatialViewportBounds(scene: .portrait())
        orbit.fit(bounds)
        var fresh = SpatialOrbitState(); fresh.fit(bounds)
        XCTAssertEqual(orbit, fresh)
    }

    func testFarClippingEnclosesTheAuthoredWorldAfterExtremePanAndOrbit() {
        var orbit = SpatialOrbitState()
        orbit.pan(horizontal: -100_000, vertical: 100_000, width: 120, height: 600)
        XCTAssertEqual(orbit.target, .init(x: 300, y: 300, z: -300))
        let yaw = 3 * Double.pi / 4
        let pitch = asin(1 / sqrt(3.0))
        orbit.orbit(horizontal: (orbit.yaw - yaw) / 0.008, vertical: (pitch - orbit.pitch) / 0.008)
        orbit.zoom(scale: .greatestFiniteMagnitude)
        let opposite = Position(x: -100, y: -100, z: 100)
        let depth = orbit.position.distance(to: opposite)
        XCTAssertGreaterThan(depth, 690)
        XCTAssertLessThan(depth, orbit.farDistance)
    }

    private func assertFits(_ scene: LightingScene, file: StaticString = #filePath, line: UInt = #line) throws {
        let bounds = try SpatialViewportBounds(scene: scene)
        var orbit = SpatialOrbitState(); orbit.fit(bounds)
        let position = orbit.position
        // Independent pinhole projection from camera location/target, without
        // using the navigation implementation's yaw or pitch formula.
        let dx = position.x - orbit.target.x, dy = position.y - orbit.target.y, dz = position.z - orbit.target.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)
        let back = (x: dx / length, y: dy / length, z: dz / length)
        let horizontal = sqrt(back.x * back.x + back.z * back.z)
        let right = (x: back.z / horizontal, y: 0.0, z: -back.x / horizontal)
        let up = (x: back.y * right.z, y: back.z * right.x - back.x * right.z, z: -back.y * right.x)
        for (width, height) in [(360.0, 240.0), (120.0, 600.0), (600.0, 120.0), (1.0, 1000.0)] {
            let fov = try XCTUnwrap(SpatialOrbitState.verticalFieldOfView(width: width, height: height))
            for x in [bounds.minimum.x, bounds.maximum.x] {
                for y in [bounds.minimum.y, bounds.maximum.y] {
                    for z in [bounds.minimum.z, bounds.maximum.z] {
                        let delta = (x: x - position.x, y: y - position.y, z: z - position.z)
                        let depth = -(delta.x * back.x + delta.y * back.y + delta.z * back.z)
                        let halfHeight = depth * tan(fov * .pi / 360)
                        let sx = (delta.x * right.x + delta.y * right.y + delta.z * right.z) / (halfHeight * width / height)
                        let sy = (delta.x * up.x + delta.y * up.y + delta.z * up.z) / halfHeight
                        XCTAssertGreaterThan(depth, 0.02, file: file, line: line)
                        XCTAssertLessThan(depth, orbit.farDistance, file: file, line: line)
                        XCTAssertLessThan(abs(sx), 1, file: file, line: line)
                        XCTAssertLessThan(abs(sy), 1, file: file, line: line)
                    }
                }
            }
        }
    }
}
