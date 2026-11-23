import Foundation
import XCTest
@testable import LightingCore

final class StudyComputeInputTests: XCTestCase {
    func testPackedInputUsesAlignedRowsAndSharedPhotometricSamples() throws {
        var scene = LightingScene.portrait()
        scene.lights[0].optics = .init(kind: .rectangle, widthMeters: 1.2, heightMeters: 0.8)
        scene.lights[1].optics = .init(kind: .directional)
        scene.lights[2].candela = 0
        let packed = try StudyComputeInput(scene: scene, width: 120)
        XCTAssertEqual(MemoryLayout<SIMD4<Float>>.stride, 16)
        XCTAssertEqual(packed.width, 120); XCTAssertEqual(packed.height, 80)
        XCTAssertEqual(packed.parameters.count, 6)
        XCTAssertEqual(packed.parameters[5].x, 65); XCTAssertEqual(packed.parameters[5].y, 1)
        XCTAssertEqual(packed.samples.count, 65 * 3); XCTAssertEqual(packed.areas.count, 3)
        let summed = stride(from: 0, to: 64 * 3, by: 3).reduce(Float(0)) { $0 + packed.samples[$1].w }
        XCTAssertEqual(summed, Float(scene.lights[0].candela), accuracy: 0.001)
        XCTAssertEqual(packed.samples[64 * 3].w, Float(scene.lights[1].candela))
        XCTAssertEqual(packed.samples[1].w, 1)
        XCTAssertEqual(packed.areas[0].w, 0.3, accuracy: 1e-6)
        XCTAssertEqual(packed.areas[1].w, 0.6, accuracy: 1e-6)
        XCTAssertEqual(packed.areas[2].w, 0.4, accuracy: 1e-6)
        XCTAssertEqual(packed.parameters[0], .init(0, 0, 3, 0.36))
        for row in packed.parameters + packed.samples + packed.areas {
            XCTAssertTrue(row.x.isFinite && row.y.isFinite && row.z.isFinite && row.w.isFinite)
        }
    }

    func testSubjectTranslationPreservesPackedGeometry() throws {
        var scene = LightingScene.portrait()
        let original = try StudyComputeInput(scene: scene, width: 48)
        func moved(_ p: Position) -> Position { .init(x: p.x + 20, y: p.y + 10, z: p.z - 13) }
        scene.subject = moved(scene.subject); scene.camera = moved(scene.camera)
        for i in scene.lights.indices { scene.lights[i].position = moved(scene.lights[i].position) }
        let shifted = try StudyComputeInput(scene: scene, width: 48)
        XCTAssertEqual(original.parameters, shifted.parameters)
        XCTAssertEqual(original.samples, shifted.samples)
    }

    func testComputeOutputFlagsAndBounds() throws {
        let width = 24, height = 16
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        bytes[1] = 0; bytes[3] = 0
        bytes[5] = 0 // Actual opaque magenta is not an invalid flag.
        let result = try StudyImage.fromComputeRGBA(width: width, height: height, data: Data(bytes))
        XCTAssertEqual(result.unsupportedPixels, 1)
        XCTAssertEqual(result.rgba[3], 255); XCTAssertEqual(result.rgba[7], 255)
        bytes[3] = 1
        XCTAssertThrowsError(try StudyImage.fromComputeRGBA(width: width, height: height, data: Data(bytes)))
        bytes[3] = 0; bytes[0] = 0
        XCTAssertThrowsError(try StudyImage.fromComputeRGBA(width: width, height: height, data: Data(bytes)))
        XCTAssertThrowsError(try StudyImage.fromComputeRGBA(width: 192, height: 128, data: Data()))
        XCTAssertThrowsError(try StudyImage.fromComputeRGBA(width: Int.max, height: Int.max, data: Data()))
    }

    func testSharedValidationAndInactiveLights() throws {
        var scene = LightingScene.portrait()
        scene.lights = []
        let packed = try StudyComputeInput(scene: scene, width: 24)
        XCTAssertTrue(packed.samples.isEmpty && packed.areas.isEmpty)
        XCTAssertEqual(packed.parameters[5].x, 0)
        XCTAssertThrowsError(try StudyComputeInput(scene: scene, width: 193))
        scene.camera = scene.subject
        XCTAssertThrowsError(try StudyComputeInput(scene: scene, width: 24)) { XCTAssertEqual($0 as? StudyError, .invalidCamera) }
    }
}
