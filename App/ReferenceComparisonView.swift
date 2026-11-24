import LightingCore
import PhotosUI
import SwiftUI
import UIKit

/// An explicitly ephemeral comparison. Closing it discards the app's image derivative;
/// the original in Photos and the saved lighting project remain unchanged.
struct ReferenceComparisonView: View {
    let scene: LightingScene
    let onApply: (LightingScene) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: PhotosPickerItem?
    @State private var requestID = UUID()
    @State private var reference: UIImage?
    @State private var tones: ReferenceTonalSummary?
    @State private var loading = false
    @State private var failure: String?
    @State private var sizeDescription = ""
    @State private var importTask: Task<Void, Never>?
    @State private var observations = ReferenceObservations()
    @State private var candidates: [GuidedRig] = []
    @State private var previewID: String?
    @State private var rigError: String?
    @State private var confirmApply = false

    private var selectedRig: GuidedRig? { candidates.first { $0.id == previewID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Compare the light").font(.title2.weight(.semibold))
                        Text("Inspect direction, contrast, softness and color. The study is a neutral sphere, not a reconstruction of the photographed person.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                            Label(reference == nil ? "Choose photo" : "Replace photo", systemImage: "photo.on.rectangle")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("chooseReference")
                        if reference != nil || loading {
                            Button(role: loading ? nil : .destructive) {
                                if loading { cancelImport() }
                                else { clear() }
                            } label: {
                                Label(loading ? (reference == nil ? "Cancel import" : "Cancel replacement") : "Remove",
                                      systemImage: loading ? "xmark" : "trash")
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("removeReference")
                        }
                    }
                    if loading {
                        ProgressView("Preparing photo…").accessibilityIdentifier("referenceLoading")
                    }
                    if let failure {
                        Label(failure, systemImage: "exclamationmark.triangle")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .accessibilityIdentifier("referenceError")
                    }
                    ViewThatFits(in: .horizontal) {
                        if !dynamicType.isAccessibilitySize {
                            HStack(alignment: .top, spacing: 12) {
                                photoPanel.frame(minWidth: 285)
                                studyPanel.frame(minWidth: 285)
                            }
                        }
                        VStack(alignment: .leading, spacing: 12) { photoPanel; studyPanel }
                    }
                    if let tones { tonalPanel(tones) }
                    guidedPanel
                    VStack(alignment: .leading, spacing: 7) {
                        Label("On-device comparison", systemImage: "lock.shield").font(.headline)
                        Text("Key & Fill keeps a reduced copy without the original photo metadata in memory only. Closing this view or removing the photo discards that copy. It is not included in saved projects or PDF exports. Photos may retrieve an iCloud original through the system picker. Your original is never modified.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("The reference is displayed as SDR sRGB, without exposure matching. No exact rig, intensity, or white balance can be inferred from this view alone.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding(16).frame(maxWidth: 900).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { clear(); dismiss() }.accessibilityIdentifier("closeReference")
                }
            }
            .alert("Replace the current lights?", isPresented: $confirmApply) {
                Button("Apply rig") {
                    guard let rig = selectedRig else { return }
                    onApply(rig.scene)
                    clear()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The studio camera and subject stay unchanged. Undo restores your previous lights. Save separately to persist the edit.")
            }
            .onChange(of: observations) { _, _ in
                candidates = []; previewID = nil; rigError = nil
            }
            .onDisappear { clear() }
            .onChange(of: selection) { _, item in
                guard let item else { return }
                let token = UUID()
                requestID = token
                loading = true
                failure = nil
                // Reset the picker so selecting the same asset again remains possible.
                selection = nil
                load(item, token: token)
            }
        }
    }

    private var photoPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REFERENCE PHOTO").font(.caption.weight(.semibold)).tracking(1.2)
            ZStack {
                Color.black
                if reference != nil && scenePhase != .active {
                    Label("Photo hidden while inactive", systemImage: "lock.fill")
                        .font(.caption).foregroundStyle(.white)
                } else if let reference {
                    Image(uiImage: reference).resizable().scaledToFit()
                        .accessibilityLabel("Imported reference photograph")
                        .accessibilityIdentifier("importedReference").privacySensitive()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo").font(.title)
                        Text("No reference selected").font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.8)).padding(12)
                    .accessibilityIdentifier("emptyReference")
                }
            }
            .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 12))
            Text(reference == nil ? "Choose a still image you are authorized to use." : sizeDescription)
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var studyPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedRig == nil ? "CURRENT LIGHT STUDY" : "CANDIDATE LIGHT STUDY").font(.caption.weight(.semibold)).tracking(1.2)
            ReferenceStudyPreview(scene: selectedRig?.scene ?? scene).frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Direct light only · uncalibrated relative preview")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func tonalPanel(_ tones: ReferenceTonalSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference tones").font(.headline)
            Text("Whole-image luminance in equivalent SDR gray, not a light meter.")
                .font(.footnote).foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("10th percentile")
                    Text(tones.lowGray, format: .percent.precision(.fractionLength(0)))
                }
                GridRow {
                    Text("Median")
                    Text(tones.medianGray, format: .percent.precision(.fractionLength(0)))
                }
                GridRow {
                    Text("90th percentile")
                    Text(tones.highGray, format: .percent.precision(.fractionLength(0)))
                }
                GridRow {
                    Text("Deep shadows (≤10% gray)")
                    Text(tones.deepShadowFraction, format: .percent.precision(.fractionLength(0)))
                }
                GridRow {
                    Text("Bright highlights (≥95% gray)")
                    Text(tones.brightHighlightFraction, format: .percent.precision(.fractionLength(0)))
                }
            }
            .font(.subheadline.monospacedDigit())
            Text("Approximate distribution from \(tones.sampleCount) opaque thumbnail samples, including background. It does not identify the subject, recover exposure, detect sensor clipping or choose the key direction.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("referenceTones")
    }

    private var guidedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build alternatives").font(.headline)
            Text("Choose what you can actually see. These are manually guided starting rigs, not automatic image analysis. Unknown values stay assumptions.")
                .font(.subheadline).foregroundStyle(.secondary)
            Picker("Key side", selection: $observations.direction) {
                ForEach(ReferenceObservations.Direction.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceKeySide")
            Picker("Shadow edges", selection: $observations.softness) {
                ForEach(ReferenceObservations.Softness.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceSoftness")
            Picker("Shadow fill", selection: $observations.fill) {
                ForEach(ReferenceObservations.Fill.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceFill")
            Picker("Rim highlight", selection: $observations.rim) {
                ForEach(ReferenceObservations.Rim.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceRim")
            Button("Build two starting rigs", systemImage: "lightbulb.2") {
                do {
                    candidates = try GuidedLighting.candidates(from: observations, in: scene)
                    previewID = candidates.first?.id
                    rigError = nil
                } catch {
                    candidates = []; previewID = nil
                    rigError = (error as? GuidedRigError) == .insufficientDirection
                        ? "Choose a visible key direction, or continue with manual editing."
                        : "The current camera or subject geometry cannot support these starting rigs. Adjust it in the studio."
                }
            }
            .buttonStyle(.borderedProminent).frame(minHeight: 44)
            .accessibilityIdentifier("buildReferenceRigs")
            if let rigError {
                Text(rigError).font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("guidedRigError")
            }
            ForEach(candidates) { rig in
                Button {
                    previewID = rig.id
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: previewID == rig.id ? "largecircle.fill.circle" : "circle")
                        VStack(alignment: .leading, spacing: 5) {
                            Text(rig.title).font(.subheadline.weight(.semibold))
                            Text(rig.explanation).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(previewID == rig.id ? .isSelected : [])
                .accessibilityIdentifier("guidedRig-\(rig.id)")
            }
            if !candidates.isEmpty {
                if let selectedRig { rigBasis(selectedRig.basis) }
                Button("Preview current setup") { previewID = nil }.frame(minHeight: 44)
                    .disabled(previewID == nil)
                Button("Apply selected rig") { confirmApply = true }
                    .buttonStyle(.borderedProminent).frame(minHeight: 44)
                    .disabled(selectedRig == nil)
                    .accessibilityIdentifier("applyReferenceRig")
                Text("Apply changes only the editable lighting arrangement. It does not save the project or retain the reference image.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func rigBasis(_ basis: GuidedRigBasis) -> some View {
        let observed = GuidedRigBasis.Cue.allCases.filter { basis.provenance(for: $0) == .userObservation }
        let observedText = observed.map { cue in
            let value: String
            switch cue {
            case .direction: value = basis.observations.direction.rawValue
            case .softness: value = basis.observations.softness.rawValue
            case .fill: value = basis.observations.fill.rawValue
            case .rim: value = basis.observations.rim.rawValue
            }
            return "\(cue.rawValue): \(value)"
        }.joined(separator: "; ")
        let unknownText = basis.unobservedCues.map(\.rawValue).joined(separator: ", ")
        let distance = StudioNumericInput.formattedValue(basis.keyDistanceMeters)
        let azimuth = StudioNumericInput.formattedValue(basis.keyAzimuthDegrees)
        let elevation = StudioNumericInput.formattedValue(basis.keyElevationDegrees)
        let lux = StudioNumericInput.formattedValue(basis.keyIlluminanceLux)
        let kelvin = StudioNumericInput.formattedValue(basis.lightKelvin)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Basis for this rig").font(.subheadline.weight(.semibold))
            Text("Your observations — \(observedText)")
                .accessibilityIdentifier("guidedObservedCues")
            Text(unknownText.isEmpty ? "No unknown cues. Exact geometry and output are still assumptions."
                 : "Assumed cues — \(unknownText)")
                .accessibilityIdentifier("guidedAssumedCues")
            Text("Chosen starting values — \(distance) m key distance · \(azimuth)° side · \(elevation)° elevation · \(lux) lx key · \(kelvin) K")
                .monospacedDigit()
                .accessibilityIdentifier("guidedStartingValues")
            Text("Angles are camera-relative. Exact geometry, power and color remain starting assumptions for every rig.")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    @MainActor private func load(_ item: PhotosPickerItem, token: UUID) {
        importTask?.cancel()
        importTask = Task {
            defer {
                if requestID == token { importTask = nil }
            }
            do {
                let transferred = try await item.loadTransferable(type: ReferencePhoto.self)
                // A provider may finish after cancellation. Reject its result
                // before constructing an obsolete image on the main actor.
                guard !Task.isCancelled, requestID == token else { return }
                guard let photo = transferred, let image = UIImage(data: photo.png) else {
                    throw ReferenceImportError.unreadable
                }
                guard !Task.isCancelled, requestID == token else { return }
                reference = image
                tones = photo.tones
                observations = .init(); candidates = []; previewID = nil; rigError = nil
                sizeDescription = "\(photo.width) × \(photo.height) px · session only"
                loading = false
            } catch {
                guard !Task.isCancelled, requestID == token else { return }
                let detail = (error as? ReferenceImportError)?.errorDescription ??
                    "The photo is unavailable. Check Photos or choose another local image."
                failure = reference == nil ? detail : "Replacement failed. Your previous photo is still open. \(detail)"
                loading = false
            }
        }
    }

    /// Cancelling a replacement retains the previous photo and guided work.
    /// Only explicit Remove, closing, or applying the rig discards that session.
    @MainActor private func cancelImport() {
        requestID = UUID()
        importTask?.cancel()
        importTask = nil
        selection = nil
        failure = nil
        loading = false
    }

    @MainActor private func clear() {
        cancelImport()
        reference = nil
        tones = nil
        observations = .init(); candidates = []; previewID = nil; rigError = nil
        sizeDescription = ""
    }
}
