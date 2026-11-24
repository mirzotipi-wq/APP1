import XCTest
@testable import LightingCore

final class StudioPlanLabelLayoutTests: XCTestCase {
    typealias Item = StudioPlanLabelLayout.Item
    typealias Rect = StudioPlanLabelLayout.Rect

    /// The genuine source-9 recovery image is 1206x2622 at 3x. Its plan
    /// viewport is 342x280 points. These anchors follow the unchanged actual
    /// four-light fixture; caption dimensions conservatively approximate its raster.
    private func recoveryItems(width: Double = 342, height: Double = 280,
                               textScale: Double = 1) -> [Item] {
        let scale = min((width - min(48, min(width, height) * 0.2) * 2) / 4,
                        (height - min(48, min(width, height) * 0.2) * 2) / 4.2)
        let geometry: [(Double, Double, Double)] = [
            (0, 0, 52), (0, 3, 51), (-1.5, 1.2, 28),
            (1.5, 1.5, 25), (0.8, -1.2, 27), (1, 1, 44)
        ]
        return geometry.enumerated().map { index, value in
            .init(anchorX: width / 2 + value.0 * scale,
                  anchorY: height / 2 + (value.1 - 0.9) * scale,
                  captionWidth: min(128, value.2 * textScale), captionHeight: 14 * textScale,
                  isSelected: index == 2)
        }
    }

    private func assertSafe(_ layout: StudioPlanLabelLayout, items: [Item],
                            width: Double, height: Double, top: Double,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(layout.markerFrames.count, items.count, file: file, line: line)
        XCTAssertEqual(layout.captionFrames.count, items.count, file: file, line: line)
        for i in items.indices {
            XCTAssertEqual(layout.markerFrames[i].centerX, items[i].anchorX, accuracy: 1e-10, file: file, line: line)
            XCTAssertEqual(layout.markerFrames[i].centerY, items[i].anchorY, accuracy: 1e-10, file: file, line: line)
            guard let frame = layout.captionFrames[i] else { continue }
            XCTAssertGreaterThanOrEqual(frame.x, 8, file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.y, max(8, top), file: file, line: line)
            XCTAssertLessThanOrEqual(frame.maxX, width - 8, file: file, line: line)
            XCTAssertLessThanOrEqual(frame.maxY, height - 8, file: file, line: line)
            XCTAssertEqual(frame.width, items[i].captionWidth, file: file, line: line)
            XCTAssertEqual(frame.height, items[i].captionHeight, file: file, line: line)
            for marker in layout.markerFrames {
                XCTAssertFalse(frame.intersects(marker, gap: 3.999999), file: file, line: line)
            }
            for j in items.indices where j != i {
                if let other = layout.captionFrames[j] {
                    XCTAssertFalse(frame.intersects(other, gap: 3.999999), file: file, line: line)
                }
            }
        }
    }

    func testCapturedRecoveryCollisionIsRemovedWithoutMovingEquipment() throws {
        let items = recoveryItems(), light = items[5], fill = items[3]
        // Old VStack: 34pt icon + 3pt spacing + 14pt caption, all centered at
        // the world anchor. The icon was shifted up by 8.5pt; caption down.
        let oldLightCaption = Rect(x: light.anchorX - light.captionWidth / 2,
                                   y: light.anchorY + 11.5, width: light.captionWidth, height: 14)
        let oldFillIcon = Rect(x: fill.anchorX - 17, y: fill.anchorY - 25.5, width: 34, height: 34)
        XCTAssertTrue(oldLightCaption.intersects(oldFillIcon))
        XCTAssertEqual(oldFillIcon.centerY, fill.anchorY - 8.5, accuracy: 1e-10)

        let layout = try XCTUnwrap(StudioPlanLabelLayout(items: items, width: 342, height: 280))
        XCTAssertEqual(layout.omittedCaptionCount, 0)
        assertSafe(layout, items: items, width: 342, height: 280, top: 32)
    }

