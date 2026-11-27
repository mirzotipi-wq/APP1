import XCTest
import LightingCore

final class StudyFrameCacheTests: XCTestCase {
    private typealias Cache = StudyFrameCache<Int, String>

    private func assertCosts(_ cache: Cache, count: Int, pixels: Int, masks: Int,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(cache.count, count, file: file, line: line)
        XCTAssertEqual(cache.pixelBytes, pixels, file: file, line: line)
        XCTAssertEqual(cache.maskBytes, masks, file: file, line: line)
        XCTAssertLessThanOrEqual(cache.count, cache.maximumCount, file: file, line: line)
        XCTAssertLessThanOrEqual(cache.pixelBytes, cache.maximumPixelBytes, file: file, line: line)
        XCTAssertLessThanOrEqual(cache.maskBytes, cache.maximumMaskBytes, file: file, line: line)
    }

    func testEmptyCacheRetainsConfiguredLimitsAndMissDoesNotChangeCosts() {
        var cache = Cache(maximumCount: 4, maximumPixelBytes: 256 * 1024,
                          maximumMaskBytes: 64 * 1024)
        XCTAssertEqual(cache.maximumCount, 4)
        XCTAssertEqual(cache.maximumPixelBytes, 256 * 1024)
        XCTAssertEqual(cache.maximumMaskBytes, 64 * 1024)
        XCTAssertNil(cache.value(for: 0))
        assertCosts(cache, count: 0, pixels: 0, masks: 0)
    }

    func testEntryLimitBoundsZeroCostValues() {
        var cache = Cache(maximumCount: 4, maximumPixelBytes: 1, maximumMaskBytes: 1)
        for key in 0..<100 {
            XCTAssertTrue(cache.insert("frame-\(key)", for: key, pixelBytes: 0, maskBytes: 0))
            assertCosts(cache, count: min(key + 1, 4), pixels: 0, masks: 0)
        }
        for key in 0..<96 { XCTAssertNil(cache.value(for: key)) }
        for key in 96..<100 { XCTAssertEqual(cache.value(for: key), "frame-\(key)") }
    }

    func testHitPromotesRecencyAndMissDoesNotProtectOldestEntry() {
        var cache = Cache(maximumCount: 3, maximumPixelBytes: 100, maximumMaskBytes: 100)
        for key in 1...3 { cache.insert("frame-\(key)", for: key, pixelBytes: 4, maskBytes: 1) }
        XCTAssertEqual(cache.value(for: 1), "frame-1")
        XCTAssertNil(cache.value(for: 99))
        cache.insert("frame-4", for: 4, pixelBytes: 4, maskBytes: 1)
        XCTAssertNil(cache.value(for: 2))
        cache.insert("frame-5", for: 5, pixelBytes: 4, maskBytes: 1)
        XCTAssertNil(cache.value(for: 3))
        for key in [1, 4, 5] { XCTAssertEqual(cache.value(for: key), "frame-\(key)") }
        assertCosts(cache, count: 3, pixels: 12, masks: 3)
    }

    func testPixelBudgetEvictsMultipleOldestEntriesBeforeCountLimit() {
        var cache = Cache(maximumCount: 4, maximumPixelBytes: 12, maximumMaskBytes: 100)
        for key in 1...3 { cache.insert("frame-\(key)", for: key, pixelBytes: 3, maskBytes: key) }
        cache.insert("frame-4", for: 4, pixelBytes: 8, maskBytes: 4)
        assertCosts(cache, count: 2, pixels: 11, masks: 7)
        XCTAssertNil(cache.value(for: 1))
        XCTAssertNil(cache.value(for: 2))
        XCTAssertEqual(cache.value(for: 3), "frame-3")
        XCTAssertEqual(cache.value(for: 4), "frame-4")
    }

    func testMaskBudgetIndependentlyEvictsAndSubtractsBothCosts() {
        var cache = Cache(maximumCount: 4, maximumPixelBytes: 100, maximumMaskBytes: 12)
        for key in 1...3 { cache.insert("frame-\(key)", for: key, pixelBytes: 10 - key, maskBytes: 3) }
        cache.insert("frame-4", for: 4, pixelBytes: 6, maskBytes: 8)
        assertCosts(cache, count: 2, pixels: 13, masks: 11)
        XCTAssertNil(cache.value(for: 1))
        XCTAssertNil(cache.value(for: 2))
        XCTAssertEqual(cache.value(for: 3), "frame-3")
        XCTAssertEqual(cache.value(for: 4), "frame-4")
    }

