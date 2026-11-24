import XCTest
@testable import LightingCore

final class StudioSceneBoundsTests: XCTestCase {
    func testTranslatedRigRetainsScaleAndProjectedLayout() throws {
        var original = LightingScene.portrait()
        original.lights[0].optics = .init(kind: .rectangle,
                                         aimTarget: .init(x: 0.2, y: 1.3, z: 0.1),
                                         widthMeters: 2.4, heightMeters: 1.7)
        func translated(_ p: Position) -> Position { .init(x: p.x + 80, y: p.y + 10, z: p.z + 85) }
        var moved = original
        moved.subject = translated(original.subject)
        moved.camera = translated(original.camera)
        for i in moved.lights.indices {
            moved.lights[i].position = translated(original.lights[i].position)
            if let target = original.lights[i].optics?.aimTarget {
                moved.lights[i].optics?.aimTarget = translated(target)
            }
        }
        let a = try StudioSceneBounds(scene: original), b = try StudioSceneBounds(scene: moved)
        let fitA = try XCTUnwrap(a.overheadFit(width: 390, height: 320))
        let fitB = try XCTUnwrap(b.overheadFit(width: 390, height: 320))
        XCTAssertEqual(fitA.pointsPerMeter, fitB.pointsPerMeter, accuracy: 1e-10)
        XCTAssertEqual(b.center.x - a.center.x, 80, accuracy: 1e-10)
        XCTAssertEqual(b.center.y - a.center.y, 10, accuracy: 1e-10)
        XCTAssertEqual(b.center.z - a.center.z, 85, accuracy: 1e-10)
        XCTAssertEqual(a.radiusMeters, b.radiusMeters, accuracy: 1e-10)
        for p in [original.subject, original.camera] + original.lights.map(\.position) {
            let first = fitA.project(p), second = fitB.project(translated(p))
            XCTAssertEqual(first.x, second.x, accuracy: 1e-9)
            XCTAssertEqual(first.y, second.y, accuracy: 1e-9)
        }
        XCTAssertEqual(original.lights[0].position.x, -1.5)
    }

