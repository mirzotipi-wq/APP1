import LightingCore
import PhotosUI
import SwiftUI
import UIKit

/// An explicitly ephemeral comparison. Closing it discards the app's image derivative;
/// the original in Photos and the saved lighting project remain unchanged.
struct ReferenceComparisonView: View {
    let scene: LightingScene
    /// The session must admit the proposal before this view consumes its photo
    /// and draft. A stale or busy workspace may reject an otherwise valid rig.
    let onApply: (LightingScene) -> Bool
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
    @State private var analysisRequestID = UUID()
    @State private var analysisTask: Task<Void, Never>?
    @State private var analysis: ReferenceAnalysisResult?
    @State private var analyzing = false
    @State private var analysisFailure: String?
    @State private var acceptedAnalysisDirection: ReferenceObservations.Direction?
    @State private var observations = ReferenceObservations()
    @State private var candidates: [GuidedRig] = []
    @State private var previewID: String?
    @State private var rigError: String?
    @State private var applyFailure: String?
    @State private var confirmApply = false
    @State private var showPhotoComparison = false
    @State private var sessionClosed = false
    @State private var isApplying = false

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
                    let importLayout = dynamicType.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                        : AnyLayout(HStackLayout(spacing: 12))
                    importLayout {
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
                    Button("Compare a test shot", systemImage: "rectangle.on.rectangle") {
                        showPhotoComparison = true
                    }
                    .buttonStyle(.bordered).frame(minHeight: 44)
                    .accessibilityIdentifier("openPhotoComparison")
                    if scenePhase == .active {
                        if let tones { tonalPanel(tones) }
                        if reference != nil { analysisPanel }
                    }
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
                    Button("Done") { closeSession(); dismiss() }.accessibilityIdentifier("closeReference")
                }
            }
            .alert("Replace the current lights?", isPresented: $confirmApply) {
                Button("Apply rig") {
                    guard !sessionClosed, !isApplying, let rig = selectedRig else { return }
                    confirmApply = false
                    isApplying = true
                    guard onApply(rig.scene) else {
                        isApplying = false
                        applyFailure = "The rig could not be applied. Your reference photo and selected rig are still open."
                        return
                    }
                    // Admission and cleanup run synchronously on the UI actor.
                    // Only an accepted edit consumes this session's photo/draft.
                    closeSession()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The studio camera and subject stay unchanged. Undo restores your previous lights. Save separately to persist the edit.")
            }
            .sheet(isPresented: $showPhotoComparison) {
                PhotoComparisonView(initialReference: reference)
            }
            .onChange(of: observations) { _, _ in
                candidates = []; previewID = nil; rigError = nil
                applyFailure = nil
                confirmApply = false
            }
            .onChange(of: previewID) { _, _ in applyFailure = nil }
            .onChange(of: selection) { _, item in
                guard !sessionClosed, let item else { return }
                let token = UUID()
                requestID = token
                loading = true
                failure = nil
                // Reset the picker so selecting the same asset again remains possible.
                selection = nil
                load(item, token: token)
            }
        }
        .background {
            ComparisonSessionDismissalObserver(onDismiss: closeSession)
                .allowsHitTesting(false)
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
                    GeometryReader { geometry in
                        ZStack(alignment: .topLeading) {
                            Image(uiImage: reference).resizable().scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .accessibilityLabel("Imported reference photograph")
                                .accessibilityIdentifier("importedReference").privacySensitive()
                            if let bounds = analysis?.faceBounds {
                                let rect = faceRect(bounds, imageSize: reference.size, container: geometry.size)
                                Rectangle().stroke(.black.opacity(0.8), lineWidth: 4)
                                    .overlay { Rectangle().stroke(.white, lineWidth: 2) }
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .allowsHitTesting(false).accessibilityHidden(true)
                            }
                        }
                    }
                    .privacySensitive()
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

    /// The service has already converted Vision bounds to a top-left origin.
    /// Apply only the displayed image's aspect-fit scale and letterbox offsets.
    private func faceRect(_ bounds: ReferenceFaceBounds, imageSize: CGSize, container: CGSize) -> CGRect {
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale, height = imageSize.height * scale
        return CGRect(x: (container.width - width) / 2 + CGFloat(bounds.x) * width,
                      y: (container.height - height) / 2 + CGFloat(bounds.y) * height,
                      width: CGFloat(bounds.width) * width, height: CGFloat(bounds.height) * height)
    }

    private var analysisPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On-device key-side check").font(.headline)
            if analyzing {
                ProgressView("Checking face lighting…")
                    .accessibilityIdentifier("referenceAnalysisLoading")
                Text("You can choose the lighting cues and build a starting rig while the check runs.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else if let analysis {
                Label(analysisSupportText(analysis.support), systemImage: analysis.support == .supported ? "lightbulb" : "info.circle")
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier("referenceAnalysisSupport")
                Text(analysis.explanation).font(.subheadline)
                    .accessibilityIdentifier("referenceAnalysisExplanation")
                if analysis.faceBounds != nil {
                    Text("The outline marks the detected face region.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if analysis.support == .supported, !analysis.requiresManualDirection {
                    Text("Suggested key side: \(analysis.observations.direction.rawValue)")
                        .font(.subheadline.weight(.medium))
                    Button("Use suggested side") { useSuggestedSide() }
                        .buttonStyle(.bordered).frame(minHeight: 44)
                        .accessibilityIdentifier("useReferenceSuggestedSide")
                    Text("Review the suggestion against the photo. Accepting it sets Key side; choose the other cues below.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Limitations").font(.caption.weight(.semibold))
                    ForEach(analysis.limitations, id: \.self) { limitation in
                        Text(limitation).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("referenceAnalysisLimitations")
            } else if let analysisFailure {
                Label(analysisFailure, systemImage: "info.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .accessibilityIdentifier("referenceAnalysisError")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("referenceAnalysis")
        .privacySensitive()
    }

    private func analysisSupportText(_ support: ReferenceAnalysisSupport) -> String {
        switch support {
        case .supported: return "Supported for a tentative suggestion"
        case .ambiguous: return "Ambiguous — choose the key side manually"
        case .unsupported: return "Unsupported — choose the key side manually"
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
            Text("Choose what you can see, or accept a tentative key-side suggestion after reviewing the photo. Unknown cues and all numeric rig settings stay starting assumptions.")
                .font(.subheadline).foregroundStyle(.secondary)
            Picker("Key side", selection: Binding(get: { observations.direction }, set: { direction in
                acceptedAnalysisDirection = nil
                observations.direction = direction
            })) {
                ForEach(ReferenceObservations.Direction.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceKeySide")
            if let acceptedAnalysisDirection {
                Text("Accepted on-device suggestion — Key side: \(acceptedAnalysisDirection.rawValue)")
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityIdentifier("referenceAcceptedSuggestion")
            }
            Picker("Shadow edges", selection: $observations.softness) {
                ForEach(ReferenceObservations.Softness.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceSoftness")
            Picker("Shadow fill", selection: $observations.fill) {
                ForEach(ReferenceObservations.Fill.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceFill")
            Picker("Rim highlight", selection: $observations.rim) {
                ForEach(ReferenceObservations.Rim.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("referenceRim")
            Button("Build starting rigs", systemImage: "lightbulb.2") {
                applyFailure = nil
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
            if candidates.count == 1 {
                Text("Only one starting rig is supported by the current camera and subject geometry.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("guidedRigAvailability")
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
                if let applyFailure {
                    Label(applyFailure, systemImage: "exclamationmark.triangle")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("referenceApplyError")
                }
                Button("Apply selected rig") { applyFailure = nil; confirmApply = true }
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
        let usesAnalysisDirection = acceptedAnalysisDirection == basis.observations.direction
        let observed = GuidedRigBasis.Cue.allCases.filter {
            basis.provenance(for: $0) == .userObservation && !($0 == .direction && usesAnalysisDirection)
        }
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
            Text(observedText.isEmpty ? "Your observations — none selected" : "Your observations — \(observedText)")
                .accessibilityIdentifier("guidedObservedCues")
            if usesAnalysisDirection {
                Text("Accepted on-device suggestion — Key side: \(basis.observations.direction.rawValue)")
                    .accessibilityIdentifier("guidedSuggestedCues")
            }
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
                applyFailure = nil
                confirmApply = false
                sizeDescription = "\(photo.width) × \(photo.height) px · session only"
                loading = false
                startAnalysis(png: photo.png)
            } catch is CancellationError {
                guard !Task.isCancelled, requestID == token else { return }
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

    @MainActor private func startAnalysis(png: Data) {
        cancelAnalysis()
        let token = analysisRequestID
        analyzing = true
        // Keep PNG bytes only for the service call, never in view state or a project.
        analysisTask = Task {
            defer {
                if analysisRequestID == token {
                    analysisTask = nil
                    analyzing = false
                }
            }
            do {
                let result = try await ReferenceAnalysisService.analyze(png: png)
                guard !Task.isCancelled, analysisRequestID == token else { return }
                analysis = result
            } catch {
                guard !Task.isCancelled, analysisRequestID == token else { return }
                analysisFailure = "The on-device check could not finish. Choose the key side manually."
            }
        }
    }

    @MainActor private func useSuggestedSide() {
        guard let analysis, analysis.support == .supported, !analysis.requiresManualDirection else { return }
        acceptedAnalysisDirection = analysis.observations.direction
        // Explicit adoption changes only direction; unknown/manual cues remain intact.
        observations.direction = analysis.observations.direction
    }

    /// Import cancellation is independent: a failed or cancelled replacement keeps
    /// the previous photo's result, including any check that is still running.
    @MainActor private func cancelAnalysis() {
        analysisRequestID = UUID()
        analysisTask?.cancel()
        analysisTask = nil
        analysis = nil
        analyzing = false
        analysisFailure = nil
        acceptedAnalysisDirection = nil
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
        cancelAnalysis()
        reference = nil
        tones = nil
        observations = .init(); candidates = []; previewID = nil; rigError = nil
        applyFailure = nil
        confirmApply = false
        sizeDescription = ""
    }

    @MainActor private func closeSession() {
        guard !sessionClosed else { return }
        sessionClosed = true
        confirmApply = false
        clear()
    }
}