    func testNarrowAndLargeTextLayoutsNeverOverlapOrMoveAnchors() throws {
        for width in [160.0, 240, 342, 700] {
            for textScale in [1.0, 1.5, 2.5, 3.2] {
                let items = recoveryItems(width: width, textScale: textScale)
                let top = 14 * textScale + 22
                let layout = try XCTUnwrap(StudioPlanLabelLayout(items: items, width: width, height: 280, reservedTop: top))
                assertSafe(layout, items: items, width: width, height: 280, top: top)
                XCTAssertEqual(layout, StudioPlanLabelLayout(items: items, width: width, height: 280, reservedTop: top))
            }
        }
    }

    func testCoincidentMarkersRemainCoincidentAndSelectedCaptionHasPriority() throws {
        let items = (0..<14).map { index in
            Item(anchorX: 110, anchorY: 140, captionWidth: 80, captionHeight: 28, isSelected: index == 13)
        }
        let layout = try XCTUnwrap(StudioPlanLabelLayout(items: items, width: 220, height: 280))
        XCTAssertEqual(layout.crowdedMarkerIndices, Array(0..<14))
        XCTAssertGreaterThan(layout.omittedCaptionCount, 0)
        XCTAssertNotNil(layout.captionFrames[13])
        XCTAssertEqual(Set(layout.markerFrames.map(\.centerX)), [110])
        XCTAssertEqual(Set(layout.markerFrames.map(\.centerY)), [140])
        assertSafe(layout, items: items, width: 220, height: 280, top: 32)
    }

    func testOversizedCaptionIsOmittedInsteadOfShrunkOrClipped() throws {
        let items = [Item(anchorX: 60, anchorY: 60, captionWidth: 200, captionHeight: 60, isSelected: true)]
        let layout = try XCTUnwrap(StudioPlanLabelLayout(items: items, width: 120, height: 100))
        XCTAssertEqual(layout.omittedCaptionCount, 1)
        XCTAssertNil(layout.captionFrames[0])
        XCTAssertEqual(layout.markerFrames[0].centerX, 60)
        XCTAssertEqual(layout.markerFrames[0].centerY, 60)
        // Native UI separately retains the bounded selected name below the plan.
    }

    func testInvalidGeometryAndUnboundedMarkerCountsAreRejected() {
        let valid = Item(anchorX: 50, anchorY: 50, captionWidth: 40, captionHeight: 14)
        XCTAssertNil(StudioPlanLabelLayout(items: [valid], width: .nan, height: 200))
        XCTAssertNil(StudioPlanLabelLayout(items: [valid], width: 200, height: 0))
        XCTAssertNil(StudioPlanLabelLayout(items: [valid], width: 200, height: 200, reservedTop: -1))
        XCTAssertNil(StudioPlanLabelLayout(items: [.init(anchorX: .infinity, anchorY: 50, captionWidth: 40, captionHeight: 14)], width: 200, height: 200))
        XCTAssertNil(StudioPlanLabelLayout(items: [.init(anchorX: 50, anchorY: 50, captionWidth: 0, captionHeight: 14)], width: 200, height: 200))
        XCTAssertNil(StudioPlanLabelLayout(items: Array(repeating: valid, count: 15), width: 200, height: 200))
    }

    func testZeroMarkersAndTinyViewportAreFiniteAndExplicit() throws {
        let empty = try XCTUnwrap(StudioPlanLabelLayout(items: [], width: 1, height: 1))
        XCTAssertEqual(empty.omittedCaptionCount, 0)
        let items = [Item(anchorX: 0.5, anchorY: 0.5, captionWidth: 40, captionHeight: 14)]
        let tiny = try XCTUnwrap(StudioPlanLabelLayout(items: items, width: 1, height: 1))
        XCTAssertEqual(tiny.omittedCaptionCount, 1)
        XCTAssertEqual(tiny.markerFrames[0].centerX, 0.5)
    }
}
