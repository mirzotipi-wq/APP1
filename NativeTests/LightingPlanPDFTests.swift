import Foundation
import PDFKit
import XCTest
import LightingCore
@testable import KeyAndFill

final class LightingPlanPDFTests: XCTestCase {
    @MainActor func testNativePDFOpensAndContainsAllEquipmentInBothPaperSizes() throws {
        var scene = LightingScene.portrait()
        scene.lights = (1...12).map { index in
            StudioLight(name: "Fixture \(index) unique", position: .init(x: Double(index) / 2, y: 2, z: 1), candela: 700, kelvin: 5600,
                        optics: .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.6))
        }
        for paper in PlanPaper.allCases {
            let plan = try LightingPlan(scene: scene, title: "Portrait validation", units: .imperial, paper: paper)
            let data = try LightingPlanPDF.make(plan)
            XCTAssertTrue(data.starts(with: Data("%PDF-".utf8)))
            let pdf = try XCTUnwrap(PDFDocument(data: data))
            XCTAssertEqual(pdf.pageCount, 4)
            for pageIndex in 0..<pdf.pageCount {
                let page = try XCTUnwrap(pdf.page(at: pageIndex))
                let bounds = page.bounds(for: .mediaBox)
                XCTAssertEqual(Double(bounds.width), paper.width, accuracy: 0.1)
                XCTAssertEqual(Double(bounds.height), paper.height, accuracy: 0.1)
                XCTAssertFalse((page.string ?? "").isEmpty)
            }
            let contents = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: "\n")
                .split(whereSeparator: \.isWhitespace).joined(separator: " ")
            for index in 1...12 { XCTAssertTrue(contents.contains("Fixture \(index) unique"), "Missing fixture \(index)") }
            XCTAssertTrue(contents.contains("ft")); XCTAssertTrue(contents.contains("700.0 cd"))
            XCTAssertTrue(contents.contains("No reference images"))
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "com.adobe.pdf")
            attachment.name = "Lighting-plan-\(paper.rawValue).pdf"; attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor func testPDFRetainsEnteredPrecisionInBothPaperSizesAndUnits() throws {
        var scene = LightingScene.portrait()
        scene.camera.x = -5.137
        scene.cameraLens = .init(focalLengthMillimeters: 73.125)
        scene.previewSettings = .init(whiteBalanceKelvin: 4321.5, exposureStops: -0.375)
        scene.lights[0].position.x = -1.237
        scene.lights[0].candela = 4321.125
        scene.lights[0].kelvin = 5600.25
        scene.lights[0].optics = .init(kind: .rectangle, aimTarget: .init(x: 4.125, y: 1.5, z: 0),
                                     widthMeters: 1.237, heightMeters: 0.053)
        for paper in PlanPaper.allCases {
            for units in PlanUnits.allCases {
                let plan = try LightingPlan(scene: scene, title: "Precision export", units: units, paper: paper)
                let pdf = try XCTUnwrap(PDFDocument(data: LightingPlanPDF.make(plan)))
                let content = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: " ")
                    .split(whereSeparator: \.isWhitespace).joined(separator: " ")
                for value in ["73.125 mm", "4321.5 K", "-0.375 relative stops", "4321.125 cd", "5600.25 K",
                              units.parameterDistance(1.237), units.parameterDistance(0.053),
                              PlanUnits.parameterNumber(units.fromMeters(-1.237), minimumDecimals: 2),
                              PlanUnits.parameterNumber(units.fromMeters(4.125), minimumDecimals: 2),
                              PlanUnits.parameterNumber(units.fromMeters(-5.137), minimumDecimals: 2)] {
                    XCTAssertTrue(content.contains(value), "\(paper) \(units): missing \(value)")
                }
            }
        }
    }

    @MainActor func testMeasuredRoomPDFRetainsEveryRowInBothPaperSizesAndUnits() throws {
        var scene = LightingScene.portrait()
        scene.placementRoom = .init(ceilingHeightMeters: 3)
        scene.lights = (1...12).map { index in
            StudioLight(name: "Measured fixture \(index)", position: .init(x: Double(index) / 2, y: 2 + Double(index) / 10, z: 1),
                        candela: 700, kelvin: 5600, optics: .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.6, rollDegrees: 37.5))
        }
        func normalized(_ text: String) -> String { text.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
        for paper in PlanPaper.allCases {
            for units in PlanUnits.allCases {
                let plan = try LightingPlan(scene: scene, title: "Measured room validation", units: units, paper: paper)
                let data = try LightingPlanPDF.make(plan)
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "com.adobe.pdf")
                attachment.name = "Measured-room-\(paper.rawValue)-\(units.rawValue).pdf"; attachment.lifetime = .keepAlways
                add(attachment)
                let pdf = try XCTUnwrap(PDFDocument(data: data))
                XCTAssertEqual(plan.roomPlacementItems.count, 14)
                XCTAssertEqual(pdf.pageCount, 8)
                XCTAssertTrue(pdf.page(at: 1)?.string?.contains("Roll 37.5°") == true)
                XCTAssertTrue(pdf.page(at: 7)?.string?.contains("Measured fixture 12") == true)
                for (index, items) in plan.roomPlacementPages.enumerated() {
                    let page = try XCTUnwrap(pdf.page(at: 1 + plan.equipmentPages.count + index))
                    let content = normalized(page.string ?? "")
                    for expected in plan.roomPlacementSummary + [LightingPlan.roomPlacementCoordinateNote, LightingPlan.roomPlacementLimitations] {
                        XCTAssertTrue(content.contains(normalized(expected)), "\(paper) \(units) room page \(index): missing \(expected)")
                    }
                    for item in items {
                        let details = [item.name,
                            "X from left: \(units.roomDistance(item.point.xFromLeft)) · Z from near: \(units.roomDistance(item.point.zFromNear))",
                            "Height: \(units.roomDistance(item.point.heightMeters)) · Floor distance to subject: \(units.roomDistance(item.point.horizontalDistanceFromSubject))",
                            item.centerStatus + ". " + item.centerHeightStatus(units: units),
                            item.projectedFaceStatus(units: units), item.faceHeightStatus(units: units)].compactMap { $0 }
                        for expected in details {
                            XCTAssertTrue(content.contains(normalized(expected)), "\(paper) \(units) \(item.name): truncated or missing \(expected)")
                        }
                    }
                }
            }
        }
    }

    @MainActor func testCrowdedMeasuredRoomPDFRetainsIdentitiesAndSettingsWithMaximumUnicodeNames() throws {
        let names = [String(repeating: "e\u{301}\u{302}\u{303}", count: StudioDisplayName.maximumCharacters),
                     String(repeating: "ن", count: StudioDisplayName.maximumCharacters),
                     String(repeating: "光", count: StudioDisplayName.maximumCharacters)]
        for name in names {
            XCTAssertEqual(name.count, StudioDisplayName.maximumCharacters)
            XCTAssertEqual(try StudioDisplayName.newInput(name), name)
        }
        XCTAssertEqual(names[0].unicodeScalars.count, StudioDisplayName.maximumScalars)
        var scene = LightingScene.portrait()
        scene.placementRoom = .init(ceilingHeightMeters: 3)
        scene.lights = names.enumerated().map { index, name in
            StudioLight(name: name, position: .init(x: 0, y: 2, z: 0),
                        candela: 1000 + Double(index) * 100, kelvin: 3200 + Double(index) * 1000,
                        optics: .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.6,
                                      rollDegrees: Double(index) * 7.5))
        }
        func text(_ page: PDFPage, topRect: CGRect? = nil) -> String {
            let raw: String?
            if let topRect {
                let rect = CGRect(x: topRect.minX, y: page.bounds(for: .mediaBox).height - topRect.maxY,
                                  width: topRect.width, height: topRect.height)
                raw = page.selection(for: rect)?.string
            } else { raw = page.string }
            return (raw ?? "").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        for paper in PlanPaper.allCases {
            for units in PlanUnits.allCases {
                let context = "\(paper.rawValue) \(units.rawValue)"
                let plan = try LightingPlan(scene: scene, title: names[2], units: units, paper: paper)
                let data = try LightingPlanPDF.make(plan)
                XCTAssertTrue(data.starts(with: Data("%PDF-".utf8)))
                let pdf = try XCTUnwrap(PDFDocument(data: data))
                XCTAssertEqual(pdf.pageCount, 4, context)
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "com.adobe.pdf")
                attachment.name = "Crowded-Unicode-room-\(paper.rawValue)-\(units.rawValue).pdf"
                attachment.lifetime = .keepAlways; add(attachment)
                for pageIndex in 0..<pdf.pageCount {
                    let page = try XCTUnwrap(pdf.page(at: pageIndex))
                    XCTAssertTrue(text(page).contains("\(pageIndex + 1) / 4"), "\(context): missing page footer")
                }
                let overview = try XCTUnwrap(pdf.page(at: 0))
                for marker in plan.diagram().markers {
                    let rect = CGRect(x: 40 + marker.center.x - 10, y: 150 + marker.center.y - 7, width: 20, height: 15)
                    XCTAssertEqual(text(overview, topRect: rect), marker.label, "\(context): crowded diagram identity")
                }
                for expected in [plan.cameraSettings, plan.previewSettings, "No reference images are embedded."] {
                    XCTAssertTrue(text(overview).contains(expected), "\(context): missing \(expected)")
                }
                let equipment = try XCTUnwrap(pdf.page(at: 1))
                for (index, light) in plan.lights.enumerated() {
                    let y = CGFloat(151 + index * 112)
                    XCTAssertEqual(text(equipment, topRect: CGRect(x: 40, y: y + 3, width: 31, height: 25)), String(light.number), context)
                    // Full names may truncate; require a recognizable glyph in the name's own box.
                    let name = text(equipment, topRect: CGRect(x: 76, y: y, width: paper.width - 116, height: 35))
                        .decomposedStringWithCompatibilityMapping.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
                    XCTAssertTrue(name.contains(["e", "ن", "光"][index]), "\(context): missing equipment name glyph \(light.number)")
                    let details = text(equipment, topRect: CGRect(x: 76, y: y + 37, width: paper.width - 116, height: 63))
                    for expected in [light.settings(units: units), light.placement(units: units), light.aim(units: units)] {
                        XCTAssertTrue(details.contains(expected), "\(context) light \(light.number): missing \(expected)")
                    }
                }
                for (pageIndex, items) in plan.roomPlacementPages.enumerated() {
                    let page = try XCTUnwrap(pdf.page(at: 2 + pageIndex))
                    for (row, item) in items.enumerated() {
                        let y = CGFloat(189 + row * 119)
                        XCTAssertEqual(text(page, topRect: CGRect(x: 40, y: y + 5, width: 30, height: 24)), item.marker, context)
                        if let number = Int(item.marker) {
                            let name = text(page, topRect: CGRect(x: 76, y: y + 2, width: paper.width - 116, height: 24))
                                .decomposedStringWithCompatibilityMapping.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
                            XCTAssertTrue(name.contains(["e", "ن", "光"][number - 1]), "\(context): missing room name glyph \(number)")
                        }
                        let details = text(page, topRect: CGRect(x: 76, y: y + 27, width: paper.width - 116, height: 89))
                        for expected in ["X from left: \(units.roomDistance(item.point.xFromLeft)) · Z from near: \(units.roomDistance(item.point.zFromNear))",
                                         "Height: \(units.roomDistance(item.point.heightMeters)) · Floor distance to subject: \(units.roomDistance(item.point.horizontalDistanceFromSubject))",
                                         item.centerHeightStatus(units: units), item.faceHeightStatus(units: units)].compactMap({ $0 }) {
                            XCTAssertTrue(details.contains(expected), "\(context) room marker \(item.marker): missing \(expected)")
                        }
                    }
                }
                let contents = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: " ")
                for light in scene.lights { XCTAssertFalse(contents.contains(light.id.uuidString), "Internal fixture identity leaked") }
                XCTAssertEqual(pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute.rawValue] as? String, "Key & Fill - Lighting plan")
            }
        }
    }

    @MainActor func testEmptySceneStillProducesReadableDiagramAndSchedule() throws {
        var scene = LightingScene.portrait(); scene.lights = []
        let plan = try LightingPlan(scene: scene, title: "Empty")
        let doc = try XCTUnwrap(PDFDocument(data: LightingPlanPDF.make(plan)))
        XCTAssertEqual(doc.pageCount, 2)
        XCTAssertTrue(doc.page(at: 1)?.string?.contains("No lights in this setup") == true)
    }
}
