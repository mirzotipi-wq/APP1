import LightingCore
import SwiftUI

struct StudioSettingsView: View {
    @ObservedObject var store: EntitlementStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StudioPreferences.unitsKey, store: StudioPreferences.defaults)
    private var unitsRaw = PlanUnits.metric.rawValue
    @AppStorage(StudioPreferences.appearanceKey, store: StudioPreferences.defaults)
    private var appearance = "system"
    @State private var showPurchase = false
    @State private var showBetaFeedback = false
    private let sourceRevision = BetaFeedbackReport.validatedSourceRevision(
        Bundle.main.object(forInfoDictionaryKey: "KEYFILL_SOURCE_REVISION") as? String
    )

    var body: some View {
        NavigationStack {
            Form {
                Section("Workspace") {
                    Picker("Distance units", selection: unitsSelection) {
                        Text("Meters").tag(PlanUnits.metric.rawValue)
                        Text("Feet").tag(PlanUnits.imperial.rawValue)
                    }
                    .accessibilityIdentifier("distanceUnits")
                    .accessibilityValue(Text(StudioPreferences.units(from: unitsRaw) == .metric ? "Meters" : "Feet"))
                    Text("The setup keeps its exact metric coordinates. Display units change how distances are read and entered.")
                        .font(.footnote).foregroundStyle(StudioPalette.secondaryText)
                    Picker("Appearance", selection: appearanceSelection) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }.accessibilityIdentifier("appearancePreference")
                }
                Section("Purchases") {
                    Button {
                        showPurchase = true
                    } label: {
                        Label(store.hasLifetimeAccess ? "Lifetime purchase" : "Purchase options",
                              systemImage: store.hasLifetimeAccess ? "checkmark.seal" : "bag")
                    }
                    .accessibilityIdentifier("openPurchaseOptions")
                }
                Section("Your photographs") {
                    Label("On-device analysis", systemImage: "lock.shield")
                    Text("Reference and test photographs use reduced copies with original metadata removed. These copies are kept in memory for the open comparison views and are excluded from saved projects and exports. Your originals in Photos are never modified.")
                    Text("Photo selection can retrieve an iCloud original through Apple's picker. Key & Fill does not upload photographs to an inference service. AR camera frames and room tracking maps are not saved.")
                }
                Section("Your projects") {
                    Text("Lighting scenes and committed room measurements are stored on this device. Use Projects to rename, duplicate, archive or delete an archived project. Export an editable copy to keep a separate backup.")
                    Text("Sharing creates a copy for the destination you choose. Shared copies are managed separately from your local project. Reference photographs and undo history are excluded.")
                }
                Section("About") {
                    LabeledContent("Version", value: version)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source revision")
                        Text(sourceRevision ?? "Unavailable")
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("buildSourceRevision")
                    }
                    Text("Lighting previews and reference suggestions are planning aids. Confirm the result using your equipment, a light meter and test photographs.")
                    Button {
                        showBetaFeedback = true
                    } label: {
                        Label("Beta feedback", systemImage: "text.bubble")
                    }
                    .accessibilityIdentifier("openBetaFeedback")
                    .accessibilityHint("Create and review a local feedback report, then choose whether and where to share it.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPurchase) { ProFeaturesView(store: store) }
            .sheet(isPresented: $showBetaFeedback) { BetaFeedbackView() }
        }
        .tint(StudioPalette.action)
    }

    private var unitsSelection: Binding<String> {
        Binding(
            get: { StudioPreferences.units(from: unitsRaw).rawValue },
            set: { unitsRaw = $0 }
        )
    }

    private var appearanceSelection: Binding<String> {
        Binding(
            get: { appearance == "light" || appearance == "dark" ? appearance : "system" },
            set: { appearance = $0 }
        )
    }

    private var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }
}
