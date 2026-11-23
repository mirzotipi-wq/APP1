import Foundation
import XCTest
@testable import LightingCore

final class ColorimetryTests: XCTestCase {
    private func scene(kelvin: Double = 5600, candela: Double = 1000) -> LightingScene {
        .init(subject: .init(x: 0, y: 0, z: 0), camera: .init(x: 0, y: 0, z: 3), lights: [
            .init(name: "Test", position: .init(x: 0, y: 0, z: 1), candela: candela, kelvin: kelvin)
        ])
    }

    func testPlanckianChromaticityAgainstPublishedReference() throws {
        // CIE illuminant A, approximately 2856 K: x=0.44757, y=0.40745 (CIE 1931 2°).
        // Approximation is not a replacement for the tabulated standard observer.
        let a = try XCTUnwrap(PreviewColorimetry.blackbody(kelvin: 2856))
        let xy = try XCTUnwrap(a.chromaticity)
        XCTAssertEqual(a.y, 1, accuracy: 1e-12)
        XCTAssertEqual(xy.x, 0.44757, accuracy: 0.003)
        XCTAssertEqual(xy.y, 0.40745, accuracy: 0.003)
        print("2856 K approximate chromaticity: \(xy.x), \(xy.y)")
        // 6500 K blackbody is distinct from D65 daylight.
        let daylight = try XCTUnwrap(PreviewColorimetry.blackbody(kelvin: 6500)?.chromaticity)
        XCTAssertEqual(daylight.x, 0.31349, accuracy: 0.003)
        XCTAssertEqual(daylight.y, 0.32366, accuracy: 0.003)
        print("6500 K approximate chromaticity: \(daylight.x), \(daylight.y)")
    }

    func testMatchedWhiteBalanceNeutralizesGrayCard() throws {
        for k in [2000.0, 2856, 5600, 10000] {
            var s = scene(kelvin: k)
            s.previewSettings = .init(whiteBalanceKelvin: k)
            let card = try XCTUnwrap(NeutralCardPreview(scene: s))
            XCTAssertEqual(card.totalLux, 1000, accuracy: 1e-9)
            XCTAssertEqual(card.incidentXYZ.y, 1000, accuracy: 1e-9)
            XCTAssertEqual(card.display.red, card.display.green, accuracy: 1e-6)
            XCTAssertEqual(card.display.green, card.display.blue, accuracy: 1e-6)
            // 18% reflectance at 1000 lx, Reinhard then sRGB encoding.
            let expected = 1.055 * pow(0.18 / 1.18, 1 / 2.4) - 0.055
            XCTAssertEqual(card.display.green, expected, accuracy: 1e-6)
        }
    }

    func testWarmCoolAndBalance() throws {
        let warm = try XCTUnwrap(NeutralCardPreview(scene: scene(kelvin: 2856)))
        let cool = try XCTUnwrap(NeutralCardPreview(scene: scene(kelvin: 10000)))
        XCTAssertGreaterThan(warm.display.red, warm.display.blue)
        XCTAssertGreaterThan(cool.display.blue, cool.display.red)
        var s = scene(kelvin: 5600)
        s.previewSettings = .init(whiteBalanceKelvin: 3200)
        let balanced = try XCTUnwrap(NeutralCardPreview(scene: s))
        XCTAssertGreaterThan(balanced.display.blue, balanced.display.red)
    }

