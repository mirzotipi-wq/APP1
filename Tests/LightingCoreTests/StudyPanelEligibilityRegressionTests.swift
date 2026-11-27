import Foundation
import XCTest
@testable import LightingCore

final class StudyPanelEligibilityRegressionTests: XCTestCase {
    func testMeasuredPanelEdgeFailuresRouteToCPUWithoutRejectingStudyInput() throws {
        // Exact Swift Double images versus the unchanged shared C++ Float32
        // kernel at f08cf66: width 24 had mean 0.96875, maximum 24 and
        // fractionAboveFour 0.046875; width 192 had fraction 0.00732422.
        // These are host measurements, not native Metal execution evidence.
        for (width, cameraY) in [(24, 2.2147825986956517), (192, 2.125549738219895)] {
            let value = overheadScene(distance: cameraY)
            XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: width), "width \(width)")
            let input = try StudyComputeInput(scene: value, width: width)
            XCTAssertEqual(input.width, width)
            XCTAssertTrue(input.samples.isEmpty)
            let oracle = try ReferenceStudyRenderer.render(scene: value, width: width)
            XCTAssertEqual(oracle.unsupportedPixels, 0)
            let expectedMask = Data(repeating: 0, count: width * (width * 2 / 3))
            XCTAssertEqual(oracle.unsupportedPixelMask, expectedMask)
            if width == 24 {
                // Both outer columns really meet the unlit panel in Double.
                // Choosing CPU retains those surfaces instead of background.
                for y in 0..<oracle.height {
                    for x in [0, width - 1] {
                        let offset = 4 * (y * width + x)
                        XCTAssertEqual(Array(oracle.rgba[offset..<(offset + 4)]), [0, 0, 0, 255])
                    }
                }
            }
        }
    }

    func testConstructedOverheadEdgesAcrossPixelGridsAndBothSidesOfBoundary() {
        // An outer pixel has |px| = (1 - 1/width)*18/f. For a vertical
        // camera its panel coordinate is (distance + radius)*px.
        for width in [24, 27, 48, 96, 189, 192] {
            let distance = 3 / ((1 - 1 / Double(width)) * 18 / 14) - 0.22
            for epsilon in [-1e-7, -1e-8, 0, 1e-8, 1e-7] {
                XCTAssertFalse(StudyFloat32Eligibility.supports(overheadScene(distance: distance + epsilon), width: width),
                               "width \(width), epsilon \(epsilon)")
            }
        }
    }

    func testPanelEdgeRoutingSurvivesLargeWorldTranslations() throws {
        for width in [24, 192] {
            let distance = 3 / ((1 - 1 / Double(width)) * 18 / 14) - 0.22
            for offset in [Position(x: 70, y: -50, z: 75), Position(x: -70, y: 50, z: -75)] {
                var value = overheadScene(distance: distance)
                value.subject = offset
                value.camera = .init(x: offset.x, y: offset.y + distance, z: offset.z)
                XCTAssertNoThrow(try value.validated())
                XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: width), "width \(width), offset \(offset)")
                XCTAssertEqual(try StudyComputeInput(scene: value, width: width).width, width)
            }
        }
    }

    func testObliqueRowsProtectBothPanelAxesAndBothSigns() throws {
        // With the camera aligned to a panel axis, an edge spans a complete
        // image row. Both signs remain risky at low and default resolutions.
        for width in [24, 192] {
            for (yaw, axis) in [(0.0, 2), (90.0, 0)] {
                for (y, sign) in [(0, -1.0), (width * 2 / 3 - 1, 1.0)] {
                    let value = try edgeScene(width: width, x: width / 2, y: y,
                                              yaw: yaw, elevation: 70, axis: axis, sign: sign)
                    let point = try panelPoint(scene: value, width: width, x: width / 2, y: y)
                    XCTAssertEqual(point[axis], sign * 3, accuracy: 1e-12)
                    XCTAssertLessThan(abs(point[2 - axis]), 3)
                    XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: width),
                                   "width \(width), axis \(axis), sign \(sign)")
                }
            }
        }
    }

    func testRotatedPanelEdgesProtectIndividualPixelCenters() throws {
        // Construct edge intersections independently through ray/plane
        // geometry. A width-24 frame cannot spend even one uncertain pixel.
        let cases: [(yaw: Double, axis: Int, sign: Double, x: Int, y: Int)] = [
            (37, 0, -1, 3, 6), (37, 0, 1, 20, 15),
            (37, 2, -1, 15, 2), (37, 2, 1, 0, 13),
            (-121, 0, -1, 23, 13), (-121, 0, 1, 8, 2),
            (-121, 2, -1, 3, 15), (-121, 2, 1, 15, 2)
        ]
        for item in cases {
            let value = try edgeScene(width: 24, x: item.x, y: item.y,
                                      yaw: item.yaw, elevation: 65, axis: item.axis, sign: item.sign)
            let point = try panelPoint(scene: value, width: 24, x: item.x, y: item.y)
            XCTAssertEqual(point[item.axis], item.sign * 3, accuracy: 1e-12)
            XCTAssertLessThan(abs(point[2 - item.axis]), 3)
            XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: 24), "\(item)")
        }
    }

    func testPanelGuardUsesRequestedGridAndDefaultOverload() {
        let value = overheadScene(distance: 3 / ((1 - 1.0 / 24) * 18 / 14) - 0.22)
        XCTAssertFalse(StudyFloat32Eligibility.supports(value, width: 24))
        for width in [27, 48, 96, 192] {
            XCTAssertTrue(StudyFloat32Eligibility.supports(value, width: width), "width \(width)")
        }
        XCTAssertEqual(StudyFloat32Eligibility.supports(value), StudyFloat32Eligibility.supports(value, width: 192))
    }

    func testSeparatedOverheadAndOrdinaryWideRotatedScenesRemainEligible() {
        var wide = LightingScene(subject: .init(x: 0, y: 0, z: 0),
                                 camera: .init(x: 1.2, y: 1.5, z: 2.3), lights: [],
                                 cameraLens: .init(focalLengthMillimeters: 14))
        for width in [24, 27, 189, 192] {
            for distance in [1.0, 2.0, 3.0] {
                XCTAssertTrue(StudyFloat32Eligibility.supports(overheadScene(distance: distance), width: width),
                              "width \(width), distance \(distance)")
            }
            XCTAssertTrue(StudyFloat32Eligibility.supports(wide, width: width), "wide width \(width)")
            XCTAssertTrue(StudyFloat32Eligibility.supports(.portrait(), width: width), "portrait width \(width)")
        }
        wide.subject = .init(x: 65, y: 45, z: -60)
        wide.camera = .init(x: 66.2, y: 46.5, z: -57.7)
        XCTAssertTrue(StudyFloat32Eligibility.supports(wide, width: 192))
        for fixture in StudyValidationFixtures.all() where fixture.name != "near-field" {
            XCTAssertTrue(StudyFloat32Eligibility.supports(fixture.scene), fixture.name)
        }
    }

    private func overheadScene(distance: Double) -> LightingScene {
        LightingScene(subject: .init(x: 0, y: 0, z: 0), camera: .init(x: 0, y: distance, z: 0),
                      lights: [], cameraLens: .init(focalLengthMillimeters: 14))
    }

    private func edgeScene(width: Int, x: Int, y: Int, yaw: Double, elevation: Double,
                           axis: Int, sign: Double) throws -> LightingScene {
        let azimuth = yaw * .pi / 180, altitude = elevation * .pi / 180
        let direction = SIMD3<Double>(cos(altitude) * sin(azimuth), sin(altitude), cos(altitude) * cos(azimuth))
        var value = overheadScene(distance: 1)
        value.camera = .init(x: direction.x, y: direction.y, z: direction.z)
        let ray = try cameraRay(scene: value, width: width, x: x, y: y)
        // Solve the plane intersection's chosen coordinate for camera
        // distance. This also covers non-cardinal yaw without a vertical-view
        // assumption or copying the eligibility guard's interval calculation.
        let distance = (sign * 3 * ray.y + 0.22 * ray[axis])
            / (direction[axis] * ray.y - direction.y * ray[axis])
        XCTAssertGreaterThan(distance, 0.27)
        XCTAssertLessThanOrEqual(distance, 20)
        value.camera = .init(x: direction.x * distance, y: direction.y * distance, z: direction.z * distance)
        return value
    }

    private func panelPoint(scene: LightingScene, width: Int, x: Int, y: Int) throws -> SIMD3<Double> {
        let ray = try cameraRay(scene: scene, width: width, x: x, y: y)
        let origin = SIMD3<Double>(scene.camera.x - scene.subject.x, scene.camera.y - scene.subject.y,
                                   scene.camera.z - scene.subject.z)
        XCTAssertLessThan(ray.y, 0)
        let distance = (-0.22 - origin.y) / ray.y
        XCTAssertGreaterThan(distance, 0.05)
        return origin + ray * distance
    }

    private func cameraRay(scene: LightingScene, width: Int, x: Int, y: Int) throws -> SIMD3<Double> {
        let camera = try XCTUnwrap(CameraFraming(scene: scene))
        let px = (2 * (Double(x) + 0.5) / Double(width) - 1) * 18 / camera.lens.focalLengthMillimeters
        let py = (1 - 2 * (Double(y) + 0.5) / Double(width * 2 / 3)) * 12 / camera.lens.focalLengthMillimeters
        let ray = SIMD3<Double>(camera.forward.x + camera.right.x * px + camera.up.x * py,
                                camera.forward.y + camera.right.y * px + camera.up.y * py,
                                camera.forward.z + camera.right.z * px + camera.up.z * py)
        return ray / sqrt(ray.x * ray.x + ray.y * ray.y + ray.z * ray.z)
    }
}
