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

    @MainActor func testEmptySceneStillProducesReadableDiagramAndSchedule() throws {
        var scene = LightingScene.portrait(); scene.lights = []
        let plan = try LightingPlan(scene: scene, title: "Empty")
        let doc = try XCTUnwrap(PDFDocument(data: LightingPlanPDF.make(plan)))
        XCTAssertEqual(doc.pageCount, 2)
        XCTAssertTrue(doc.page(at: 1)?.string?.contains("No lights in this setup") == true)
    }
}
