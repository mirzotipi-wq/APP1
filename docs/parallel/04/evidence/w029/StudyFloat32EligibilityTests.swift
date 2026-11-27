import Foundation
import XCTest
@testable import LightingCore

final class StudyFloat32EligibilityTests: XCTestCase {
    private func scene(light: StudioLight, focal: Double = 85) -> LightingScene {
        LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                      camera: .init(x: 0, y: 1.66, z: 2.3), lights: [light],
                      cameraLens: .init(focalLengthMillimeters: focal))
    }

    private func point(_ position: Position, candela: Double = 100) -> StudioLight {
        .init(name: "Precision fixture", position: position, candela: candela, kelvin: 5600)
    }

    func testOrdinaryStartupFixturesStayEligibleAndUnsupportedFixtureRoutesToCPU() {
        for fixture in StudyValidationFixtures.all() {
            XCTAssertEqual(StudyFloat32Eligibility.supports(fixture.scene), fixture.name != "near-field", fixture.name)
        }
        XCTAssertTrue(StudyFloat32Eligibility.supports(.portrait()))
        var disabled = StudyValidationFixtures.all().first { $0.name == "near-field" }!.scene
        disabled.lights[0].candela = 0
        XCTAssertTrue(StudyFloat32Eligibility.supports(disabled), "Disabled sources produce no samples or area guards")
    }

    func testCameraInsideSphereIsIneligibleAndRejectedByStudySetup() {
        let value = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 0.1), lights: [])
        XCTAssertThrowsError(try StudyComputeInput(scene: value, width: 24)) {
            XCTAssertEqual($0 as? StudyError, .invalidCamera)
        }
        XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: value, width: 24)) {
            XCTAssertEqual($0 as? StudyError, .invalidCamera)
        }
        XCTAssertFalse(StudyFloat32Eligibility.supports(value),
                       "A camera inside the study sphere cannot use the Float32 backend")
    }

    func testCameraBelowPanelIsIneligibleAndRejectedByStudySetup() {
        let value = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1, z: 3), lights: [])
        XCTAssertThrowsError(try StudyComputeInput(scene: value, width: 24)) {
            XCTAssertEqual($0 as? StudyError, .invalidCamera)
        }
        XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: value, width: 24)) {
            XCTAssertEqual($0 as? StudyError, .invalidCamera)
        }
        XCTAssertFalse(StudyFloat32Eligibility.supports(value),
                       "A camera below the study panel cannot use the Float32 backend")
    }

    func testMeasuredMicrometerCutoffRegressionsAndBothSidesOfBoundaryRouteToCPU() throws {
        // Exact scenes from the independent host-kernel probe. The first
        // mismatched by 10 nm at 1 m, the second by 1 µm at 20 m.
        for (distance, source) in [
            (1.0, Position(x: -0.00044872192385861007, y: 1.5004487219238587, z: 0.2699992442531467)),
            (20.0, Position(x: -0.011379302180595366, y: 1.5113793021805955, z: 0.26951898442381533))
        ] {
            var value = scene(light: point(source), focal: 200)
            value.camera = .init(x: 0, y: 1.5, z: distance)
            XCTAssertFalse(StudyFloat32Eligibility.supports(value))
        }
        for epsilon in [-1e-4, -1e-6, -1e-8, 0, 1e-8, 1e-6, 1e-4] {
            let value = scene(light: point(.init(x: 0, y: 1.5, z: 0.22 + 0.05 + epsilon)))
            XCTAssertFalse(StudyFloat32Eligibility.supports(value), "epsilon \(epsilon)")
        }
        let separated = scene(light: point(.init(x: 0, y: 1.5, z: 0.272)))
        XCTAssertTrue(StudyFloat32Eligibility.supports(separated))
        let encoded = try SceneCodec.encode(separated)
        _ = StudyFloat32Eligibility.supports(separated)
        XCTAssertEqual(try SceneCodec.encode(separated), encoded)
    }

    func testRelativeTwentyMeterDomainAndLargeWorldTranslationsArePreserved() {
        var value = scene(light: point(.init(x: 20, y: 1.5, z: 0)))
        value.camera = .init(x: 12, y: 1.5, z: 16) // Exactly 20 m from subject.
        XCTAssertTrue(StudyFloat32Eligibility.supports(value))
        for offset in [Position(x: 70, y: -50, z: 75), Position(x: -70, y: 50, z: -75)] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(translated(value, by: offset)))
        }
        value.camera = .init(x: 0, y: 1.5, z: 20.000001)
        XCTAssertFalse(StudyFloat32Eligibility.supports(value))
        value.camera.z = 20
        value.lights[0].position.x = 20.000001
        XCTAssertFalse(StudyFloat32Eligibility.supports(value))
    }

    func testCameraFrustumKeepsInvisiblePanelRegionsOutOfTheGuard() {
        // This light is 5 cm above the panel, but that panel region lies below
        // the 85 mm view. Widening to 14 mm exposes it and requires CPU routing.
        let source = point(.init(x: 0, y: 1.5 - 0.22 + 0.05, z: 1.2))
        var narrow = scene(light: source, focal: 85)
        var wide = scene(light: source, focal: 14)
        for yaw in [0.0, 37.0, 90.0, -121.0] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(rotated(narrow, degrees: yaw)), "narrow yaw \(yaw)")
            XCTAssertFalse(StudyFloat32Eligibility.supports(rotated(wide, degrees: yaw)), "wide yaw \(yaw)")
        }
        narrow = translated(narrow, by: .init(x: 65, y: 45, z: -60))
        wide = translated(wide, by: .init(x: 65, y: 45, z: -60))
        XCTAssertTrue(StudyFloat32Eligibility.supports(narrow))
        XCTAssertFalse(StudyFloat32Eligibility.supports(wide))
    }

    func testRectanglesUseTheirActualFaceAndSizeDependentNearFieldGuard() {
        // Horizontal 0.6 m face: the real guard is 0.15 m, not 0.05 m.
        for epsilon in [-1e-6, 1e-6] {
            let y = 1.5 + 0.22 + 0.15 + StudyFloat32Eligibility.surfaceMarginMeters + epsilon
            let light = StudioLight(name: "Horizontal area", position: .init(x: 0, y: y, z: 0),
                                    candela: 100, kelvin: 5600,
                                    optics: .init(kind: .rectangle, widthMeters: 0.6, heightMeters: 0.6))
            XCTAssertEqual(StudyFloat32Eligibility.supports(scene(light: light)), epsilon > 0)
        }
        // The center alone is far enough away, but the 4 m face extends across
        // the sphere and enters its 1 m near-field guard.
        let edgeNear = StudioLight(name: "Wide offset area", position: .init(x: 1.5, y: 2.5, z: 0),
                                   candela: 100, kelvin: 5600,
                                   optics: .init(kind: .rectangle, aimTarget: .init(x: 1.5, y: 1.5, z: 0),
                                                 widthMeters: 4, heightMeters: 0.2))
        XCTAssertFalse(StudyFloat32Eligibility.supports(scene(light: edgeNear)))
    }

    func testVisiblePanelGuardAccountsForTiltedEmitterExtentAndInvalidAim() {
        for height in [0.5, 0.9] {
            let position = Position(x: 0, y: 1.5 - 0.22 + height, z: 1.5)
            let light = StudioLight(name: "Tilted face", position: position, candela: 100, kelvin: 5600,
                                    optics: .init(kind: .rectangle,
                                                  aimTarget: .init(x: 0, y: position.y - 1, z: 2.5),
                                                  widthMeters: 0.6, heightMeters: 1.2))
            XCTAssertEqual(StudyFloat32Eligibility.supports(scene(light: light, focal: 14)), height > 0.5)
        }
        var invalid = scene(light: point(.init(x: 0, y: 2.5, z: 1)))
        invalid.lights[0].optics = .init(kind: .directional, aimTarget: invalid.lights[0].position)
        XCTAssertFalse(StudyFloat32Eligibility.supports(invalid))
        invalid.lights[0].candela = 0
        XCTAssertTrue(StudyFloat32Eligibility.supports(invalid), "Inactive sources do not require an emission frame")
        invalid.subject.x = .nan
        XCTAssertFalse(StudyFloat32Eligibility.supports(invalid))
    }

    func testMeasuredSilhouetteBoundaryAtRequestedWidthRoutesToCPU() throws {
        // Shared C++ Float32 kernel versus a transcribed C++ Double reference:
        // two pixels exceeded four levels at 24 x 16 (2 / 384 = 0.0052083333).
        // This host-derived routing fixture is not Swift or Metal parity evidence.
        let value = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 3), lights: [],
                                  cameraLens: .init(focalLengthMillimeters: 161.27198111190464))
        let packed = try StudyComputeInput(scene: value, width: 24)
        XCTAssertEqual(packed.width, 24)
        XCTAssertEqual(packed.height, 16)
        XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: 24),
                       "Eligibility must guard the silhouette at the requested pixel grid")

        // Read the shipped Double renderer directly: these are unlit sphere
        // pixels, not background or invalid-surface markers.
        let oracle = try ReferenceStudyRenderer.render(scene: value, width: 24)
        XCTAssertEqual(oracle.width, 24)
        XCTAssertEqual(oracle.height, 16)
        XCTAssertEqual(oracle.rgba.count, 24 * 16 * 4)
        XCTAssertEqual(oracle.unsupportedPixels, 0)
        for x in [9, 14] {
            let offset = 4 * x // Both recorded pixels are on row zero.
            XCTAssertEqual(Array(oracle.rgba[offset..<(offset + 4)]), [0, 0, 0, 255], "pixel (\(x), 0)")
            XCTAssertEqual(oracle.unsupportedPixelMask[x], 0, "pixel (\(x), 0)")
        }

        for width in [27, 48, 96, 192] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(value, width: width),
                          "The same scene clears the silhouette guard on the width-\(width) grid")
        }
        XCTAssertEqual(StudyFloat32Eligibility.supports(value),
                       StudyFloat32Eligibility.supports(value, width: 192),
                       "The legacy overload must retain the default compute width")
    }

    func testInvalidRequestedWidthsMatchComputeAndCPUResolutionRejection() {
        var value = LightingScene.portrait()
        value.lights = []
        for width in [Int.min, -24, 0, 21, 23, 25, 26, 191, 193, 195, Int.max] {
            XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: width), "width \(width)")
            XCTAssertThrowsError(try StudyComputeInput(scene: value, width: width), "width \(width)") {
                XCTAssertEqual($0 as? StudyError, .invalidResolution)
            }
            XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: value, width: width), "width \(width)") {
                XCTAssertEqual($0 as? StudyError, .invalidResolution)
            }
        }
    }

    func testValidResolutionEndpointsAndOddWidthsRemainAvailable() throws {
        var value = LightingScene.portrait()
        value.lights = []
        for width in [24, 27, 189, 192] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(value, width: width), "width \(width)")
            let packed = try StudyComputeInput(scene: value, width: width)
            XCTAssertEqual(packed.width, width)
            XCTAssertEqual(packed.height, width * 2 / 3)
        }
    }

    func testDisabledFarEmitterPreservesNoLightRoutingAndCPUImage() throws {
        var value = LightingScene.portrait()
        value.lights = [point(.init(x: 21, y: 1.5, z: 0), candela: 0)]
        for width in [24, 27, 192] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(value, width: width), "width \(width)")
            let packed = try StudyComputeInput(scene: value, width: width)
            XCTAssertTrue(packed.samples.isEmpty)
            XCTAssertTrue(packed.areas.isEmpty)
        }
        var unlit = value
        unlit.lights = []
        XCTAssertEqual(try ReferenceStudyRenderer.render(scene: value, width: 24),
                       try ReferenceStudyRenderer.render(scene: unlit, width: 24))

        value.lights[0].candela = 100
        for width in [24, 27, 192] {
            XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: width),
                           "The same source exceeds the distance domain when enabled; width \(width)")
        }
    }

    func testOddWidthSilhouetteCenterColumnIsCountedOnce() throws {
        // Fixed axial fixtures selected by an independent per-ray distance
        // scan. At width 51, only the top/bottom center pixels enter the shell;
        // counting each twice would incorrectly reject this grid. Width 27
        // also intersects the silhouette and cannot spend a whole pixel.
        for (width, focal, eligible) in [(27, 154.1293387912136, false), (51, 158.39589488231985, true)] {
            let value = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                      camera: .init(x: 0, y: 1.5, z: 3), lights: [],
                                      cameraLens: .init(focalLengthMillimeters: focal))
            let packed = try StudyComputeInput(scene: value, width: width)
            XCTAssertEqual(packed.width, width)
            XCTAssertEqual(packed.height, width * 2 / 3)
            XCTAssertEqual(StudyFloat32Eligibility.supports(value, width: width), eligible, "width \(width)")
        }
    }

    func testExactCameraClearanceBoundariesMatchStudySetup() throws {
        let subject = Position(x: 0, y: 1.5, z: 0)
        let geometry = try XCTUnwrap(StudyGeometry(center: subject))
        let cameras = [Position(x: 0, y: subject.y, z: geometry.radius + CameraFraming.minimumDepthMeters),
                       Position(x: 0, y: geometry.panelY + 0.01, z: 3)]
        for camera in cameras {
            let value = LightingScene(subject: subject, camera: camera, lights: [])
            XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: 24), "camera \(camera)")
            XCTAssertThrowsError(try StudyComputeInput(scene: value, width: 24)) {
                XCTAssertEqual($0 as? StudyError, .invalidCamera)
            }
            XCTAssertThrowsError(try ReferenceStudyRenderer.render(scene: value, width: 24)) {
                XCTAssertEqual($0 as? StudyError, .invalidCamera)
            }
        }
    }

    private func translated(_ source: LightingScene, by offset: Position) -> LightingScene {
        var value = source
        func move(_ p: Position) -> Position { .init(x: p.x + offset.x, y: p.y + offset.y, z: p.z + offset.z) }
        value.subject = move(value.subject); value.camera = move(value.camera)
        for index in value.lights.indices {
            value.lights[index].position = move(value.lights[index].position)
            if let aim = value.lights[index].optics?.aimTarget { value.lights[index].optics?.aimTarget = move(aim) }
        }
        return value
    }

    private func rotated(_ source: LightingScene, degrees: Double) -> LightingScene {
        var value = source
        let angle = degrees * .pi / 180, c = cos(angle), s = sin(angle)
        func rotate(_ p: Position) -> Position {
            let x = p.x - source.subject.x, z = p.z - source.subject.z
            return .init(x: source.subject.x + c * x + s * z, y: p.y,
                         z: source.subject.z - s * x + c * z)
        }
        value.camera = rotate(value.camera)
        for index in value.lights.indices {
            value.lights[index].position = rotate(value.lights[index].position)
            if let aim = value.lights[index].optics?.aimTarget { value.lights[index].optics?.aimTarget = rotate(aim) }
        }
        return value
    }
}
