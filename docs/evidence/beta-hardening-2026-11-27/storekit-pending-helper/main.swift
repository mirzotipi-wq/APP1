import Foundation
import XCTest

final class EntitlementAttemptPortableWitness: XCTestCase {
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

XCTMain([testCase([
    ("testPendingApprovalThenRevocationResolvesWithoutPurchasedSnapshot", EntitlementAttemptPortableWitness.testPendingApprovalThenRevocationResolvesWithoutPurchasedSnapshot),
    ("testHistoricalRevocationDoesNotClearNewPendingApproval", EntitlementAttemptPortableWitness.testHistoricalRevocationDoesNotClearNewPendingApproval),
    ("testMatchingVerifiedCompletionBeforePendingResultCannotReopenApproval", EntitlementAttemptPortableWitness.testMatchingVerifiedCompletionBeforePendingResultCannotReopenApproval),
    ("testHistoricalCompletionBeforePendingResultStillAllowsPendingState", EntitlementAttemptPortableWitness.testHistoricalCompletionBeforePendingResultStillAllowsPendingState),
    ("testOlderCompletionCannotResolveReplacementAttempt", EntitlementAttemptPortableWitness.testOlderCompletionCannotResolveReplacementAttempt),
    ("testPurchasedEntitlementResolvesPendingWithoutRequestToken", EntitlementAttemptPortableWitness.testPurchasedEntitlementResolvesPendingWithoutRequestToken)
])])
