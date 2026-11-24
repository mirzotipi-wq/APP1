import XCTest
@testable import LightingCore

final class LightingPlanTests: XCTestCase {
    func testUnitConversionAndStableFormatting() throws {
        XCTAssertEqual(PlanUnits.imperial.distance(0.3048), "1.00 ft")
        XCTAssertEqual(PlanUnits.metric.coordinates(.init(x: -0.0001, y: 1.25, z: -2.5)), "(0.00, 1.25, -2.50) m")
        XCTAssertEqual(PlanUnits.imperial.toMeters(10), 3.048, accuracy: 1e-12)
        XCTAssertEqual(PlanPaper.letter.width, 612)
        XCTAssertEqual(PlanPaper.a4.width, 595.28, accuracy: 0.01)
    }

    func testFixedPrecisionAndNegativeZero() {
        XCTAssertEqual(PlanUnits.number(1234.56, decimals: 0), "1235")
        XCTAssertEqual(PlanUnits.number(1234.56, decimals: 1), "1234.6")
        XCTAssertEqual(PlanUnits.number(-0.0001, decimals: 2), "0.00")
        XCTAssertEqual(PlanUnits.number(0.125, decimals: 3), "0.125")
    }

    func testAdaptiveParameterFormattingRetainsPrecisionWithoutFalseNegativeZero() {
        XCTAssertEqual(PlanUnits.parameterNumber(73.125), "73.125")
        XCTAssertEqual(PlanUnits.parameterNumber(4321.5), "4321.5")
        XCTAssertEqual(PlanUnits.parameterNumber(900, minimumDecimals: 1), "900.0")
        XCTAssertEqual(PlanUnits.parameterNumber(1.2, minimumDecimals: 2), "1.20")
        XCTAssertEqual(PlanUnits.parameterNumber(-0.0000001, minimumDecimals: 2), "0.00")
        XCTAssertEqual(PlanUnits.parameterNumber(0.12345678), "0.123457")
        XCTAssertEqual(PlanUnits.imperial.parameterDistance(0.3048), "1.00 ft")
        XCTAssertEqual(PlanUnits.metric.parameterCoordinates(.init(x: -0.0001, y: 1.237, z: -2.5)), "(-0.0001, 1.237, -2.50) m")
        XCTAssertEqual(PlanUnits.metric.distance(1.237), "1.24 m")
    }

    func testPrecisePDFModelAndPlainTextShareTheSameValidatedParameters() throws {
        var scene = LightingScene.portrait()
        scene.camera.x = -5.137
        scene.cameraLens = .init(focalLengthMillimeters: 73.125)
        scene.previewSettings = .init(whiteBalanceKelvin: 4321.5, exposureStops: -0.375)
        scene.lights[0].candela = 4321.125
        scene.lights[0].kelvin = 5600.25
        scene.lights[0].position.x = -1.237
        scene.lights[0].optics = .init(kind: .rectangle,
            aimTarget: .init(x: 4.125, y: 1.5, z: 0),
            widthMeters: 1.237, heightMeters: 0.053)
        scene.lights[1].optics = .init(kind: .directional, aimTarget: scene.lights[1].position)
        let metric = try LightingPlan(scene: scene, title: "Precise")
        let light = metric.lights[0]
        XCTAssertEqual(light.settings(units: .metric), "4321.125 cd · 5600.25 K · 1.237 m × 0.053 m")
        XCTAssertTrue(light.placement(units: .metric).contains("-1.237"))
        XCTAssertTrue(light.aim(units: .metric).contains("4.125"))
        XCTAssertTrue(metric.cameraSettings.contains("73.125 mm"))
        XCTAssertTrue(metric.previewSettings.contains("4321.5 K balance · -0.375 relative stops"))
        for units in PlanUnits.allCases {
            let report = try LightingPlan(scene: scene, title: "Precise", units: units)
            let entry = report.lights[0]
            for value in [report.cameraSettings, report.previewSettings, entry.settings(units: units),
                          entry.placement(units: units), entry.aim(units: units),
                          units.parameterCoordinates(scene.camera)] {
                XCTAssertTrue(report.plainText.contains(value), "Missing \(value)")
            }
            XCTAssertTrue(report.plainText.contains("Aim undefined"))
            XCTAssertTrue(report.plainText.contains("No reference images"))
            XCTAssertEqual(report.scene, scene)
        }
    }

