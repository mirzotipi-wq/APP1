import Combine
import XCTest
@testable import KeyAndFill

@MainActor
final class EntitlementStoreConfigurationTests: XCTestCase {
    private func assertUnconfigured(_ store: EntitlementStore,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(store.productID, file: file, line: line)
        XCTAssertFalse(store.isConfigured, file: file, line: line)
        XCTAssertEqual(store.entitlement, .unconfigured, file: file, line: line)
        XCTAssertEqual(store.productState, .unconfigured, file: file, line: line)
        XCTAssertNil(store.product, file: file, line: line)
        XCTAssertNil(store.productName, file: file, line: line)
        XCTAssertNil(store.displayPrice, file: file, line: line)
        XCTAssertEqual(store.activity, .idle, file: file, line: line)
        XCTAssertFalse(store.isBusy, file: file, line: line)
        XCTAssertFalse(store.isPurchasePending, file: file, line: line)
        XCTAssertFalse(store.hasLifetimeAccess, file: file, line: line)
        XCTAssertFalse(store.canPurchase, file: file, line: line)
    }

    func testCurrentPrereleaseBuildHasNoConfiguredProduct() {
        // Sales are intentionally disabled until the owner approves configuration.
        // Do not construct a configured store if that contract regresses.
        XCTAssertNil(EntitlementStore.configuredProductID)
        guard EntitlementStore.configuredProductID == nil else { return }
        let store = EntitlementStore()
        assertUnconfigured(store)
        XCTAssertNil(store.lastOutcome)
    }

    func testNilEmptyAndWhitespaceOnlyIdentifiersDisableSales() {
        let identifiers: [String?] = [nil, "", " ", "\t\r\n", " \t\n ", "\u{00A0}\u{2003}"]
        for identifier in identifiers {
            let store = EntitlementStore(productID: identifier)
            assertUnconfigured(store)
            XCTAssertNil(store.lastOutcome)
        }
    }

    func testUnexpandedBuildSettingsAndEmbeddedWhitespaceDisableSales() {
        // Every input is invalid: none starts a configured StoreKit lookup.
        let identifiers = [
            "$(KEYFILL_PRO_PRODUCT_ID)",
            "${KEYFILL_PRO_PRODUCT_ID}",
            " \t$(KEYFILL_PRO_PRODUCT_ID)\n",
            "com.example.$(PRODUCT_NAME).lifetime",
            "com.example.${PRODUCT_NAME}.lifetime",
            "com.example.pro lifetime",
            "com.example.pro\tlifetime",
            "com.example.pro\nlifetime",
            "com.example.pro\u{00A0}lifetime",
            "com.example.pro\u{2003}lifetime",
        ]
        for identifier in identifiers {
            let store = EntitlementStore(productID: identifier)
            assertUnconfigured(store)
            XCTAssertNil(store.lastOutcome)
        }
    }

    func testUnconfiguredRefreshPreservesIdleStateAndNoOutcome() async {
        let store = EntitlementStore(productID: nil)
        await store.refresh()
        assertUnconfigured(store)
        XCTAssertNil(store.lastOutcome)
    }

    func testUnconfiguredPurchaseAndRestoreReturnWithoutStartingActivity() async {
        let store = EntitlementStore(productID: nil)
        var activities: [EntitlementStore.Activity] = []
        let observation = store.$activity.sink { activities.append($0) }
        defer { observation.cancel() }
        let purchase = await store.purchase()
        XCTAssertEqual(purchase, .unconfigured)
        XCTAssertEqual(store.lastOutcome, .unconfigured)
        assertUnconfigured(store)

        store.clearOutcome()
        XCTAssertNil(store.lastOutcome)
        let restore = await store.restorePurchases()
        XCTAssertEqual(restore, .unconfigured)
        XCTAssertEqual(store.lastOutcome, .unconfigured)
        assertUnconfigured(store)

        await store.refresh()
        XCTAssertEqual(store.lastOutcome, .unconfigured)
        store.clearOutcome()
        XCTAssertNil(store.lastOutcome)
        assertUnconfigured(store)
        XCTAssertEqual(activities, [.idle], "Disabled actions must never publish a payment activity")
    }

    func testCancelledUnconfiguredActionsRemainTerminalAndIdle() async {
        let store = EntitlementStore(productID: nil)
        let operation = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            XCTAssertTrue(Task.isCancelled)
            await store.refresh()
            let purchase = await store.purchase()
            let restore = await store.restorePurchases()
            return (purchase, restore)
        }
        let (purchase, restore) = await operation.value
        XCTAssertEqual(purchase, .unconfigured)
        XCTAssertEqual(restore, .unconfigured)
        XCTAssertEqual(store.lastOutcome, .unconfigured)
        assertUnconfigured(store)
    }
}
