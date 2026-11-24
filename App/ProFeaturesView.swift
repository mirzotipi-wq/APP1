import StoreKit
import SwiftUI

/// The app owns this store so a dismissed sheet cannot discard purchase updates.
/// This screen reports StoreKit facts; it does not define or apply feature limits.
@MainActor
struct ProFeaturesView: View {
    @ObservedObject var store: EntitlementStore
    @Environment(\.dismiss) private var dismiss
    @State private var requestedAction: Action?

    private enum Action: Equatable {
        case purchase, restore, refresh
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current pre-release") {
                    Text("All current features are available without a purchase.")
                        .accessibilityIdentifier("proPrereleaseAvailability")
                }

                if store.isConfigured {
                    purchaseStatus
                }

                Section("One-time purchase") {
                    productDetails
                }

                Section {
                    Button {
                        perform(.purchase)
                    } label: {
                        purchaseButtonTitle
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!store.canPurchase || isPerformingAction || purchaseIsPending)
                    .accessibilityIdentifier("purchasePro")

                    Button("Restore Purchases") {
                        perform(.restore)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(!store.isConfigured || isPerformingAction || store.entitlement == .checking)
                    .accessibilityIdentifier("restoreProPurchases")

                    if needsRetry {
                        Button("Try again") {
                            perform(.refresh)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(isPerformingAction || isLoading)
                        .accessibilityHint("Checks purchase status and reloads App Store purchase details.")
                        .accessibilityIdentifier("retryProPurchaseDetails")
                    }

                    actionProgress
                    actionOutcome
                }
            }
            .navigationTitle("Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("closeProFeatures")
                }
            }
        }
    }

    private var purchaseStatus: some View {
        Section("Purchase status") {
            if store.hasLifetimeAccess {
                status(
                    store.lastOutcome == .restored ? "Purchase restored" : "Purchased",
                    symbol: "checkmark.circle",
                    detail: "Your one-time purchase has been verified."
                )
            } else if purchaseIsPending {
                status(
                    "Purchase pending",
                    symbol: "clock",
                    detail: "The App Store has not completed this purchase yet. You can close this sheet and keep using the app."
                )
            } else if store.entitlement == .unverified || store.lastOutcome == .unverified {
                status(
                    "Purchase needs verification",
                    symbol: "questionmark.circle",
                    detail: "A purchase could not be verified. Try again or use Restore Purchases to check its status."
                )
            } else if store.entitlement == .revoked || store.lastOutcome == .revoked {
                status(
                    "Purchase no longer active",
                    symbol: "arrow.uturn.backward.circle",
                    detail: "The App Store reports that this purchase was refunded or revoked. Use Restore Purchases to check its status."
                )
            } else if store.entitlement == .checking {
                ProgressView("Checking purchases")
            } else {
                status(
                    "No verified purchase found",
                    symbol: "creditcard",
                    detail: "Already purchased? Use Restore Purchases to check your App Store account."
                )
            }
        }
        .accessibilityIdentifier("proPurchaseStatus")
    }

    @ViewBuilder
    private var productDetails: some View {
        switch store.productState {
        case .unconfigured:
            status(
                "Purchases unavailable",
                symbol: "info.circle",
                detail: "Purchases are not available in this version of Key & Fill. All current pre-release features remain available."
            )
        case .loading:
            ProgressView("Loading purchase details")
        case .available:
            if let product = store.product {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: product.displayName)
                        .font(.headline)
                    Text(verbatim: product.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(verbatim: product.displayPrice)
                        .font(.title2.weight(.semibold))
                    Text("One-time purchase. No subscription or recurring charges.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("proProductDetails")
            } else {
                unavailableProduct
            }
        case .unavailable:
            unavailableProduct
        case .failed:
            status(
                "Purchase details unavailable",
                symbol: "exclamationmark.circle",
                detail: "The App Store could not provide purchase details. Check your connection and try again."
            )
        }
    }

    private var unavailableProduct: some View {
        status(
            "Purchase unavailable",
            symbol: "info.circle",
            detail: "This purchase is not available from the App Store right now. You can try again later."
        )
    }

    private var purchaseButtonTitle: Text {
        if store.hasLifetimeAccess {
            return Text("Purchased")
        }
        if purchaseIsPending {
            return Text("Purchase pending")
        }
        if store.productState == .available, let product = store.product {
            return Text("Buy once for \(product.displayPrice)")
        }
        if store.productState == .loading {
            return Text("Loading purchase")
        }
        return Text("Purchase unavailable")
    }

    @ViewBuilder
    private var actionProgress: some View {
        if requestedAction == .refresh {
            ProgressView("Refreshing purchases")
        } else if store.activity == .purchasing || requestedAction == .purchase {
            ProgressView("Waiting for the App Store")
        } else if store.activity == .restoring || requestedAction == .restore {
            ProgressView("Restoring purchases")
        }
    }

    @ViewBuilder
    private var actionOutcome: some View {
        if !isPerformingAction, let outcome = store.lastOutcome {
            switch outcome {
            case .cancelled:
                status(
                    "Cancelled",
                    symbol: "info.circle",
                    detail: "You can continue using the app or try again when you are ready."
                )
            case .nothingToRestore:
                status(
                    "No purchase to restore",
                    symbol: "info.circle",
                    detail: "The App Store did not find a current purchase for your account."
                )
            case .failed:
                status(
                    "App Store action could not be completed",
                    symbol: "exclamationmark.circle",
                    detail: "Try again, or use Restore Purchases if you have already purchased."
                )
            case .unavailable:
                unavailableProduct
            case .unverified where store.hasLifetimeAccess:
                status(
                    "Recent purchase could not be verified",
                    symbol: "questionmark.circle",
                    detail: "Your existing verified purchase remains active. Use Restore Purchases to check the recent purchase."
                )
            case .purchased, .restored, .pending, .revoked, .unverified, .unconfigured, .busy:
                EmptyView()
            }
        }
    }

    private func status(_ title: LocalizedStringKey, symbol: String,
                        detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var isPerformingAction: Bool {
        requestedAction != nil || store.isBusy
    }

    private var isLoading: Bool {
        store.productState == .loading || store.entitlement == .checking
    }

    private var purchaseIsPending: Bool {
        !store.hasLifetimeAccess && store.isPurchasePending
    }

    private var needsRetry: Bool {
        guard store.isConfigured else { return false }
        if purchaseIsPending { return true }
        switch store.productState {
        case .unavailable, .failed: return true
        default: break
        }
        switch store.entitlement {
        case .unverified, .revoked: return true
        default: break
        }
        switch store.lastOutcome {
        case .pending, .unverified, .revoked, .unavailable, .failed: return true
        default: return false
        }
    }

    private func perform(_ action: Action) {
        guard store.isConfigured, !isPerformingAction else { return }
        switch action {
        case .purchase:
            guard store.canPurchase, !purchaseIsPending else { return }
        case .restore:
            guard store.entitlement != .checking else { return }
        case .refresh:
            guard !isLoading else { return }
        }

        // Reserve the action before scheduling it, including rapid repeated taps.
        requestedAction = action
        Task { @MainActor in
            defer { requestedAction = nil }
            switch action {
            case .purchase:
                await store.purchase()
            case .restore:
                await store.restorePurchases()
            case .refresh:
                store.clearOutcome()
                await store.refresh()
            }
        }
    }
}
