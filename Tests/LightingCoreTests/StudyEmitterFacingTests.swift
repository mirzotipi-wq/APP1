import Foundation
import XCTest
@testable import LightingCore

final class StudyEmitterFacingTests: XCTestCase {
    private func vector(_ point: Position) -> SIMD3<Double> { .init(point.x, point.y, point.z) }
    private func vector(_ normal: UnitDirection) -> SIMD3<Double> { .init(normal.x, normal.y, normal.z) }
    private func position(_ value: SIMD3<Double>) -> Position { .init(x: value.x, y: value.y, z: value.z) }
    private func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
    private func unit(_ value: SIMD3<Double>) throws -> UnitDirection {
        try XCTUnwrap(UnitDirection(x: value.x, y: value.y, z: value.z))
    }

    private func scene(center: Position = .init(x: 0, y: 0, z: 0),
                       target: Position = .init(x: 0, y: 0, z: 1),
                       width: Double = 1, height: Double = 0.6, roll: Double = 0) -> LightingScene {
        .init(subject: .init(x: 0, y: 0, z: 0), camera: .init(x: 0, y: 0, z: 3), lights: [
            .init(name: "One-sided rectangle", position: center, candela: 1000, kelvin: 5600,
                  optics: .init(kind: .rectangle, aimTarget: target,
                                widthMeters: width, heightMeters: height, rollDegrees: roll))
        ])
    }

    private func signal(_ lighting: StudyLighting, receiver: Position,
                        normal: UnitDirection) throws -> StudySurfaceSignal {
        try lighting.evaluate(receiver: receiver, normal: normal, view: normal,
                              material: .diffuse(reflectance: 1))
    }

    private func assertDark(_ signal: StudySurfaceSignal,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(signal.visibleLux, 0, file: file, line: line)
        XCTAssertEqual(signal.unoccludedLux, 0, file: file, line: line)
        XCTAssertEqual(signal.signalXYZ, .init(x: 0, y: 0, z: 0), file: file, line: line)
    }

    func testBackFacingRectanglesRemainDarkAcrossAimRollAndWorldTranslation() throws {
        let cases: [(Position, SIMD3<Double>, Double)] = [
            (.init(x: 0, y: 0, z: 0), .init(0, 0, 1), 0),
            (.init(x: 0, y: 0, z: 0), .init(0, 1, 0), 90),
            (.init(x: 90, y: -88, z: 91), .init(0.3, -0.7, 0.4), 37),
            (.init(x: -90, y: 88, z: -91), .init(-0.7, 0.1, -0.6), -121)
        ]
        for quality in [StudyQuality.interactive, .reference] {
            for (center, aim, roll) in cases {
                let scene = scene(center: center, target: position(vector(center) + aim), roll: roll)
                let frame = try XCTUnwrap(StudioPhotometry.frame(for: scene.lights[0], subject: scene.subject))
                let axis = vector(frame.normal), right = vector(frame.right), up = vector(frame.up)
                let receiver = vector(center) - axis * 0.75 + right * 0.2 + up * 0.1
                let lighting = try StudyLighting(scene: scene, quality: quality)
                // Exercise both fully facing and clipped receiver hemispheres.
                for candidate in [axis, right + axis * 0.1, up - axis * 0.1] {
                    let normal = try unit(candidate), n = vector(normal)
                    var visibilityCalls = 0
                    let actual = try lighting.evaluate(receiver: receiver, normal: n, view: n,
                        material: .dielectric(reflectance: 0.34, roughness: 0.48, f0: 0.04),
                        occlusionTest: { _, _, _ in visibilityCalls += 1; return false },
                        geometricNormal: axis)
                    assertDark(actual)
                    XCTAssertEqual(visibilityCalls, 0)
                }
            }
        }
    }

    func testCoplanarAndSmallDepthReceiversRetainOriginalMidpointResult() throws {
        let scene = scene()
        let normal = try unit(.init(-1, 0, 0))
        // Outside the emitting face, these receivers satisfy the finite-area
        // separation guard even when their depth from its plane is zero.
        for (quality, grid) in [(StudyQuality.interactive, 8), (.reference, 32)] {
            let lighting = try StudyLighting(scene: scene, quality: quality)
            for depth in [-0.05, -0.049999999, -1e-10, 0, 1e-10, 0.049999999, 0.05] {
                let receiver = Position(x: 0.8, y: 0.1, z: depth)
                let actual = try signal(lighting, receiver: receiver, normal: normal)
                let expected = midpointLux(scene: scene, receiver: receiver, normal: normal, grid: grid)
                XCTAssertEqual(actual.visibleLux, expected, accuracy: max(1, expected) * 1e-12)
                XCTAssertEqual(actual.unoccludedLux, actual.visibleLux)
                if depth <= 0 { assertDark(actual) } else { XCTAssertGreaterThan(actual.visibleLux, 0) }
            }
        }
    }

