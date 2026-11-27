import Foundation

/// Correlates one in-memory purchase request with its verified transaction.
/// Resolution is sticky because an update can arrive before purchase() returns.
struct EntitlementPurchaseAttempt: Equatable, Sendable {
    let token: UUID
    private(set) var isPending = false
    private(set) var isResolved = false

    mutating func receivePendingResult() {
        isPending = !isResolved
    }

    mutating func observeVerifiedTransaction(token: UUID?) {
        guard token == self.token else { return }
        resolve()
    }

    mutating func observePurchasedEntitlement() {
        resolve()
    }

    private mutating func resolve() {
        isResolved = true
        isPending = false
    }
}
