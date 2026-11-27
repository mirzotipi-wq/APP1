import Combine
import Foundation
import StoreKit

/// StoreKit facts only. Feature limits and the decision to offer a sale belong to
/// the owner-approved product policy, not this service.
@MainActor
final class EntitlementStore: ObservableObject {
    enum Entitlement: Equatable, Sendable {
        case unconfigured, checking, notPurchased, purchased, revoked, unverified
    }

    enum ProductState: Equatable, Sendable {
        case unconfigured, loading, available, unavailable
        case failed(String)
    }

    enum Activity: Equatable, Sendable {
        case idle, purchasing, restoring
    }

    enum Outcome: Equatable, Sendable {
        case purchased, restored, cancelled, pending, nothingToRestore
        case revoked, unverified, unconfigured, unavailable, busy
        case failed(String)
    }

    /// No fallback SKU or price: an absent/unexpanded build setting disables sales.
    nonisolated static var configuredProductID: String? {
        normalizedProductID(Bundle.main.object(forInfoDictionaryKey: "KEYFILL_PRO_PRODUCT_ID") as? String)
    }

    let productID: String?
    @Published private(set) var entitlement: Entitlement
    @Published private(set) var productState: ProductState
    @Published private(set) var product: Product?
    @Published private(set) var activity: Activity = .idle
    @Published private(set) var lastOutcome: Outcome?
    @Published private var purchaseAttempt: EntitlementPurchaseAttempt?

    var isConfigured: Bool { productID != nil }
    var isPurchasePending: Bool { purchaseAttempt?.isPending == true }
    var isBusy: Bool { activity != .idle }
    var hasLifetimeAccess: Bool { entitlement == .purchased }
    var displayPrice: String? { product?.displayPrice }
    var productName: String? { product?.displayName }
    var canPurchase: Bool {
        productState == .available && !isBusy && !hasLifetimeAccess
            && !isPurchasePending && entitlement != .checking
    }

    private var updatesTask: Task<Void, Never>?
    private var startupTask: Task<Void, Never>?
    private var isLoadingProduct = false
    private var entitlementRevision = UUID()
    private var finishingTransactions: Set<UInt64> = []

