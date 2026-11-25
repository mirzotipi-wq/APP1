import SwiftUI

@main
struct AccessibilityControlApp: App {
    var body: some Scene {
        WindowGroup {
            AccessibilityControlScreen()
        }
    }
}

private struct AccessibilityControlScreen: View {
    @State private var confirmed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Accessibility audit control")
                .font(.headline)
                .accessibilityIdentifier("control.title")
            Text(confirmed ? "Confirmed" : "Ready for audit")
                .accessibilityIdentifier("control.status")
            Button("Confirm control") {
                confirmed = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(uiColor: .label))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .controlSize(.large)
            .accessibilityIdentifier("control.confirm")
        }
        .padding(24)
    }
}

