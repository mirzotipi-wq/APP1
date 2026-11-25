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
                            .font(.subheadline).foregroundStyle(StudioPalette.secondaryText)
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
                                    .foregroundStyle(StudioPalette.secondaryText)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(topic.title).font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(topic.summary).font(.subheadline)
                                        .foregroundStyle(StudioPalette.secondaryText)
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
        .tint(StudioPalette.action)
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
                 "Keep subject and camera placement applies the recipe's lights around your current subject, facing your camera, and keeps camera settings and measured room. Turn it off to use the recipe's subject, camera and lights and reset room and preview settings. Undo restores the previous setup. Tap Save before exploring if you want a saved version to return to.")
            step("Shape the portrait",
                 "Begin with the Key light's side, height and intensity. Balance Fill to control shadow depth, then use Rim for separation. Adjust the starting layout for your subject and real equipment.")
        case .editing:
            step("Select a light",
                 "Tap a light in Plan or in the Lights list. Its inspector appears below. Use the + beside Scene or Add light in the list to extend the setup.")
            step("Place it precisely",
                 "Drag the selected light's marker in Plan or adjust Horizontal, Depth and Height. Choose meters or feet in Studio tools > Settings. Tap a value with the pencil, type an exact number, then choose Apply value. Cancel leaves the value unchanged. Intensity is in candela (cd), and Temperature is in kelvin (K).")
            step("Choose the emitting surface",
                 "In Emitter, choose Bare point, Directional or Rectangular softbox. The softbox Width and Height describe its emitting face; Roll turns that face around its aim. For aimed emitters, keep Aim at subject on or turn it off to set Aim X, Aim Y and Aim Z.")
            step("Manage and arrange",
                 "Use Light actions to rename or duplicate a light. Set ideal lux adjusts that light's contribution on the ideal camera-facing plane at the subject; other lights stay unchanged. Studio tools also opens Subject position and Arrange setup, where you can move the entire setup or rotate and mirror its lights. Each applied arrangement can be undone.")
            step("Compare edits",
                 "Undo and Redo at the bottom let you compare changes. Save keeps the current setup locally; edit history belongs to the current editing session.")
        case .previews:
            step("Layout and framing",
                 "Plan shows the overhead layout. Read its caption for the current grid spacing. In 3D, drag to orbit, pinch to zoom, pan with two fingers and tap a light to select it. Fit setup frames the whole rig. Camera previews the setup from your camera position, using the chosen focal length and aiming at the subject.")
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
                 "A suitable single-face photo may offer an on-device suggestion for the brighter side. Tap Use suggested side to accept it only if it matches what you see; it does not set Key side automatically. Choose Key side, Shadow edges, Shadow fill and Rim highlight, then tap Build starting rigs. Leave uncertain cues unknown. A visible key direction is needed to build alternatives.")
            step("Compare with your result",
                 "Tap Compare a test shot to import a test photograph beside the reference. Compare them side by side or move the wipe divider. The photos are fitted without automatic alignment or exposure matching. Closing the comparison clears its copies and returns to Reference, where your original reference and lighting choices remain until you close that view.")
            step("Compare assumptions",
                 "Compare the one or two available starting rigs. Some subject positions allow only one arrangement within the supported scene. Read Basis for this rig to distinguish your observations, an accepted on-device key-side suggestion, assumed cues and chosen starting values. Preview current setup returns to your existing light study. Exact geometry, intensity and color remain starting assumptions.")
            step("Keep an alternative",
                 "Choose Apply selected rig and confirm Apply rig. Only the lights change; the studio camera and subject stay in place. Undo restores the previous lights. Save separately to keep the edit.")
        case .room:
            step("Measure, then enter",
                 "Open Room placement after shaping the rig. Measure Width and Depth and the subject's distances From left wall and From near wall. Add Ceiling height (optional) for ceiling checks; leave it blank and press Set for unmeasured. Floor checks remain available without it. Press Set after each changed entry so it becomes part of the current measured layout.")
            step("Turn and place the rig",
                 "Adjust Rig rotation or use Rotate 180°. Read each camera and light center's wall distances and height. Rectangular emitting-face projections flag wall crossings. Manual room placement uses the dimensions you enter.")
            step("Place at full scale in AR",
                 "On a supported device, open Studio tools > Place in AR and tap Start AR camera. Move slowly until the app finds a horizontal surface, then place the subject on the floor. Check scale and alignment against your measurements. Recheck after tracking warnings, or use Reset and scan again. Use manual room measurements stops the camera. When you return, tap Start AR camera to scan and place the setup again.")
            step("Check the real equipment",
                 "Wall, floor and measured ceiling checks cover centers and ideal rectangular emitting faces. Check the full fixture, stands, booms, cables and working clearance physically.")
            step("Take the notes with you",
                 "Use Review and share notes, then Share measurement notes. Notes include applied entries, so press Set first. If the displayed values already match your room, choose Keep room with setup. Remove room from setup asks for confirmation and keeps your planning fields. Save in the studio keeps the measurements or their removal with the project. Undo in the studio restores the setup from before this room editing session as one edit.")
        case .saving:
            step("Keep a local project",
                 "Tap Save and wait for Saved locally. Projects lets you open, rename, duplicate and archive saved setups. Save your current edits before opening or changing another project.")
            step("Share a readable plan",
                 "Open Export lighting plan beside Projects, then Lighting plan (PDF). Choose Paper and Units, review the preview, then Share PDF. The PDF communicates the diagram, equipment, scene settings and committed room placement when present. Use an editable copy when you want to reopen a setup.")
            step("Keep an editable copy",
                 "Choose Editable project copy, then Save editable copy to write a file you can reopen. In Projects, Import editable project creates a separate project from that file and keeps existing projects.")
            step("Know what is included",
                 "Exports capture the setup when you opened Export lighting plan, including unsaved edits. Exporting does not save to Projects. Photos and edit history are excluded. Editable copies and PDFs include committed room measurements. Room measurement notes provide a separate text report.")
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
