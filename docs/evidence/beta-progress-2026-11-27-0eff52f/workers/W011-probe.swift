import Foundation

// This driver compiles the unchanged app struct, then compares each observed
// state with a declarative history property, not a second transition machine.
@main
struct W011PurchaseOrderingProbe {
    enum Event: Int, CaseIterable {
        case pending, matchingVerified, previousAttemptVerified, unrelatedVerified, nilVerified, purchasedFact, replaceAttempt
    }
    static let tokens = (0...8).map { index in
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
    }
    static let unrelated = UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!

    static func main() {
        var histories = 0
        var checks = 0
        var maximumDepth = 0
        func walk(_ actual: EntitlementPurchaseAttempt, history: [Event]) {
            // Each replacement starts an independent request with a never-reused
            // token. Only a matching verified fact or purchased entitlement is
            // allowed to resolve that request. Pending cannot undo that fact.
            let generation = history.filter { $0 == .replaceAttempt }.count
            let lastReplacement = history.lastIndex(of: .replaceAttempt)
            let currentHistory = history.suffix(from: lastReplacement.map { $0 + 1 } ?? 0)
            let resolutionExists = currentHistory.contains(.matchingVerified) || currentHistory.contains(.purchasedFact)
            let pendingWasReceived = currentHistory.contains(.pending)
            precondition(actual.token == tokens[generation], "Request token changed unexpectedly: \(history)")
            precondition(actual.isResolved == resolutionExists, "Resolution differs from verified history: \(history)")
            precondition(actual.isPending == (pendingWasReceived && !resolutionExists), "Pending differs from request history: \(history)")
            precondition(!(actual.isPending && actual.isResolved), "Resolved request became pending: \(history)")
            histories += 1
            checks += 4
            maximumDepth = max(maximumDepth, history.count)
            guard history.count < 6 else { return }
            for event in Event.allCases {
                var next = actual
                switch event {
                case .pending: next.receivePendingResult()
                case .matchingVerified: next.observeVerifiedTransaction(token: tokens[generation])
                case .previousAttemptVerified:
                    next.observeVerifiedTransaction(token: generation == 0 ? unrelated : tokens[generation - 1])
                case .unrelatedVerified: next.observeVerifiedTransaction(token: unrelated)
                case .nilVerified: next.observeVerifiedTransaction(token: nil)
                case .purchasedFact: next.observePurchasedEntitlement()
                case .replaceAttempt: next = EntitlementPurchaseAttempt(token: tokens[generation + 1])
                }
                walk(next, history: history + [event])
            }
        }
        walk(EntitlementPurchaseAttempt(token: tokens[0]), history: [])
        precondition(histories == 137257)
        print("W011: \(histories) exhaustive event histories through depth \(maximumDepth); \(checks) invariant checks passed against actual EntitlementPurchaseAttempt.swift.")
        print("No StoreKit service, sandbox transaction, entitlement snapshot, cancellation delivery, or native UI execution was performed.")
    }
}
