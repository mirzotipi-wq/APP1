import SwiftUI

@main
@MainActor
struct KeyAndFillApp: App {
    @StateObject private var entitlements = EntitlementStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StudioPreferences.appearanceKey, store: StudioPreferences.defaults)
    private var appearance = "system"
    @State private var hasActivated = false
    @State private var isRefreshingEntitlements = false

    var body: some Scene {
        WindowGroup {
            StudioView()
                .environmentObject(entitlements)
                .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            // The shared store refreshes at initialization. Observe subsequent
            // app activations once, regardless of the number of open windows.
            defer { hasActivated = true }
            guard hasActivated, entitlements.isConfigured, !isRefreshingEntitlements else { return }
            isRefreshingEntitlements = true
            Task { @MainActor in
                defer { isRefreshingEntitlements = false }
                await entitlements.refresh()
            }
        }
    }
}