    init(productID: String? = EntitlementStore.configuredProductID) {
        let configuredID = Self.normalizedProductID(productID)
        self.productID = configuredID
        entitlement = configuredID == nil ? .unconfigured : .checking
        productState = configuredID == nil ? .unconfigured : .loading
        guard let configuredID else { return }

        // Do not bind self outside this loop: the next update may never arrive.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                await self?.receiveUpdate(result)
            }
        }
        isLoadingProduct = true
        startupTask = Task { [weak self] in
            await self?.refreshEntitlements()
            guard !Task.isCancelled else { return }
            // The potentially network-bound lookup holds no strong store reference.
            let lookup = await Self.fetchProduct(productID: configuredID)
            guard !Task.isCancelled else { return }
            self?.product = lookup.product
            self?.productState = lookup.state
            self?.isLoadingProduct = false
        }
    }

    deinit {
        updatesTask?.cancel()
        startupTask?.cancel()
    }

    /// Safe at launch or when the app becomes active. Never prompts for restore.
    /// StoreKit's verified on-device transactions are the entitlement authority;
    /// product lookup failure does not alter an already verified entitlement.
    func refresh() async {
        guard isConfigured, !Task.isCancelled else { return }
        await refreshEntitlements()
        guard !Task.isCancelled else { return }
        await loadProduct()
    }

    @discardableResult
    func purchase() async -> Outcome {
        guard !isBusy else { return .busy }
        guard isConfigured else { return record(.unconfigured) }
        guard !Task.isCancelled else { return record(.cancelled) }
        if hasLifetimeAccess { return record(.purchased) }
        if isPurchasePending { return record(.pending) }
        guard canPurchase, let product else { return record(.unavailable) }
        // This account-free flow uses a request token to distinguish a completed
        // approval from an older refunded purchase of the same product.
        let attemptToken = UUID()
        purchaseAttempt = EntitlementPurchaseAttempt(token: attemptToken)

        activity = .purchasing
        lastOutcome = nil
        defer {
            activity = .idle
            if !isPurchasePending { purchaseAttempt = nil }
        }
        do {
            switch try await product.purchase(options: [.appAccountToken(attemptToken)]) {
            case .success(let result):
                return record(await processPurchase(result))
            case .userCancelled:
                return record(.cancelled)
            case .pending:
                // Approval may have arrived through updates while purchase awaited.
                // A subsequent revocation must not let this older result reopen
                // an approval that the store has already observed completing.
                purchaseAttempt?.receivePendingResult()
                return record(isPurchasePending ? .pending : currentPurchaseOutcome)
            @unknown default:
                return record(.failed("The App Store returned an unsupported purchase result. Try again."))
            }
        } catch {
            return record(Self.outcome(for: error))
        }
    }

    /// Call only from an explicit Restore Purchases action: sync can ask the user
    /// to authenticate. A failed network sync never clears local verified access.
    @discardableResult
    func restorePurchases() async -> Outcome {
        guard !isBusy else { return .busy }
        guard isConfigured else { return record(.unconfigured) }
        guard !Task.isCancelled else { return record(.cancelled) }
        activity = .restoring
        lastOutcome = nil
        defer { activity = .idle }

        do {
            try await AppStore.sync()
        } catch {
            await refreshEntitlements()
            return record(Self.outcome(for: error))
        }
        await refreshEntitlements()
        guard !Task.isCancelled else { return record(.cancelled) }
        switch entitlement {
        case .purchased: return record(.restored)
        case .notPurchased: return record(isPurchasePending ? .pending : .nothingToRestore)
        case .revoked: return record(.revoked)
        case .unverified: return record(.unverified)
        case .unconfigured: return record(.unconfigured)
        case .checking: return record(.failed("Purchase verification has not completed. Try again."))
        }
    }

    func clearOutcome() { lastOutcome = nil }

    private func loadProduct() async {
        guard let productID, !isLoadingProduct, !Task.isCancelled else { return }
        isLoadingProduct = true
        productState = .loading
        defer {
            isLoadingProduct = false
            if productState == .loading {
                productState = product == nil ? .unavailable : .available
            }
        }
        let lookup = await Self.fetchProduct(productID: productID)
        guard !Task.isCancelled else { return }
        product = lookup.product
        productState = lookup.state
    }

    private func refreshEntitlements() async {
        guard let productID, !Task.isCancelled else { return }
        entitlementRevision = UUID()
        while !Task.isCancelled {
            let revision = entitlementRevision
            let current = await Self.readEntitlement(productID: productID)
            guard !Task.isCancelled else { return }
            // A purchase, restore or another refresh may have overtaken this read.
            // Re-read current facts rather than publishing the older snapshot.
            guard revision == entitlementRevision else { continue }
            entitlement = current.entitlement
            // A restore or refresh that finds no entitlement cannot establish
            // that an outstanding approval was declined or cancelled.
            if current.entitlement == .purchased {
                purchaseAttempt?.observePurchasedEntitlement()
            }
            for token in current.verifiedTransactionTokens {
                purchaseAttempt?.observeVerifiedTransaction(token: token)
            }
            return
        }
    }

    private func receiveUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard isRelevant(transaction) else { return }
            lastOutcome = await processVerifiedTransaction(transaction)
        case .unverified(let transaction, _):
            guard transaction.productID == productID else { return }
            // Untrusted data cannot grant or revoke access. Recheck StoreKit facts.
            await refreshEntitlements()
            lastOutcome = .unverified
        }
    }

    private func processPurchase(_ result: VerificationResult<Transaction>) async -> Outcome {
        switch result {
        case .verified(let transaction):
            guard isRelevant(transaction) else {
                return .failed("The App Store returned a transaction for a different product type or identifier.")
            }
            return await processVerifiedTransaction(transaction)
        case .unverified:
            await refreshEntitlements()
            return .unverified
        }
    }

    private func processVerifiedTransaction(_ transaction: Transaction) async -> Outcome {
        guard isRelevant(transaction) else { return .unavailable }
        // This finite task deliberately outlives cancellation of a purchase view.
        // It is not stored on self, and never waits on the endless updates stream.
        let handling = Task<Outcome, Never> { @MainActor [self] in
            await refreshEntitlements()
            // Publish current facts before resolving approval, so a late pending
            // result cannot return a stale outcome or admit a purchase early.
            // An older handler can resolve only its own matching request token.
            purchaseAttempt?.observeVerifiedTransaction(token: transaction.appAccountToken)
            guard entitlement == .purchased || entitlement == .revoked else {
                return currentPurchaseOutcome
            }
            // Publish the entitlement before acknowledging delivery. Only verified
            // transactions for this nonconsumable ever reach finish().
            if finishingTransactions.insert(transaction.id).inserted {
                await transaction.finish()
                finishingTransactions.remove(transaction.id)
            }
            return currentPurchaseOutcome
        }
        return await handling.value
    }

    private func isRelevant(_ transaction: Transaction) -> Bool {
        transaction.productID == productID && transaction.productType == .nonConsumable
    }

    private func record(_ outcome: Outcome) -> Outcome {
        lastOutcome = outcome
        return outcome
    }

    private var currentPurchaseOutcome: Outcome {
        switch entitlement {
        case .purchased: return .purchased
        case .revoked: return .revoked
        case .unverified: return .unverified
        default:
            return .failed("The transaction was verified, but no current entitlement is available. Try Restore Purchases.")
        }
    }

    nonisolated private static func fetchProduct(productID: String) async -> (product: Product?, state: ProductState) {
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first(where: { $0.id == productID }) else {
                return (nil, .unavailable)
            }
            guard product.type == .nonConsumable else {
                return (nil, .failed("The configured product is not a lifetime purchase."))
            }
            return (product, .available)
        } catch {
            return (nil, .failed(error.localizedDescription))
        }
    }

    nonisolated private static func readEntitlement(productID: String) async
        -> (entitlement: Entitlement, verifiedTransactionTokens: Set<UUID>) {
        var sawUnverified = false
        var sawRevoked = false
        var verifiedTransactionTokens: Set<UUID> = []
        for await result in Transaction.currentEntitlements {
            guard !Task.isCancelled else { return (.checking, verifiedTransactionTokens) }
            switch result {
            case .verified(let transaction):
                guard transaction.productID == productID,
                      transaction.productType == .nonConsumable else { continue }
                if let token = transaction.appAccountToken {
                    verifiedTransactionTokens.insert(token)
                }
                if transaction.revocationDate == nil { return (.purchased, verifiedTransactionTokens) }
                sawRevoked = true
            case .unverified(let transaction, _):
                if transaction.productID == productID { sawUnverified = true }
            }
        }
        if sawUnverified { return (.unverified, verifiedTransactionTokens) }
        if sawRevoked { return (.revoked, verifiedTransactionTokens) }
        guard !Task.isCancelled else { return (.checking, verifiedTransactionTokens) }

        // Refunded/revoked products are absent from currentEntitlements. History
        // distinguishes revocation from never purchased; it never grants access.
        if let latest = await Transaction.latest(for: productID) {
            switch latest {
            case .verified(let transaction):
                if transaction.productID == productID,
                   transaction.productType == .nonConsumable,
                   transaction.revocationDate != nil {
                    if let token = transaction.appAccountToken {
                        verifiedTransactionTokens.insert(token)
                    }
                    return (.revoked, verifiedTransactionTokens)
                }
            case .unverified(let transaction, _):
                if transaction.productID == productID { return (.unverified, verifiedTransactionTokens) }
            }
        }
        return (.notPurchased, verifiedTransactionTokens)
    }

    nonisolated private static func normalizedProductID(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty, !value.contains("$("), !value.contains("${"),
              value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        return value
    }

    nonisolated private static func outcome(for error: Error) -> Outcome {
        if error is CancellationError { return .cancelled }
        if let storeError = error as? StoreKitError, case .userCancelled = storeError { return .cancelled }
        return .failed(error.localizedDescription)
    }
}