    func testProductionPayloadBudgetsRemainBoundedAcrossMixedFrameSizes() {
        var cache = Cache(maximumCount: 4, maximumPixelBytes: 256 * 1024,
                          maximumMaskBytes: 64 * 1024)
        let pixelsPerFrame = [192 * 128, 144 * 96, 24 * 16, 48 * 32]
        for key in 0..<100 {
            let pixels = pixelsPerFrame[key % pixelsPerFrame.count]
            XCTAssertTrue(cache.insert("frame-\(key)", for: key,
                                       pixelBytes: pixels * 4, maskBytes: pixels))
            XCTAssertLessThanOrEqual(cache.count, 4)
            XCTAssertLessThanOrEqual(cache.pixelBytes, 256 * 1024)
            XCTAssertLessThanOrEqual(cache.maskBytes, 64 * 1024)
            XCTAssertEqual(cache.pixelBytes, cache.maskBytes * 4)
            XCTAssertEqual(cache.value(for: key), "frame-\(key)")
        }
        // A large sphere frame can coexist with one other large frame; a third
        // must evict the oldest even though the four-entry limit is not full.
        cache.removeAll { _ in true }
        for key in 1...3 {
            cache.insert("sphere-\(key)", for: key, pixelBytes: 192 * 128 * 4,
                         maskBytes: 192 * 128)
        }
        assertCosts(cache, count: 2, pixels: 192 * 128 * 4 * 2, masks: 192 * 128 * 2)
        XCTAssertNil(cache.value(for: 1))
        XCTAssertEqual(cache.value(for: 2), "sphere-2")
        XCTAssertEqual(cache.value(for: 3), "sphere-3")
    }

    func testReplacementChargesNewCostsOnlyAndBecomesMostRecent() {
        var cache = Cache(maximumCount: 2, maximumPixelBytes: 10, maximumMaskBytes: 10)
        cache.insert("old", for: 1, pixelBytes: 4, maskBytes: 3)
        cache.insert("other", for: 2, pixelBytes: 5, maskBytes: 2)
        XCTAssertTrue(cache.insert("replacement", for: 1, pixelBytes: 2, maskBytes: 6))
        assertCosts(cache, count: 2, pixels: 7, masks: 8)
        cache.insert("newest", for: 3, pixelBytes: 1, maskBytes: 1)
        XCTAssertNil(cache.value(for: 2))
        XCTAssertEqual(cache.value(for: 1), "replacement")
        XCTAssertEqual(cache.value(for: 3), "newest")
        assertCosts(cache, count: 2, pixels: 3, masks: 7)
    }

    func testLargerReplacementRemovesOldChargeBeforeEvictingOtherEntries() {
        var cache = Cache(maximumCount: 3, maximumPixelBytes: 10, maximumMaskBytes: 10)
        for key in 1...3 { cache.insert("frame-\(key)", for: key, pixelBytes: 3, maskBytes: key) }
        cache.insert("larger", for: 1, pixelBytes: 7, maskBytes: 5)
        assertCosts(cache, count: 2, pixels: 10, masks: 8)
        XCTAssertNil(cache.value(for: 2))
        XCTAssertEqual(cache.value(for: 3), "frame-3")
        XCTAssertEqual(cache.value(for: 1), "larger")
    }

    func testInvalidAndOversizedCostsRejectWithoutReplacementOrRecencyChanges() {
        let invalidCosts = [(-1, 0), (0, -1), (Int.min, 1), (1, Int.min),
                            (11, 1), (1, 9), (Int.max, 1), (1, Int.max),
                            (Int.max, Int.max)]
        for (pixels, masks) in invalidCosts {
            for rejectedKey in [1, 99] {
                var cache = Cache(maximumCount: 2, maximumPixelBytes: 10, maximumMaskBytes: 8)
                cache.insert("oldest", for: 1, pixelBytes: 4, maskBytes: 2)
                cache.insert("newest", for: 2, pixelBytes: 4, maskBytes: 2)
                XCTAssertFalse(cache.insert("rejected", for: rejectedKey,
                                            pixelBytes: pixels, maskBytes: masks))
                assertCosts(cache, count: 2, pixels: 8, masks: 4)
                var snapshot = cache
                XCTAssertEqual(snapshot.value(for: 1), "oldest")
                XCTAssertEqual(snapshot.value(for: 2), "newest")
                XCTAssertNil(snapshot.value(for: 99))
                cache.insert("third", for: 3, pixelBytes: 4, maskBytes: 2)
                XCTAssertNil(cache.value(for: 1), "Rejected admission must not promote the old value")
                XCTAssertEqual(cache.value(for: 2), "newest")
                XCTAssertEqual(cache.value(for: 3), "third")
                assertCosts(cache, count: 2, pixels: 8, masks: 4)
            }
        }
    }

