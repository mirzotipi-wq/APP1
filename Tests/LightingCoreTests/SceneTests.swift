import XCTest
import Foundation
@testable import LightingCore

final class SceneTests: XCTestCase {
    func testPortraitRoundTrip() throws {
        let scene = LightingScene.portrait()
        XCTAssertEqual(try SceneCodec.decode(SceneCodec.encode(scene)), scene)
    }

    func testInverseSquare() throws {
        let near = try XCTUnwrap(Photometry.normalIlluminance(candela: 100, distanceMeters: 1))
        let far = try XCTUnwrap(Photometry.normalIlluminance(candela: 100, distanceMeters: 2))
        XCTAssertEqual(near, 100, accuracy: 0.000001)
        XCTAssertEqual(far, near / 4, accuracy: 0.000001)
    }

    func testInvalidPhotometry() {
        XCTAssertNil(Photometry.normalIlluminance(candela: -1, distanceMeters: 1))
        XCTAssertNil(Photometry.normalIlluminance(candela: 1, distanceMeters: 0))
        XCTAssertNil(Photometry.normalIlluminance(candela: .nan, distanceMeters: 1))
        XCTAssertNil(Photometry.normalIlluminance(candela: 1, distanceMeters: .infinity))
    }

    func testRejectDuplicateIDs() {
        var scene = LightingScene.portrait()
        scene.lights.append(scene.lights[0])
        XCTAssertThrowsError(try scene.validated()) { XCTAssertEqual($0 as? SceneError, .duplicateLight) }
    }

    func testRejectInvalidLight() {
        var scene = LightingScene.portrait()
        scene.lights[0].kelvin = -1
        XCTAssertThrowsError(try SceneCodec.encode(scene))
    }

    func testRejectUnknownSchema() {
        var scene = LightingScene.portrait()
        scene.schemaVersion = 99
        XCTAssertThrowsError(try scene.validated())
    }

    func testRejectOversizedAndMalformedData() {
        XCTAssertThrowsError(try SceneCodec.decode(Data(repeating: 0, count: SceneCodec.maximumBytes + 1)))
        XCTAssertThrowsError(try SceneCodec.decode(Data("not JSON".utf8)))
    }

    func testDistance() {
        XCTAssertEqual(Position(x: 0, y: 0, z: 0).distance(to: Position(x: 3, y: 4, z: 0)), 5)
    }
}