    func testFrontFacingAndNarrowGrazingReceiversKeepPositiveLight() throws {
        let scene = scene()
        let receiver = Position(x: 0, y: 0, z: 0.25)
        let front = try unit(.init(0, 0, -1))
        let grazing = try unit(.init(1, 0, 0.499 / 0.25))
        let frame = try XCTUnwrap(StudioPhotometry.frame(for: scene.lights[0], subject: scene.subject))
        let emitter = try XCTUnwrap(LambertianRectangle(center: scene.lights[0].position,
            right: frame.right, up: frame.up, widthMeters: 1, heightMeters: 0.6, onAxisCandela: 1000))
        let grazingReference = try XCTUnwrap(Photometry.rectangularIlluminance(
            emitter: emitter, receiver: receiver, receiverNormal: grazing))
        for (quality, grid) in [(StudyQuality.interactive, 8), (.reference, 32)] {
            let lighting = try StudyLighting(scene: scene, quality: quality)
            let full = try signal(lighting, receiver: receiver, normal: front)
            let expected = midpointLux(scene: scene, receiver: receiver, normal: front, grid: grid)
            XCTAssertEqual(full.visibleLux, expected, accuracy: expected * 1e-12)
            let partial = try signal(lighting, receiver: receiver, normal: grazing)
            XCTAssertGreaterThan(partial.visibleLux, 0)
            XCTAssertLessThan(abs(partial.visibleLux - grazingReference) / grazingReference, 0.002)
        }
    }

    func testBackFacingSourcesCannotBypassNearFieldErrorsInMixedRig() throws {
        let normal = try unit(.init(0, 0, 1))
        for quality in [StudyQuality.interactive, .reference] {
            let lighting = try StudyLighting(scene: scene(), quality: quality)
            // Larger than the culling depth, but inside the rectangle's own
            // size-dependent 25 cm guard: still unsupported, never black.
            for depth in [-0.10, -0.249999999] {
                XCTAssertThrowsError(try signal(lighting, receiver: .init(x: 0, y: 0, z: depth), normal: normal)) {
                    XCTAssertEqual($0 as? StudyError, .invalidSurface)
                }
            }
            let small = try StudyLighting(scene: scene(width: 0.1, height: 0.1), quality: quality)
            XCTAssertThrowsError(try signal(small, receiver: .init(x: 0, y: 0, z: -0.05.nextDown), normal: normal)) {
                XCTAssertEqual($0 as? StudyError, .invalidSurface)
            }
            assertDark(try signal(small, receiver: .init(x: 0, y: 0, z: -0.05), normal: normal))

            var mixed = scene(center: .init(x: 0, y: 0, z: 1), target: .init(x: 0, y: 0, z: 2))
            mixed.lights.append(.init(name: "Unsupported point", position: .init(x: 0, y: 0, z: 0.04),
                                      candela: 500, kelvin: 5600))
            let withPoint = try StudyLighting(scene: mixed, quality: quality)
            XCTAssertThrowsError(try signal(withPoint, receiver: .init(x: 0, y: 0, z: 0), normal: normal)) {
                XCTAssertEqual($0 as? StudyError, .invalidSurface)
            }
            mixed.lights.removeLast()
            mixed.lights.append(scene(center: .init(x: 0, y: 0, z: 0.1),
                                       target: .init(x: 0, y: 0, z: 1)).lights[0])
            let withArea = try StudyLighting(scene: mixed, quality: quality)
            XCTAssertThrowsError(try signal(withArea, receiver: .init(x: 0, y: 0, z: 0), normal: normal)) {
                XCTAssertEqual($0 as? StudyError, .invalidSurface)
            }
        }
    }

    func testSkippingBackFacingAreaPreservesFollowingPointAndAreaContributions() throws {
        let normal = try unit(.init(0, 0, 1)), receiver = Position(x: 0, y: 0, z: 0)
        var original = scene(center: .init(x: 0.2, y: 0.1, z: 1), target: receiver)
        original.lights.append(.init(name: "Point", position: .init(x: -0.3, y: 0.2, z: 1.5),
                                    candela: 700, kelvin: 3200))
        let back = scene(center: .init(x: -0.1, y: 0.2, z: 1), target: .init(x: -0.1, y: 0.2, z: 2)).lights[0]
        for quality in [StudyQuality.interactive, .reference] {
            let reference = try signal(StudyLighting(scene: original, quality: quality), receiver: receiver, normal: normal)
            for index in 0...original.lights.count {
                var mixed = original
                mixed.lights.insert(back, at: index)
                let actual = try signal(StudyLighting(scene: mixed, quality: quality), receiver: receiver, normal: normal)
                XCTAssertEqual(actual, reference, "A zero-contribution block must preserve all subsequent sample indices/order")
            }
        }
    }

