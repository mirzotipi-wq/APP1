import SwiftUI

/// Contextual help owns only its navigation. It has no access to the editor,
/// project store, reference image or room measurements.
struct StudioGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan a portrait, step by step")
                            .font(.title3.weight(.semibold))
                            .accessibilityIdentifier("studioGuideOverview")
                        Text("Follow the workflow or open the topic you need. Your current studio stays open while you read.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 4)
                }
                Section("Workflow") {
                    ForEach(StudioGuideTopic.allCases) { topic in
                        NavigationLink {
                            page(topic)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(topic.rawValue)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(topic.title).font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(topic.summary).font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(minHeight: 44, alignment: .leading)
                        }
                        .accessibilityLabel(Text(topic.title))
                        .accessibilityHint(Text(topic.summary))
                        .accessibilityIdentifier("studioGuideTopic-\(topic.rawValue)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Studio guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { closeButton }
            }
        }
    }

    private var closeButton: some View {
        Button("Done") { dismiss() }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("closeStudioGuide")
    }

    private func page(_ topic: StudioGuideTopic) -> some View {
        List { sections(for: topic) }
            .listStyle(.insetGrouped)
            .navigationTitle(topic.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Capture the sheet's dismiss action, including on pushed pages.
                ToolbarItem(placement: .confirmationAction) { closeButton }
            }
    }

    @ViewBuilder
    private func sections(for topic: StudioGuideTopic) -> some View {
        switch topic {
        case .recipe:
            step("Open a starting rig",
                 "Tap Recipes at the top of the studio. Three-point portrait gives you Key, Fill and Rim lights. Rembrandt, Butterfly and Silhouette offer other starting arrangements.")
            step("Keep what you want",
                 "Choosing a recipe replaces the current setup. Undo restores the previous setup. Tap Save before exploring if you want a saved version to return to.")
            step("Shape the portrait",
                 "Begin with the Key light's side, height and intensity. Balance Fill to control shadow depth, then use Rim for separation. Adjust the starting layout for your subject and real equipment.")
        case .editing:
            step("Select a light",
                 "Tap a light in Plan or in the Lights list. Its inspector appears below. Use the + beside Scene or Add light in the list to extend the setup.")
            step("Place it precisely",
                 "Adjust Horizontal, Depth and Height in meters. Tap a value with the pencil, type an exact number, then choose Apply value. Cancel leaves the value unchanged. Intensity is in candela (cd), and Temperature is in kelvin (K).")
            step("Choose the emitting surface",
                 "In Emitter, choose Bare point, Directional or Rectangular softbox. The softbox Width and Height describe its emitting face. For aimed emitters, keep Aim at subject on or turn it off to set Aim X, Aim Y and Aim Z.")
            step("Compare edits",
                 "Undo and Redo at the bottom let you compare changes. Save keeps the current setup locally; edit history belongs to the current editing session.")
        case .previews:
            step("Layout and framing",
                 "Plan shows the overhead layout on a 1 m grid. In 3D, drag to orbit and use Fit setup to frame the whole rig. Camera previews the setup from your camera position, using the chosen focal length and aiming at the subject.")
            step("Light and shadow",
                 "Switch to Study and choose Sphere for a simple light check or Bust for a neutral mannequin. Use the camera controls below to change framing. Study shows direct light, shadows and relative color.")
            step("Read the meter",
                 "Meter compares light on an ideal camera-facing plane at the subject. White balance and Relative exposure change the neutral-card and Study display. A rim light may read zero on that plane while lighting the back of the subject.")
            step("Check with a test photograph",
                 "3D shading is illustrative. Study and Meter are diagnostic models, not calibrated skin, camera exposure or a reconstruction of a person. Confirm the result with your real lights and a test photograph.")
        case .reference:
            step("Bring a visual target",
                 "Open Reference photo, then Choose photo. Compare direction, shadow edges and fill against the neutral study. The app's photo copy is kept only while this view is open; your original remains unchanged.")
            step("Describe what you see",
                 "Choose Key side, Shadow edges, Shadow fill and Rim highlight, then tap Build two starting rigs. This is manually guided: leave uncertain cues unknown. A visible key direction is needed to build alternatives.")
            step("Compare assumptions",
                 "Try Closer starting rig and Farther starting rig. Read Basis for this rig to separate Your observations, Assumed cues and Chosen starting values. Preview current setup returns to your existing light study. Exact geometry, intensity and color remain starting assumptions.")
            step("Keep an alternative",
                 "Choose Apply selected rig and confirm Apply rig. Only the lights change; the studio camera and subject stay in place. Undo restores the previous lights. Save separately to keep the edit.")
        case .room:
            step("Measure, then enter",
                 "Open Room placement after shaping the rig. Measure Width and Depth and the subject's distances From left wall and From near wall. Press Set after each changed entry so it becomes part of the current measured layout.")
            step("Turn and place the rig",
                 "Adjust Rig rotation or use Rotate 180°. Read each camera and light center's wall distances and height. Rectangular emitting-face projections flag wall crossings. This is manual placement using your measurements; the app does not scan or track the room.")
            step("Check the real equipment",
                 "Check the fixture, stands, booms, cables and ceiling clearance physically. The diagram covers centers and rectangular emitting faces, rather than the full equipment.")
            step("Take the notes with you",
                 "Use Review and share notes, then Share measurement notes. Notes include committed entries, so press Set first. Room measurements are session-only and are not part of the saved project or lighting PDF.")
        case .saving:
            step("Keep a local project",
                 "Tap Save and wait for Saved locally. Projects lets you open, rename, duplicate and archive saved setups. Save your current edits before opening or changing another project.")
            step("Share a readable plan",
                 "Open Export lighting plan beside Projects, then Lighting plan (PDF). Choose Paper and Units, review the preview, then Share PDF. The PDF communicates the diagram, equipment and scene settings; use an editable copy when you want to reopen a setup.")
            step("Keep an editable copy",
                 "Choose Editable project copy, then Save editable copy to write a file you can reopen. In Projects, Import editable project creates a separate project from that file and keeps existing projects.")
            step("Know what is included",
                 "Exports capture the setup when you opened Export lighting plan, including unsaved edits. Exporting does not save to Projects. Photos and room measurements are not included in the PDF or editable copy. Editable copies also omit edit history; share room notes separately.")
        }
    }

    private func step(_ title: LocalizedStringKey, _ explanation: LocalizedStringKey) -> some View {
        Section {
            Text(explanation)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        } header: {
            Text(title).textCase(nil)
        }
    }
}

private enum StudioGuideTopic: Int, CaseIterable, Identifiable {
    case recipe = 1
    case editing, previews, reference, room, saving

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .recipe: return "Start with a recipe"
        case .editing: return "Edit the lighting"
        case .previews: return "Read the previews"
        case .reference: return "Explore a reference"
        case .room: return "Measure the room"
        case .saving: return "Save and share"
        }
    }

    var summary: LocalizedStringKey {
        switch self {
        case .recipe: return "Choose a portrait starting point."
        case .editing: return "Position, output, color and emitters."
        case .previews: return "Plan, 3D, Camera, Study and Meter."
        case .reference: return "Build alternatives from your observations."
        case .room: return "Place equipment with measured distances."
        case .saving: return "Local projects, PDF plans and editable copies."
        }
    }
}
