import Foundation
import XCTest
@testable import LightingCore

final class ReferenceStudyTests: XCTestCase {
    private let normal = UnitDirection(x: 0, y: 0, z: 1)!
    private let up = UnitDirection(x: 0, y: 1, z: 0)!
    private let origin = Position(x: 0, y: 0, z: 0)

    private func scene(light: StudioLight) -> LightingScene {
        .init(subject: origin, camera: .init(x: 0, y: 0, z: 3), lights: [light])
    }
    private func point(_ position: Position = .init(x: 0, y: 0, z: 1)) -> StudioLight {
        .init(name: "Reference", position: position, candela: 1000, kelvin: 5600)
    }

    func testLambertianSignalMatchesAnalyticLuxAndCard() throws {
        let s = scene(light: point())
        let prepared = try StudyLighting(scene: s)
        XCTAssertEqual(prepared.sampleCount, 1)
        let sample = try prepared.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 0.18))
        XCTAssertEqual(sample.visibleLux, 1000, accuracy: 1e-12)
        XCTAssertEqual(sample.unoccludedLux, 1000, accuracy: 1e-12)
        XCTAssertEqual(sample.signalXYZ.y, 0.18, accuracy: 1e-12)
        let display = try XCTUnwrap(PreviewColorTransform(settings: .init())?.display(sample.signalXYZ))
        let card = try XCTUnwrap(NeutralCardPreview(scene: s))
        XCTAssertEqual(display.red, card.display.red, accuracy: 1e-12)
        XCTAssertEqual(display.green, card.display.green, accuracy: 1e-12)
        XCTAssertEqual(display.blue, card.display.blue, accuracy: 1e-12)
    }

    func testDirectionalAndRectangleAdapterAgreeWithExistingPhotometry() throws {
        var s = scene(light: point(.init(x: 0.4, y: 0.2, z: 1.5)))
        for kind in [EmitterKind.directional, .rectangle] {
            s.lights[0].optics = .init(kind: kind, widthMeters: 1.0, heightMeters: 0.6)
            let expected = try XCTUnwrap(StudioPhotometry.illuminance(for: s.lights[0], in: s))
            let reference = try StudyLighting(scene: s, quality: .reference)
            let sample = try reference.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 1))
            XCTAssertEqual(sample.visibleLux, expected, accuracy: 1e-8)
            XCTAssertEqual(reference.sampleCount, kind == .rectangle ? 1024 : 1)
            let fast = try StudyLighting(scene: s, quality: .interactive)
            let approximate = try fast.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 1))
            XCTAssertLessThan(abs(approximate.visibleLux - expected) / expected, 0.05)
        }
    }

    func testAreaConvergenceAcrossRotatedReceivers() throws {
        var s = scene(light: point(.init(x: 0, y: 0, z: 1)))
        var maxError = 0.0
        for size in [0.3, 0.8, 1.2] {
            s.lights[0].optics = .init(kind: .rectangle, widthMeters: size, heightMeters: size * 0.7)
            let fine = try StudyLighting(scene: s, quality: .reference)
            let coarse = try StudyLighting(scene: s, quality: .interactive)
            for x in [-0.35, 0.0, 0.35] {
                let p = Position(x: x, y: 0.12, z: 0.2)
                let n = try XCTUnwrap(UnitDirection(x: 0.2, y: -0.1, z: 1))
                let a = try fine.evaluate(receiver: p, normal: n, view: n, material: .diffuse(reflectance: 1))
                let b = try coarse.evaluate(receiver: p, normal: n, view: n, material: .diffuse(reflectance: 1))
                let relative = abs(a.visibleLux - b.visibleLux) / a.visibleLux
                maxError = max(maxError, relative)
                XCTAssertLessThan(relative, 0.05)
            }
        }
        print("Study 8x8 vs 32x32, 9 unoccluded fixtures, max relative error: \(maxError)")
    }

    func testSphereOcclusionAndFiniteSourcePenumbra() throws {
        let center = Position(x: 0, y: 1, z: 0)
        let geometry = try XCTUnwrap(StudyGeometry(center: center))
        var s = LightingScene(subject: center, camera: .init(x: 0, y: 1.2, z: 3), lights: [point(.init(x: 0, y: 2, z: 0))])
        let hard = try StudyLighting(scene: s)
        let contact = Position(x: 0, y: geometry.panelY, z: 0)
        let shadow = try hard.evaluate(receiver: contact, normal: up, view: up, material: .diffuse(reflectance: 1), geometry: geometry)
        XCTAssertGreaterThan(shadow.unoccludedLux, 0)
        XCTAssertEqual(shadow.visibleLux, 0)
        let open = Position(x: 1, y: geometry.panelY, z: 0)
        let clear = try hard.evaluate(receiver: open, normal: up, view: up, material: .diffuse(reflectance: 1), geometry: geometry)
        XCTAssertEqual(clear.visibleLux, clear.unoccludedLux, accuracy: 1e-10)
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 1.2)
        let soft = try StudyLighting(scene: s, quality: .reference)
        let edge = Position(x: 0.31, y: geometry.panelY, z: 0)
        let partial = try soft.evaluate(receiver: edge, normal: up, view: up, material: .diffuse(reflectance: 1), geometry: geometry)
        XCTAssertGreaterThan(partial.visibleLux, 0)
        XCTAssertLessThan(partial.visibleLux, partial.unoccludedLux)
        let hardEdge = try hard.evaluate(receiver: edge, normal: up, view: up, material: .diffuse(reflectance: 1), geometry: geometry)
        XCTAssertEqual(hardEdge.visibleLux, hardEdge.unoccludedLux, accuracy: 1e-10)
        print("Soft shadow fixture visible fraction: \(partial.visibleLux / partial.unoccludedLux)")
    }

    func testGGXNormalIncidenceAndRoughness() throws {
        let prepared = try StudyLighting(scene: scene(light: point()))
        let gloss = try prepared.evaluate(receiver: origin, normal: normal, view: normal,
                                          material: .dielectric(reflectance: 0.18, roughness: 0.5, f0: 0.04))
        let rough = try prepared.evaluate(receiver: origin, normal: normal, view: normal,
                                          material: .dielectric(reflectance: 0.18, roughness: 1, f0: 0.04))
        XCTAssertEqual(gloss.visibleLux, rough.visibleLux, accuracy: 1e-12)
        // N=L=V: D*pi = 1/roughness^4, correlated Smith denominator=4.
        XCTAssertEqual(gloss.signalXYZ.y, 0.18 * 0.96 + 0.04 / (4 * pow(0.5, 4)), accuracy: 1e-12)
        XCTAssertEqual(rough.signalXYZ.y, 0.18 * 0.96 + 0.04 / 4, accuracy: 1e-12)
        XCTAssertGreaterThan(gloss.signalXYZ.y, rough.signalXYZ.y)
    }

    func testInvalidNearFieldDegenerateAndSurfaceInputs() throws {
        let near = try StudyLighting(scene: scene(light: point(.init(x: 0, y: 0, z: 0.04))))
        XCTAssertThrowsError(try near.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 1))) { XCTAssertEqual($0 as? StudyError, .invalidSurface) }
        var s = scene(light: point(.init(x: 0, y: 0, z: 0.1)))
        s.lights[0].optics = .init(kind: .rectangle, widthMeters: 1, heightMeters: 1)
        let nearArea = try StudyLighting(scene: s)
        XCTAssertThrowsError(try nearArea.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: 1))) { XCTAssertEqual($0 as? StudyError, .invalidSurface) }
        let emitterPosition = s.lights[0].position; s.lights[0].optics?.aimTarget = emitterPosition
        XCTAssertThrowsError(try StudyLighting(scene: s)) { XCTAssertEqual($0 as? StudyError, .invalidEmitter) }
        s.lights[0].candela = 0
        XCTAssertEqual(try StudyLighting(scene: s).sampleCount, 0)
        let normalLight = try StudyLighting(scene: scene(light: point()))
        XCTAssertThrowsError(try normalLight.evaluate(receiver: origin, normal: normal, view: normal, material: .diffuse(reflectance: -0.1)))
        XCTAssertThrowsError(try normalLight.evaluate(receiver: origin, normal: normal, view: UnitDirection(x: 0, y: 0, z: -1)!, material: .diffuse(reflectance: 1)))
    }

    func testDeterministicImageAndDarkScene() throws {
        var s = LightingScene.portrait()
        let image = try ReferenceStudyRenderer.render(scene: s, width: 48)
        XCTAssertEqual(image, try ReferenceStudyRenderer.render(scene: s, width: 48))
        XCTAssertEqual(image.width, 48); XCTAssertEqual(image.height, 32)
        XCTAssertEqual(image.rgba.count, 48 * 32 * 4)
        XCTAssertEqual(image.unsupportedPixels, 0)
        let bytes = [UInt8](image.rgba)
        XCTAssertTrue(stride(from: 3, to: bytes.count, by: 4).allSatisfy { bytes[$0] == 255 })
        let center = 4 * (16 * 48 + 24)
        XCTAssertGreaterThan(bytes[center], 0)
        s.lights = []
        let dark = [UInt8](try ReferenceStudyRenderer.render(scene: s, width: 48).rgba)
        XCTAssertEqual(Array(dark[center..<(center + 3)]), [0, 0, 0])
        XCTAssertEqual(Array(dark[0..<3]), [18, 20, 24])
    }

    func testRendererCancellationAndBounds() throws {
        let s = LightingScene.portrait()
        for width in [0, 23, 25, 195] {
            XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: s, width: width)) { XCTAssertEqual($0 as? StudyError, .invalidResolution) }
        }
        XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: s, width: 120, quality: .reference)) { XCTAssertEqual($0 as? StudyError, .invalidResolution) }
        var calls = 0
        XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: s, width: 48, isCancelled: { calls += 1; return calls >= 3 })) { XCTAssertEqual($0 as? StudyError, .cancelled) }
        var invalid = s; invalid.camera = invalid.subject
        XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: invalid, width: 48)) { XCTAssertEqual($0 as? StudyError, .invalidCamera) }
    }

    func testNearFieldPixelsAreDiagnosticNotBlack() throws {
        var s = LightingScene.portrait()
        s.lights = [.init(name: "Too close", position: s.subject, candela: 1000, kelvin: 5600,
                          optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 1.5, z: 1), widthMeters: 1, heightMeters: 1))]
        let image = try ReferenceStudyRenderer.render(scene: s, width: 48)
        XCTAssertGreaterThan(image.unsupportedPixels, 0)
        let rgba = [UInt8](image.rgba)
        let count = stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0] == 255 && rgba[$0+1] == 0 && rgba[$0+2] == 255 }.count
        XCTAssertEqual(count, image.unsupportedPixels)
    }
}