    func testMeshShadowOffsetAndReceiverHemisphereUseTheOutwardFace() throws {
        // An interior point of a fixed brow/eye mesh face, away from shared edges.
        func vertex(_ row: Int, _ column: Int) -> SIMD3<Double> {
            PortraitHeadMesh.surfacePoint(y: PortraitHeadMesh.ringY(row),
                angle: 2 * Double.pi * Double(column) / Double(PortraitHeadMesh.longitudeSegments))
        }
        let a = vertex(24, 3), b = vertex(24, 4), c = vertex(25, 3)
        let ab = b - a, ac = c - a
        let geometric = vector(try unit(.init(ab.y * ac.z - ab.z * ac.y,
            ab.z * ac.x - ab.x * ac.z, ab.x * ac.y - ab.y * ac.x)))
        let center = (a + b + c) / 3, camera = center + geometric * 0.01
        let hit = try XCTUnwrap(PortraitHeadMesh.standard.hit(origin: camera, direction: -geometric,
                                                             minimum: 1e-6, maximum: 0.02))
        XCTAssertEqual(hit.distance, 0.01, accuracy: 1e-10)
        XCTAssertGreaterThan(geometric.z, 0)
        XCTAssertEqual(dot(hit.geometricNormal, geometric), 1, accuracy: 1e-12)
        let receiver = camera - geometric * hit.distance
        let difference = hit.normal - geometric
        XCTAssertGreaterThan(dot(difference, difference), 1e-6,
                             "This fixture must distinguish smooth and geometric normals")
        // For distinct unit normals n and g, n-g faces n but lies behind g.
        let belowFace = vector(try unit(difference))
        XCTAssertGreaterThan(dot(hit.normal, belowFace), 0)
        XCTAssertLessThan(dot(geometric, belowFace), 0)

        for (lightDirection, frontFacing) in [(geometric, true), (belowFace, false)] {
            let source = receiver + lightDirection
            let scene = LightingScene(subject: position(receiver), camera: position(camera), lights: [
                .init(name: "Mesh normal probe", position: position(source), candela: 1000, kelvin: 5600)
            ])
            let lighting = try StudyLighting(scene: scene)
            var visibilityCalls = 0
            let actual = try lighting.evaluate(receiver: receiver, normal: hit.normal, view: geometric,
                material: .diffuse(reflectance: 1), occlusionTest: { origin, direction, distance in
                    visibilityCalls += 1
                    let offset = origin - receiver, outward = self.dot(offset, geometric)
                    XCTAssertGreaterThan(outward, 0)
                    let tangent = offset - geometric * outward
                    XCTAssertLessThan(sqrt(self.dot(tangent, tangent)), 1e-12,
                                      "A shading-normal offset slides the ray along the actual face")
                    let endpoint = origin + direction * distance
                    for axis in 0..<3 { XCTAssertEqual(endpoint[axis], source[axis], accuracy: 1e-12) }
                    return false
                }, geometricNormal: hit.geometricNormal)
            if frontFacing {
                XCTAssertEqual(visibilityCalls, 1)
                XCTAssertGreaterThan(actual.visibleLux, 0)
                XCTAssertEqual(actual.visibleLux, actual.unoccludedLux)
            } else {
                assertDark(actual)
                XCTAssertEqual(visibilityCalls, 0)
            }
        }
    }

    func testBackFacingRenderStillObservesPixelCancellation() throws {
        var scene = LightingScene.portrait()
        scene.lights = self.scene(center: .init(x: 0, y: 1.5, z: 10),
                                 target: .init(x: 0, y: 1.5, z: 11)).lights
        let renderers: [(() -> Bool) throws -> StudyImage] = [
            { try ReferenceStudyRenderer.render(scene: scene, width: 24, isCancelled: $0) },
            { try PortraitStudyRenderer.render(scene: scene, width: 24, isCancelled: $0) }
        ]
        for render in renderers {
            var calls = 0
            XCTAssertThrowsError(try render { calls += 1; return calls == 3 }) {
                XCTAssertEqual($0 as? StudyError, .cancelled)
            }
            XCTAssertEqual(calls, 3)
        }
    }

    /// Direct irradiance formula without normalized sample directions. Used
    /// only where the whole receiver hemisphere contains the rectangle, so
    /// its independent midpoint integration is the declared exact convention.
    private func midpointLux(scene: LightingScene, receiver: Position,
                             normal: UnitDirection, grid: Int) -> Double {
        let light = scene.lights[0], optics = light.effectiveOptics
        let frame = StudioPhotometry.frame(for: light, subject: scene.subject)!
        let center = vector(light.position), right = vector(frame.right), up = vector(frame.up)
        let axis = vector(frame.normal), n = vector(normal), p = vector(receiver)
        var total = 0.0
        for row in 0..<grid {
            let y = ((Double(row) + 0.5) / Double(grid) - 0.5) * optics.heightMeters
            for col in 0..<grid {
                let x = ((Double(col) + 0.5) / Double(grid) - 0.5) * optics.widthMeters
                let delta = center + right * x + up * y - p, r2 = dot(delta, delta)
                total += light.candela / Double(grid * grid)
                    * max(0, -dot(axis, delta)) * max(0, dot(n, delta)) / (r2 * r2)
            }
        }
        return total
    }
}