    func testSceneLinearAdditivityAndExposureStops() throws {
        var s = scene(kelvin: 3200, candela: 500)
        let one = try XCTUnwrap(NeutralCardPreview(scene: s))
        let another = try XCTUnwrap(NeutralCardPreview(scene: scene(kelvin: 6500, candela: 250)))
        s.lights.append(scene(kelvin: 6500, candela: 250).lights[0])
        let combined = try XCTUnwrap(NeutralCardPreview(scene: s))
        XCTAssertEqual(combined.totalLux, 750, accuracy: 1e-9)
        XCTAssertEqual(combined.incidentXYZ.x, one.incidentXYZ.x + another.incidentXYZ.x, accuracy: 1e-9)
        XCTAssertEqual(combined.incidentXYZ.y, one.incidentXYZ.y + another.incidentXYZ.y, accuracy: 1e-9)
        XCTAssertEqual(combined.incidentXYZ.z, one.incidentXYZ.z + another.incidentXYZ.z, accuracy: 1e-9)
        var neutral = scene(candela: 500)
        neutral.previewSettings = .init(exposureStops: 1)
        let exposed = try XCTUnwrap(NeutralCardPreview(scene: neutral))
        let doubled = try XCTUnwrap(NeutralCardPreview(scene: scene(candela: 1000)))
        XCTAssertEqual(exposed.totalLux, 500)
        XCTAssertEqual(exposed.display.red, doubled.display.red, accuracy: 1e-12)
        XCTAssertEqual(exposed.display.green, doubled.display.green, accuracy: 1e-12)
        XCTAssertEqual(exposed.display.blue, doubled.display.blue, accuracy: 1e-12)
    }

    func testExtremeValidSettingsStayInDisplayGamut() throws {
        for k in [1000.0, 2000, 5600, 10000, 20000] {
            for white in [2000.0, 5600, 10000] {
                for ev in [-6.0, 0, 6] {
                    var s = scene(kelvin: k, candela: 100000)
                    s.previewSettings = .init(whiteBalanceKelvin: white, exposureStops: ev)
                    let card = try XCTUnwrap(NeutralCardPreview(scene: s), "\(k) K / \(white) K / \(ev) stops")
                    XCTAssertTrue([card.display.red, card.display.green, card.display.blue].allSatisfy { $0.isFinite && (0...1).contains($0) })
                }
            }
        }
    }

    func testBlackAndUnsupportedGeometryAreDistinct() throws {
        var s = scene(candela: 0)
        s.lights[0].position = s.subject
        let off = try XCTUnwrap(NeutralCardPreview(scene: s))
        XCTAssertEqual(off.totalLux, 0)
        XCTAssertEqual(off.display.red, 0); XCTAssertEqual(off.display.green, 0); XCTAssertEqual(off.display.blue, 0)
        s.lights[0].candela = 1
        XCTAssertNil(NeutralCardPreview(scene: s))
        s = scene(); s.camera = s.subject
        XCTAssertNil(NeutralCardPreview(scene: s))
        XCTAssertNil(PreviewColorimetry.blackbody(kelvin: .nan))
        XCTAssertNil(PreviewColorimetry.blackbody(kelvin: 999))
        XCTAssertNil(PreviewColorimetry.display(.init(x: .infinity, y: 1, z: 1), settings: .init()))
    }

    func testRejectInvalidSceneRatherThanSummingDuplicateOrExcessLights() throws {
        var s = scene()
        s.lights.append(s.lights[0])
        XCTAssertNil(NeutralCardPreview(scene: s))
        s.lights = (0..<13).map { _ in scene().lights[0] }
        XCTAssertNil(NeutralCardPreview(scene: s))
    }

    func testPreviewSettingsMigrationAndRoundTrip() throws {
        var old = scene(); old.schemaVersion = 3
        old.cameraLens = .init(focalLengthMillimeters: 85)
        let migrated = try SceneCodec.decode(JSONEncoder().encode(old))
        XCTAssertEqual(migrated.schemaVersion, LightingScene.currentSchemaVersion)
        XCTAssertEqual(migrated.effectivePreviewSettings, .init())
        XCTAssertEqual(migrated.cameraLens, old.cameraLens)
        var s = migrated; s.previewSettings = .init(whiteBalanceKelvin: 3200, exposureStops: -1.5)
        let decoded = try SceneCodec.decode(SceneCodec.encode(s))
        XCTAssertEqual(decoded, s)
        s.schemaVersion = 3
        XCTAssertThrowsError(try s.validated())
        s.schemaVersion = LightingScene.currentSchemaVersion
        s.previewSettings?.exposureStops = .nan
        XCTAssertThrowsError(try SceneCodec.encode(s))
        s.previewSettings = .init(whiteBalanceKelvin: 10001)
        XCTAssertThrowsError(try SceneCodec.encode(s))
    }
}