    func testMaximumIntegerBudgetsEvictBeforeAdditionCanOverflow() {
        var cache = Cache(maximumCount: Int.max, maximumPixelBytes: Int.max,
                          maximumMaskBytes: Int.max)
        cache.insert("large", for: 1, pixelBytes: Int.max - 1, maskBytes: Int.max - 2)
        cache.insert("boundary", for: 2, pixelBytes: 1, maskBytes: 2)
        assertCosts(cache, count: 2, pixels: Int.max, masks: Int.max)
        cache.insert("small", for: 3, pixelBytes: 1, maskBytes: 1)
        assertCosts(cache, count: 2, pixels: 2, masks: 3)
        XCTAssertNil(cache.value(for: 1))
        XCTAssertEqual(cache.value(for: 2), "boundary")
        XCTAssertEqual(cache.value(for: 3), "small")
        cache.insert("entire-budget", for: 4, pixelBytes: Int.max, maskBytes: Int.max)
        assertCosts(cache, count: 1, pixels: Int.max, masks: Int.max)
        XCTAssertFalse(cache.insert("invalid", for: 4, pixelBytes: Int.min, maskBytes: Int.max))
        XCTAssertEqual(cache.value(for: 4), "entire-budget")
        cache.removeAll { _ in true }
        assertCosts(cache, count: 0, pixels: 0, masks: 0)
    }

    func testSelectiveBackendRemovalPreservesSurvivorCostsAndRecency() {
        var cache = Cache(maximumCount: 3, maximumPixelBytes: 100, maximumMaskBytes: 100)
        cache.insert("CPU first", for: 1, pixelBytes: 4, maskBytes: 2)
        cache.insert("Metal frame", for: 2, pixelBytes: 7, maskBytes: 3)
        cache.insert("CPU second", for: 3, pixelBytes: 5, maskBytes: 4)
        XCTAssertEqual(cache.value(for: 1), "CPU first")
        cache.removeAll { $0.hasPrefix("Metal") }
        assertCosts(cache, count: 2, pixels: 9, masks: 6)
        XCTAssertNil(cache.value(for: 2))
        cache.insert("CPU third", for: 4, pixelBytes: 6, maskBytes: 1)
        cache.insert("CPU fourth", for: 5, pixelBytes: 3, maskBytes: 3)
        XCTAssertNil(cache.value(for: 3))
        XCTAssertEqual(cache.value(for: 1), "CPU first")
        assertCosts(cache, count: 3, pixels: 13, masks: 6)
        cache.removeAll { _ in false }
        assertCosts(cache, count: 3, pixels: 13, masks: 6)
        cache.removeAll { _ in true }
        assertCosts(cache, count: 0, pixels: 0, masks: 0)
        for key in 1...5 { XCTAssertNil(cache.value(for: key)) }
        cache.removeAll { _ in true }
        cache.insert("fresh", for: 6, pixelBytes: 2, maskBytes: 1)
        assertCosts(cache, count: 1, pixels: 2, masks: 1)
    }

    func testEquivalentNonHashableKeysReplaceAndFindTheSameEntry() {
        struct Key: Equatable, Sendable { let scene: Int; let width: Int }
        var cache = StudyFrameCache<Key, String>(maximumCount: 2, maximumPixelBytes: 100,
                                                maximumMaskBytes: 100)
        cache.insert("original", for: Key(scene: 1, width: 24), pixelBytes: 4, maskBytes: 1)
        cache.insert("new width", for: Key(scene: 1, width: 48), pixelBytes: 8, maskBytes: 2)
        cache.insert("replacement", for: Key(scene: 1, width: 24), pixelBytes: 12, maskBytes: 3)
        XCTAssertEqual(cache.count, 2)
        XCTAssertEqual(cache.pixelBytes, 20)
        XCTAssertEqual(cache.maskBytes, 5)
        XCTAssertEqual(cache.value(for: Key(scene: 1, width: 24)), "replacement")
        XCTAssertEqual(cache.value(for: Key(scene: 1, width: 48)), "new width")
        XCTAssertNil(cache.value(for: Key(scene: 2, width: 24)))
    }

    func testOversizedReplacementRetainsOriginalLifetimeAndRecency() {
        for (pixels, masks) in [(3, 1), (1, 3)] {
            var cache = LifetimeCache(maximumCount: 2, maximumPixelBytes: 2,
                                      maximumMaskBytes: 2)
            let oldest = insertObservedValue(into: &cache, for: 1)
            let newest = insertObservedValue(into: &cache, for: 2)
            let rejected = insertObservedValue(into: &cache, for: 1, pixelBytes: pixels,
                                               maskBytes: masks, expectedAdmission: false)
            withExtendedLifetime(cache) {
                XCTAssertNotNil(oldest.value, "A rejected replacement must retain the original")
                XCTAssertNotNil(newest.value)
                XCTAssertNil(rejected.value, "A rejected value must not be retained")
            }

            // A lookup would promote key 1; a retained cache copy would keep it alive.
            // Observe weak references alone before the next admission tests its LRU position.
            let third = insertObservedValue(into: &cache, for: 3)
            withExtendedLifetime(cache) {
                XCTAssertNil(oldest.value, "A rejected replacement must not promote the original")
                XCTAssertNotNil(newest.value)
                XCTAssertNotNil(third.value)
            }
        }
    }

