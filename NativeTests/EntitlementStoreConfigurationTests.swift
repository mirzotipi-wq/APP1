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

    func testPendingApprovalThenRevocationResolvesWithoutPurchasedSnapshot() {
        let token = UUID()
        var attempt = EntitlementPurchaseAttempt(token: token)
        attempt.receivePendingResult()
        XCTAssertTrue(attempt.isPending)

        // The store passes the token from a verified relevant revoked update
        // or history snapshot. No purchased entitlement was ever observed.
        attempt.observeVerifiedTransaction(token: token)
        XCTAssertTrue(attempt.isResolved)
        XCTAssertFalse(attempt.isPending)
    }

    func testHistoricalRevocationDoesNotClearNewPendingApproval() {
        let historicalToken = UUID()
        var attempt = EntitlementPurchaseAttempt(token: UUID())
        attempt.receivePendingResult()

        attempt.observeVerifiedTransaction(token: historicalToken)
        XCTAssertFalse(attempt.isResolved)
        XCTAssertTrue(attempt.isPending)

        // An older purchase may predate request tokens altogether.
        attempt.observeVerifiedTransaction(token: nil)
        XCTAssertFalse(attempt.isResolved)
        XCTAssertTrue(attempt.isPending)
    }

    func testMatchingVerifiedCompletionBeforePendingResultCannotReopenApproval() {
        let token = UUID()
        var attempt = EntitlementPurchaseAttempt(token: token)
        // Updates may complete and revoke approval while purchase() is suspended.
        attempt.observeVerifiedTransaction(token: token)
        attempt.receivePendingResult()
        XCTAssertTrue(attempt.isResolved)
        XCTAssertFalse(attempt.isPending)
        // Duplicate or delayed pending delivery remains terminal.
        attempt.receivePendingResult()
        XCTAssertFalse(attempt.isPending)
    }

    func testHistoricalCompletionBeforePendingResultStillAllowsPendingState() {
        var attempt = EntitlementPurchaseAttempt(token: UUID())
        attempt.observeVerifiedTransaction(token: UUID())
        attempt.observeVerifiedTransaction(token: nil)
        attempt.receivePendingResult()
        XCTAssertFalse(attempt.isResolved)
        XCTAssertTrue(attempt.isPending)
    }

    func testOlderCompletionCannotResolveReplacementAttempt() {
        let firstToken = UUID()
        let secondToken = UUID()
        var attempt = EntitlementPurchaseAttempt(token: firstToken)
        attempt.receivePendingResult()
        attempt.observeVerifiedTransaction(token: firstToken)
        XCTAssertFalse(attempt.isPending)

        attempt = EntitlementPurchaseAttempt(token: secondToken)
        attempt.receivePendingResult()
        attempt.observeVerifiedTransaction(token: firstToken)
        XCTAssertTrue(attempt.isPending)
        XCTAssertFalse(attempt.isResolved)

        attempt.observeVerifiedTransaction(token: secondToken)
        XCTAssertFalse(attempt.isPending)
        XCTAssertTrue(attempt.isResolved)
    }

    func testPurchasedEntitlementResolvesPendingWithoutRequestToken() {
        var attempt = EntitlementPurchaseAttempt(token: UUID())
        attempt.receivePendingResult()
        // Preserve existing behavior for verified restored or shared access.
        attempt.observePurchasedEntitlement()
        XCTAssertTrue(attempt.isResolved)
        XCTAssertFalse(attempt.isPending)
        attempt.receivePendingResult()
        XCTAssertFalse(attempt.isPending)
    }
}