    func testEquipmentRowsPreserveSceneValuesAndAimSemantics() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: .init(x: 2, y: 1.8, z: -0.3), widthMeters: 1.2, heightMeters: 0.65)
        scene.lights[1].optics = .init(kind: .directional)
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        let report = try LightingPlan(scene: scene, title: "Portrait\nSession", units: .metric)
        XCTAssertEqual(report.title, "Portrait Session")
        XCTAssertEqual(report.scene, scene)
        XCTAssertEqual(report.lights.map(\.number), [1, 2, 3])
        let key = report.lights[0]
        XCTAssertEqual(key.kind, .rectangle)
        XCTAssertEqual(key.position, scene.lights[0].position)
        XCTAssertEqual(key.subjectDistance, scene.lights[0].position.distance(to: scene.subject), accuracy: 1e-12)
        XCTAssertEqual(key.settings(units: .metric), "900.0 cd · 5600 K · 1.20 m × 0.65 m")
        XCTAssertEqual(key.aim(units: .metric), "Aim (2.00, 1.80, -0.30) m · manual target")
        XCTAssertTrue(report.lights[1].followsSubject)
        XCTAssertNil(report.lights[2].aimTarget)
        XCTAssertTrue(report.lights[2].aim(units: .metric).contains("no aiming direction"))
        XCTAssertTrue(report.cameraSettings.contains("85 mm"))
        XCTAssertTrue(report.previewSettings.contains("relative stops"))
    }

    func testDiagramUsesUniformScaleAndPositiveZDown() throws {
        let report = try LightingPlan(scene: .portrait(), title: "Default")
        let diagram = report.diagram(), subject = diagram.markers[0].anchor, camera = diagram.markers[1].anchor
        XCTAssertEqual(camera.x, subject.x, accuracy: 1e-9)
        XCTAssertEqual(camera.y - subject.y, 3 * diagram.pointsPerMeter, accuracy: 1e-9)
        let origin = diagram.project(.init(x: 0, y: 0))
        let x = diagram.project(.init(x: 1, y: 0)), z = diagram.project(.init(x: 0, y: 1))
        XCTAssertEqual(x.x - origin.x, z.y - origin.y, accuracy: 1e-9)
        XCTAssertEqual(diagram.lines.filter { $0.kind == .camera }.count, 1)
        XCTAssertTrue(diagram.lines.filter { $0.kind == .aim }.isEmpty)
    }

    func testManualAimAndRotatedModifierAreProjectedFromWorldCoordinates() throws {
        let origin = Position(x: -2, y: 2, z: 1)
        let target = Position(x: 1, y: 0.5, z: -1)
        let light = StudioLight(name: "Rect", position: origin, candela: 150, kelvin: 4000,
                                optics: .init(kind: .rectangle, aimTarget: target, widthMeters: 2, heightMeters: 1))
        let scene = LightingScene(subject: target, camera: .init(x: 1, y: 0.5, z: 4), lights: [light])
        let diagram = try LightingPlan(scene: scene, title: "Manual aim").diagram()
        let line = try XCTUnwrap(diagram.lines.first { $0.kind == .aim })
        XCTAssertEqual(line.points.first, diagram.project(.init(x: origin.x, y: origin.z)))
        XCTAssertEqual(line.points.last, diagram.project(.init(x: target.x, y: target.z)))
        let modifier = try XCTUnwrap(diagram.lines.first { $0.kind == .modifier })
        XCTAssertEqual(modifier.points.count, 5)
        XCTAssertEqual(modifier.points.first, modifier.points.last)
        // The right basis is horizontal; the first edge preserves its 2 m width in plan.
        XCTAssertEqual(modifier.points[0].distance(to: modifier.points[1]), 2 * diagram.pointsPerMeter, accuracy: 1e-9)
        let opposite = modifier.points[2]
        XCTAssertEqual((modifier.points[0].x + opposite.x) / 2, line.points[0].x, accuracy: 1e-9)
        XCTAssertEqual((modifier.points[0].y + opposite.y) / 2, line.points[0].y, accuracy: 1e-9)
    }

    func testCoincidentSourcesKeepActualAnchorsAndDistinctNumberedLabels() throws {
        let p = Position(x: 0, y: 1, z: 0)
        let lights = (1...12).map { StudioLight(name: "L\($0)", position: p, candela: 100, kelvin: 5600) }
        let scene = LightingScene(subject: p, camera: p, lights: lights)
        let diagram = try LightingPlan(scene: scene, title: "Crowded", paper: .a4).diagram()
        XCTAssertEqual(diagram.markers.count, 14)
        XCTAssertTrue(diagram.markers.allSatisfy { $0.anchor == diagram.markers[0].anchor })
        for (i, marker) in diagram.markers.enumerated() {
            XCTAssertTrue((11...diagram.width - 11).contains(marker.center.x))
            XCTAssertTrue((11...diagram.height - 11).contains(marker.center.y))
            for other in diagram.markers.dropFirst(i + 1) {
                XCTAssertGreaterThanOrEqual(marker.center.distance(to: other.center), 26.999)
            }
        }
        XCTAssertEqual(diagram, try LightingPlan(scene: scene, title: "Crowded", paper: .a4).diagram())
    }

    func testExtremeCoordinatesAndModifierFootprintFitBothPapers() throws {
        var scene = LightingScene.portrait()
        scene.subject = .init(x: -100, y: 0, z: -100)
        scene.camera = .init(x: 100, y: 100, z: 100)
        scene.lights[0].position = .init(x: 100, y: 1, z: -100)
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: .init(x: -100, y: 2, z: 100), widthMeters: 4, heightMeters: 4)
        for paper in PlanPaper.allCases {
            for units in PlanUnits.allCases {
                let d = try LightingPlan(scene: scene, title: "Extreme", units: units, paper: paper).diagram()
                XCTAssertGreaterThan(d.pointsPerMeter, 0)
                XCTAssertLessThanOrEqual(d.grid.count, 18)
                XCTAssertTrue(d.gridStep.isFinite)
                for p in d.lines.flatMap(\.points) + d.markers.map(\.anchor) {
                    XCTAssertTrue((0...d.width).contains(p.x))
                    XCTAssertTrue((0...d.height).contains(p.y))
                }
            }
        }
    }

    func testGridSpacingIsBoundedAndUnitCorrect() throws {
        for units in PlanUnits.allCases {
            let d = try LightingPlan(scene: .portrait(), title: "Grid", units: units).diagram()
            let vertical = d.grid.filter { abs($0.from.x - $0.to.x) < 1e-9 }.sorted { $0.from.x < $1.from.x }
            XCTAssertGreaterThan(vertical.count, 1)
            XCTAssertLessThanOrEqual(d.grid.count, 18)
            XCTAssertEqual(vertical[1].from.x - vertical[0].from.x, units.toMeters(d.gridStep) * d.pointsPerMeter, accuracy: 1e-9)
            XCTAssertTrue(d.scaleLabel.hasSuffix(units.symbol))
        }
    }

    func testPaginationIncludesEveryLightExactlyOnceAndEmptyScene() throws {
        var scene = LightingScene.portrait()
        scene.lights = (1...12).map { .init(name: "L\($0)", position: .init(x: Double($0), y: 2, z: 0), candela: 100, kelvin: 5600) }
        let report = try LightingPlan(scene: scene, title: "Twelve")
        XCTAssertEqual(report.equipmentPages.map(\.count), [5, 5, 2])
        XCTAssertEqual(report.equipmentPages.flatMap { $0 }.map(\.number), Array(1...12))
        XCTAssertEqual(report.pageCount, 4)
        scene.lights = []
        let empty = try LightingPlan(scene: scene, title: "Empty")
        XCTAssertEqual(empty.pageCount, 2)
        XCTAssertTrue(empty.equipmentPages[0].isEmpty)
    }

    func testInvalidSceneAndUndefinedAimAreNotPresentedAsValid() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: scene.lights[0].position)
        let plan = try LightingPlan(scene: scene, title: "Invalid aim")
        XCTAssertFalse(plan.lights[0].aimIsValid)
        XCTAssertTrue(plan.lights[0].aim(units: .metric).contains("undefined"))
        XCTAssertFalse(plan.diagram().lines.contains { $0.kind == .modifier })
        scene.lights[0].candela = -1
        XCTAssertThrowsError(try LightingPlan(scene: scene, title: "Invalid"))
    }

    func testUnicodeAndControlCharactersAreSafelyBounded() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].name = "نور\nاصلی"
        let plan = try LightingPlan(scene: scene, title: String(repeating: "写", count: 90))
        XCTAssertEqual(plan.lights[0].name, "نور اصلی")
        XCTAssertEqual(plan.title.count, 80)
        XCTAssertTrue(plan.title.hasSuffix("…"))
    }
}