    func testSuccessfulReplacementReleasesOnlyOriginalAndPromotesReplacement() {
        var cache = LifetimeCache(maximumCount: 2, maximumPixelBytes: 2,
                                  maximumMaskBytes: 2)
        let original = insertObservedValue(into: &cache, for: 1)
        let other = insertObservedValue(into: &cache, for: 2)
        let replacement = insertObservedValue(into: &cache, for: 1)
        withExtendedLifetime(cache) {
            XCTAssertNil(original.value, "The replaced value must be released")
            XCTAssertNotNil(other.value, "Replacement must preserve an unrelated entry")
            XCTAssertNotNil(replacement.value)
        }

        let newest = insertObservedValue(into: &cache, for: 3)
        withExtendedLifetime(cache) {
            XCTAssertNil(other.value)
            XCTAssertNotNil(replacement.value, "The replacement must become most recent")
            XCTAssertNotNil(newest.value)
        }
    }

    func testBudgetEvictionReleasesEveryRemovedValueAndRetainsSurvivors() {
        for (pixels, masks) in [(3, 1), (1, 3)] {
            var cache = LifetimeCache(maximumCount: 4, maximumPixelBytes: 4,
                                      maximumMaskBytes: 4)
            let oldest = insertObservedValue(into: &cache, for: 1)
            let second = insertObservedValue(into: &cache, for: 2)
            let survivor = insertObservedValue(into: &cache, for: 3)
            let admitted = insertObservedValue(into: &cache, for: 4, pixelBytes: pixels,
                                               maskBytes: masks)
            withExtendedLifetime(cache) {
                XCTAssertNil(oldest.value)
                XCTAssertNil(second.value, "Every entry removed for a byte budget must be released")
                XCTAssertNotNil(survivor.value)
                XCTAssertNotNil(admitted.value)
            }
        }
    }

    func testSelectiveInvalidationReleasesOnlyMatchingValuesThenReleasesSurvivors() {
        var cache = LifetimeCache(maximumCount: 4, maximumPixelBytes: 4,
                                  maximumMaskBytes: 4)
        let firstCPU = insertObservedValue(into: &cache, for: 1)
        let firstMetal = insertObservedValue(into: &cache, for: 2, isMetal: true)
        let secondCPU = insertObservedValue(into: &cache, for: 3)
        let secondMetal = insertObservedValue(into: &cache, for: 4, isMetal: true)

        cache.removeAll { $0.isMetal }
        withExtendedLifetime(cache) {
            XCTAssertNil(firstMetal.value)
            XCTAssertNil(secondMetal.value)
            XCTAssertNotNil(firstCPU.value)
            XCTAssertNotNil(secondCPU.value)
        }

        cache.removeAll { _ in false }
        withExtendedLifetime(cache) {
            XCTAssertNotNil(firstCPU.value, "A nonmatching invalidation must retain survivors")
            XCTAssertNotNil(secondCPU.value)
        }

        cache.removeAll { _ in true }
        XCTAssertNil(firstCPU.value)
        XCTAssertNil(secondCPU.value)
        XCTAssertEqual(cache.count, 0)
    }

    private typealias LifetimeCache = StudyFrameCache<Int, LifetimeValue>

    private final class LifetimeValue: Sendable {
        let isMetal: Bool

        init(isMetal: Bool) {
            self.isMetal = isMetal
        }
    }

    private final class WeakValue {
        weak var value: LifetimeValue?

        init(_ value: LifetimeValue) {
            self.value = value
        }
    }

    // The factory returns only a weak observer. Its temporary strong reference
    // ends before the caller checks lifetime; no closure captures the value.
    private func insertObservedValue(into cache: inout LifetimeCache, for key: Int,
                                     isMetal: Bool = false, pixelBytes: Int = 1,
                                     maskBytes: Int = 1, expectedAdmission: Bool = true,
                                     file: StaticString = #filePath, line: UInt = #line) -> WeakValue {
        let value = LifetimeValue(isMetal: isMetal)
        let observer = WeakValue(value)
        XCTAssertEqual(cache.insert(value, for: key, pixelBytes: pixelBytes, maskBytes: maskBytes),
                       expectedAdmission, file: file, line: line)
        return observer
    }
}