    func testRectangularFaceCornersFitWithConsistentPadding() throws {
        let light = StudioLight(name: "Large overhead softbox", position: .init(x: 0, y: 2, z: 0),
                                candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: .init(x: 0, y: 0, z: 0),
                                              widthMeters: 4, heightMeters: 3))
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 1), lights: [light])
        let bounds = try StudioSceneBounds(scene: scene)
        XCTAssertEqual(bounds.minimum.x, -2, accuracy: 1e-12)
        XCTAssertEqual(bounds.maximum.x, 2, accuracy: 1e-12)
        XCTAssertEqual(bounds.minimum.z, -1.5, accuracy: 1e-12)
        XCTAssertEqual(bounds.maximum.z, 1.5, accuracy: 1e-12)
        XCTAssertTrue(bounds.unavailableModifierIDs.isEmpty)
        let fit = try XCTUnwrap(bounds.overheadFit(width: 440, height: 340, padding: 20))
        XCTAssertEqual(fit.pointsPerMeter, 100, accuracy: 1e-12)
        for x in [-2.0, 2.0] {
            for z in [-1.5, 1.5] {
                let p = fit.project(.init(x: x, y: 2, z: z))
                XCTAssertGreaterThanOrEqual(p.x, 20)
                XCTAssertLessThanOrEqual(p.x, 420)
                XCTAssertGreaterThanOrEqual(p.y, 20)
                XCTAssertLessThanOrEqual(p.y, 320)
            }
        }
    }

    func testManualAimTargetsParticipateOnlyWhenVisible() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .directional, aimTarget: .init(x: 18, y: 6, z: -14))
        let aimed = try StudioSceneBounds(scene: scene)
        XCTAssertEqual(aimed.maximum.x, 18)
        XCTAssertEqual(aimed.maximum.y, 6)
        XCTAssertEqual(aimed.minimum.z, -14)
        scene.lights[0].optics?.kind = .point
        let point = try StudioSceneBounds(scene: scene)
        XCTAssertLessThan(point.maximum.x, 18)
        XCTAssertLessThan(point.maximum.y, 6)
        XCTAssertGreaterThan(point.minimum.z, -14)
    }

    func testDegenerateModifierReportsUnavailableWithoutLosingItsCenter() throws {
        let p = Position(x: 8, y: 3, z: -7)
        let light = StudioLight(name: "Undefined aim", position: p, candela: 500, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: p, widthMeters: 4, heightMeters: 4))
        let scene = LightingScene(subject: .init(x: 0, y: 1.5, z: 0),
                                  camera: .init(x: 0, y: 1.5, z: 3), lights: [light])
        let bounds = try StudioSceneBounds(scene: scene)
        XCTAssertEqual(bounds.unavailableModifierIDs, [light.id])
        XCTAssertEqual(bounds.maximum.x, p.x)
        XCTAssertEqual(bounds.maximum.y, p.y)
        XCTAssertEqual(bounds.minimum.z, p.z)
        XCTAssertNotNil(bounds.overheadFit(width: 320, height: 320))
    }

    func testEmptyCoincidentRigHasFiniteCenteredMinimumSpan() throws {
        let p = Position(x: 80, y: -12, z: 92)
        let scene = LightingScene(subject: p, camera: p, lights: [])
        let bounds = try StudioSceneBounds(scene: scene)
        XCTAssertEqual(bounds.minimum, p)
        XCTAssertEqual(bounds.maximum, p)
        XCTAssertEqual(bounds.center, p)
        XCTAssertEqual(bounds.radiusMeters, 0)
        let fit = try XCTUnwrap(bounds.overheadFit(width: 400, height: 300, padding: 40))
        XCTAssertEqual(fit.pointsPerMeter, 110)
        XCTAssertEqual(fit.project(p).x, 200)
        XCTAssertEqual(fit.project(p).y, 150)
    }

    func testExtremeValidCentersRetainDerivedCornersBeyondAuthoringLimit() throws {
        let light = StudioLight(name: "Boundary softbox", position: .init(x: 100, y: 100, z: 100),
                                candela: 900, kelvin: 5600,
                                optics: .init(kind: .rectangle, aimTarget: .init(x: 100, y: 100, z: 99),
                                              widthMeters: 4, heightMeters: 4))
        let scene = LightingScene(subject: .init(x: -100, y: -100, z: -100),
                                  camera: .init(x: 100, y: -100, z: -100), lights: [light])
        let bounds = try StudioSceneBounds(scene: scene)
        XCTAssertEqual(bounds.maximum.x, 102, accuracy: 1e-12)
        XCTAssertEqual(bounds.maximum.y, 102, accuracy: 1e-12)
        XCTAssertEqual(bounds.minimum.x, -100)
        XCTAssertTrue(bounds.radiusMeters.isFinite)
        let fit = try XCTUnwrap(bounds.overheadFit(width: 390, height: 320))
        for p in [bounds.minimum, bounds.maximum, scene.subject, scene.camera, light.position] {
            let projected = fit.project(p)
            XCTAssertTrue(projected.x.isFinite && projected.y.isFinite)
            XCTAssertGreaterThanOrEqual(projected.x, 40 - 1e-10)
            XCTAssertLessThanOrEqual(projected.x, 350 + 1e-10)
            XCTAssertGreaterThanOrEqual(projected.y, 40 - 1e-10)
            XCTAssertLessThanOrEqual(projected.y, 280 + 1e-10)
        }
    }

    func testInvalidSceneAndViewportInputsAreRejected() throws {
        var scene = LightingScene.portrait()
        scene.subject.x = .infinity
        XCTAssertThrowsError(try StudioSceneBounds(scene: scene)) {
            XCTAssertEqual($0 as? SceneError, .invalidScene)
        }
        let bounds = try StudioSceneBounds(scene: .portrait())
        for dimensions in [(0.0, 320.0), (-1.0, 320.0), (.infinity, 320.0), (320.0, .nan)] {
            XCTAssertNil(bounds.overheadFit(width: dimensions.0, height: dimensions.1))
        }
        XCTAssertNil(bounds.overheadFit(width: 320, height: 320, padding: 160))
        XCTAssertNil(bounds.overheadFit(width: 320, height: 320, padding: -1))
        XCTAssertNil(bounds.overheadFit(width: 320, height: 320, padding: .infinity))
        XCTAssertNil(bounds.overheadFit(width: 320, height: 320, minimumSpanMeters: 0))
        XCTAssertNil(bounds.overheadFit(width: 320, height: 320, minimumSpanMeters: .nan))
    }

    func testGridStaysBoundedImmediatelyAbovePaddingThresholdAndInNarrowView() throws {
        let scene = LightingScene(subject: .init(x: -100, y: 1.5, z: -100),
                                  camera: .init(x: 100, y: 1.5, z: 100), lights: [])
        let bounds = try StudioSceneBounds(scene: scene)
        for (width, padding) in [(96.0.nextUp, 48.0), (97.0, 48.0), (1.0, 0.2)] {
            let fit = try XCTUnwrap(bounds.overheadFit(width: width, height: 280, padding: padding))
            let grid = try XCTUnwrap(fit.grid())
            XCTAssertGreaterThan(grid.spacingMeters, 1)
            XCTAssertLessThanOrEqual(grid.verticalWorldCoordinates.count, 128)
            XCTAssertLessThanOrEqual(grid.horizontalWorldCoordinates.count, 128)
            XCTAssertFalse(grid.verticalWorldCoordinates.isEmpty)
            XCTAssertFalse(grid.horizontalWorldCoordinates.isEmpty)
            for coordinate in grid.verticalWorldCoordinates + grid.horizontalWorldCoordinates {
                XCTAssertTrue(coordinate.isFinite)
                XCTAssertEqual(coordinate / grid.spacingMeters,
                               (coordinate / grid.spacingMeters).rounded(), accuracy: 1e-10)
            }
            let fraction = grid.spacingMeters / pow(10, floor(log10(grid.spacingMeters)))
            XCTAssertTrue([1.0, 2.0, 5.0, 10.0].contains { abs($0 - fraction) < 1e-10 })
        }
    }

    func testGridUsesOneMeterForPortraitAndKeepsWorldAlignmentWhenTranslated() throws {
        let scene = LightingScene.portrait()
        var moved = scene
        func move(_ p: Position) -> Position { .init(x: p.x + 80, y: p.y, z: p.z + 70) }
        moved.subject = move(scene.subject)
        moved.camera = move(scene.camera)
        for index in moved.lights.indices { moved.lights[index].position = move(scene.lights[index].position) }
        let a = try XCTUnwrap(StudioSceneBounds(scene: scene).overheadFit(width: 390, height: 280, padding: 48))
        let b = try XCTUnwrap(StudioSceneBounds(scene: moved).overheadFit(width: 390, height: 280, padding: 48))
        let first = try XCTUnwrap(a.grid()), second = try XCTUnwrap(b.grid())
        XCTAssertEqual(first.spacingMeters, 1)
        XCTAssertEqual(second.spacingMeters, 1)
        XCTAssertEqual(second.verticalWorldCoordinates, first.verticalWorldCoordinates.map { $0 + 80 })
        XCTAssertEqual(second.horizontalWorldCoordinates, first.horizontalWorldCoordinates.map { $0 + 70 })
        XCTAssertTrue(first.verticalWorldCoordinates.contains(0))
        XCTAssertTrue(first.horizontalWorldCoordinates.contains(0))
    }

    func testGridHonorsRequestedLimitAndRejectsUnrepresentableSpansWithoutTrapping() throws {
        let scene = LightingScene(subject: .init(x: -100, y: 1.5, z: -100),
                                  camera: .init(x: 100, y: 1.5, z: 100), lights: [])
        let bounds = try StudioSceneBounds(scene: scene)
        let normal = try XCTUnwrap(bounds.overheadFit(width: 390, height: 280))
        for limit in [2, 3, 8, 128, Int.max] {
            let grid = try XCTUnwrap(normal.grid(maximumLinesPerAxis: limit))
            XCTAssertLessThanOrEqual(grid.verticalWorldCoordinates.count, min(limit, 512))
            XCTAssertLessThanOrEqual(grid.horizontalWorldCoordinates.count, min(limit, 512))
        }
        for limit in [Int.min, -1, 0, 1] { XCTAssertNil(normal.grid(maximumLinesPerAxis: limit)) }
        let enormous = try XCTUnwrap(bounds.overheadFit(width: .greatestFiniteMagnitude,
                                                       height: .greatestFiniteMagnitude, padding: 0))
        let grid = try XCTUnwrap(enormous.grid())
        XCTAssertTrue(grid.spacingMeters.isFinite)
        XCTAssertLessThanOrEqual(grid.verticalWorldCoordinates.count, 128)
        let unrepresentable = try XCTUnwrap(bounds.overheadFit(width: .greatestFiniteMagnitude,
                                                              height: 96.0.nextUp, padding: 48))
        XCTAssertNil(unrepresentable.grid())
    }
}
