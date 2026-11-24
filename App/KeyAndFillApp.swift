import SwiftUI

@main
@MainActor
struct KeyAndFillApp: App {
    @StateObject private var entitlements = EntitlementStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StudioPreferences.appearanceKey, store: StudioPreferences.defaults)
    private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            StudioView()
                .environmentObject(entitlements)
                .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await entitlements.refresh() } }
                }
        }
    }
}
