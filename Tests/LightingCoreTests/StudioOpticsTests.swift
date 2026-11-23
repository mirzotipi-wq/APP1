import Foundation
import XCTest
@testable import LightingCore

final class StudioOpticsTests: XCTestCase {
    private let origin = Position(x: 0, y: 0, z: 0)
    private func scene(camera: Position = .init(x: 0, y: 0, z: 3)) -> LightingScene {
        .init(subject: origin, camera: camera, lights: [.init(name: "Key", position: .init(x: 0, y: 0, z: 2), candela: 400, kelvin: 5600)])
    }
    private func dot(_ a: UnitDirection, _ b: UnitDirection) -> Double { a.x*b.x + a.y*b.y + a.z*b.z }

    func testLegacyDocumentMigratesWithoutLosingIDsOrSettings() throws {
        let json = """
        {"schemaVersion":1,"subject":{"x":0,"y":0,"z":0},"camera":{"x":0,"y":0,"z":3},
        "lights":[{"id":"72FA05BA-B155-4BA3-A6FA-B024074E85B6","name":"Legacy key","position":{"x":0,"y":0,"z":2},"candela":400,"kelvin":5600}]}
        """
        let migrated = try SceneCodec.decode(Data(json.utf8))
        XCTAssertEqual(migrated.schemaVersion, LightingScene.currentSchemaVersion)
        XCTAssertEqual(migrated.lights[0].id.uuidString, "72FA05BA-B155-4BA3-A6FA-B024074E85B6")
        XCTAssertEqual(migrated.lights[0].name, "Legacy key")
        XCTAssertEqual(migrated.lights[0].position, .init(x: 0, y: 0, z: 2))
        XCTAssertEqual(migrated.lights[0].candela, 400)
        XCTAssertEqual(migrated.lights[0].kelvin, 5600)
        XCTAssertNil(migrated.lights[0].optics)
        XCTAssertEqual(migrated.lights[0].effectiveOptics.kind, .point)
        XCTAssertEqual(StudioPhotometry.illuminance(for: migrated.lights[0], in: migrated), 100)
        XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(migrated)), migrated)
    }

    func testOpticsPersistAcrossSaveAndReopen() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SceneFileStore(url: folder.appendingPathComponent("project.json"))
        var s = scene()
        s.lights[0].optics = .init(kind: .rectangle, aimTarget: .init(x: 0.3, y: 0.2, z: 0), widthMeters: 1.2, heightMeters: 0.4)
        try store.save(s)
        XCTAssertEqual(try store.load(), s)
    }

    func testRejectInvalidOpticsAndMislabeledVersion() throws {
        var s = scene()
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 0)
        XCTAssertThrowsError(try SceneCodec.encode(s))
        s.lights[0].optics = .init(kind: .directional, aimTarget: .init(x: 101, y: 0, z: 0))
        XCTAssertThrowsError(try s.validated())
        s.lights[0].optics = .init(kind: .rectangle, heightMeters: .nan)
        XCTAssertThrowsError(try s.validated())
        s.lights[0].optics = .init(kind: .rectangle)
        s.schemaVersion = 1
        XCTAssertThrowsError(try s.validated())
        s.schemaVersion = 99
        XCTAssertThrowsError(try s.validated())
    }

    func testPointReceiverTracksCameraAndBackface() throws {
        let s = scene()
        XCTAssertEqual(StudioPhotometry.illuminance(for: s.lights[0], in: s), 100)
        let tilted = scene(camera: .init(x: sqrt(3), y: 0, z: 1))
        XCTAssertEqual(try XCTUnwrap(StudioPhotometry.illuminance(for: tilted.lights[0], in: tilted)), 50, accuracy: 1e-10)
        let back = scene(camera: .init(x: 0, y: 0, z: -3))
        XCTAssertEqual(StudioPhotometry.illuminance(for: back.lights[0], in: back), 0)
        let coincident = scene(camera: origin)
        XCTAssertNil(StudioPhotometry.illuminance(for: coincident.lights[0], in: coincident))
    }

    func testDirectionalCosineAndAimAway() throws {
        var s = scene()
        s.lights[0].optics = .init(kind: .directional)
        XCTAssertEqual(StudioPhotometry.illuminance(for: s.lights[0], in: s), 100)
        s.lights[0].optics?.aimTarget = .init(x: sqrt(3), y: 0, z: 1)
        XCTAssertEqual(try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s)), 50, accuracy: 1e-10)
        s.lights[0].optics?.aimTarget = .init(x: 0, y: 0, z: 3)
        XCTAssertEqual(StudioPhotometry.illuminance(for: s.lights[0], in: s), 0)
        let source = s.lights[0].position
        s.lights[0].optics?.aimTarget = source
        XCTAssertNil(StudioPhotometry.illuminance(for: s.lights[0], in: s))
    }

    func testFrameOrthonormalIncludingVertical() throws {
        for target in [Position(x: 1, y: 2, z: -3), .init(x: 0, y: 1, z: 0), .init(x: 0, y: -1, z: 0), .init(x: 0, y: 0, z: -1), .init(x: 1e-13, y: 1, z: 0)] {
            let f = try XCTUnwrap(EmitterFrame(source: origin, target: target))
            XCTAssertEqual(dot(f.right, f.up), 0, accuracy: 1e-10)
            XCTAssertEqual(dot(f.normal, f.right), 0, accuracy: 1e-10)
            XCTAssertEqual(dot(f.normal, f.up), 0, accuracy: 1e-10)
            let cross = try XCTUnwrap(UnitDirection(x: f.right.y*f.up.z-f.right.z*f.up.y, y: f.right.z*f.up.x-f.right.x*f.up.z, z: f.right.x*f.up.y-f.right.y*f.up.x))
            XCTAssertEqual(dot(cross, f.normal), 1, accuracy: 1e-10)
        }
        XCTAssertNil(EmitterFrame(source: origin, target: origin))
    }

    func testRectangleMatchesIndependentAnalyticAndRotatedScene() throws {
        var s = scene()
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.6)
        let a = 0.6, b = 0.3, d = 2.0
        let da = hypot(d, a), db = hypot(d, b)
        let expected = 800 / (1.2*0.6) * (a/da*atan(b/da) + b/db*atan(a/db))
        let actual = try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s))
        XCTAssertLessThan(abs(actual-expected)/expected, 0.01)
        s.camera = .init(x: 3, y: 0, z: 0)
        s.lights[0].position = .init(x: 2, y: 0, z: 0)
        XCTAssertEqual(try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s)), actual, accuracy: 1e-9)
        s.lights[0].optics?.aimTarget = .init(x: 3, y: 0, z: 0)
        XCTAssertEqual(StudioPhotometry.illuminance(for: s.lights[0], in: s), 0)
    }

    func testRectangleNearPlaneAbstainsAndDimensionsChangeEstimate() throws {
        var s = scene()
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 0.1, heightMeters: 0.1)
        let small = try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s))
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 2, heightMeters: 2)
        let large = try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s))
        XCTAssertLessThan(large, small)
        s.lights[0].position.z = 0.4
        XCTAssertNil(StudioPhotometry.illuminance(for: s.lights[0], in: s))
    }
}
