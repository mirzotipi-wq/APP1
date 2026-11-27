import SwiftUI

/// The studio presents this only after a successful load with no saved library.
/// It owns no scene or storage actions: opening guidance never replaces a rig,
/// and a failed save leaves this card available until the user dismisses it.
@MainActor
struct StudioWelcomeView: View {
    let onSaveCurrent: () -> Void
    let onOpenGuide: () -> Void
    let onOpenProjects: () -> Void

    @AppStorage(StudioPreferences.welcomeDismissedKey, store: StudioPreferences.defaults)
    private var isDismissed = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !isDismissed {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Text("Start your first portrait")
                        .font(.title3.weight(.semibold))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .studioTextLayoutProbe("studioWelcomeTitle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("studioWelcomeTitle")
                        .studioTextLayoutValue("studioWelcomeTitle")
                    Button {
                        // No animation, including when Reduce Motion is enabled.
                        isDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .accessibilityLabel("Dismiss welcome")
                    .accessibilityHint("Hides this card. The Studio guide remains available above.")
                    .accessibilityIdentifier("dismissStudioWelcome")
                }

                Text("For a three-light portrait, shape Key, balance Fill and use Rim for separation. Edit in Plan, compare in Study, then save the setup you want to keep.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onSaveCurrent) {
                    Label("Save current setup", systemImage: "square.and.arrow.down")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(StudioPalette.prominentActionText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Saves your current setup locally, including any edits you have made.")
                .accessibilityIdentifier("welcomeSaveCurrent")

                StudioAdaptiveLayout(forceVertical: dynamicTypeSize.isAccessibilitySize) {
                    Button(action: onOpenGuide) {
                        actionLabel("Studio guide", systemImage: "questionmark.circle")
                    }
                    .accessibilityHint("Read the workflow while keeping your current setup open.")
                    .accessibilityIdentifier("welcomeOpenGuide")
                    Button(action: onOpenProjects) {
                        actionLabel("Projects", systemImage: "folder")
                    }
                    .accessibilityHint("Open your project library.")
                    .accessibilityIdentifier("welcomeOpenProjects")
                }
                .buttonStyle(.bordered)

                Text("Next, explore Reference photo for plausible alternatives, use Room placement or AR, and export a lighting plan.")
                    .font(.subheadline)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Imported photo copies stay in memory for open views; saved projects and exports exclude them. Previews and suggestions are not calibrated measurements. Check real lighting with a meter and test photos.")
                    .font(.footnote)
                    .foregroundStyle(StudioPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("studioWelcomeLimitations")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 20))
            .tint(StudioPalette.action)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("studioWelcome")
        }
    }

    private func actionLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
}
