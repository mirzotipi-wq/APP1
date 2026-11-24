import PhotosUI
import SwiftUI
import UIKit

/// A separate, session-only comparison of two actual photographs.
/// The optional seed is the reduced, sanitized image already open in Reference.
@MainActor
struct PhotoComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicType
    @StateObject private var reference: ComparisonPhotoSlot
    @StateObject private var testShot: ComparisonPhotoSlot
    @State private var referenceSelection: PhotosPickerItem?
    @State private var testSelection: PhotosPickerItem?
    @State private var mode = ComparisonMode.sideBySide
    @State private var wipeFraction = 0.5
    @State private var sessionClosed = false

    init(initialReference: UIImage? = nil) {
        // Capture the mutable slot in StateObject's thunk, not a separate copy
        // of the image that could outlive an explicit Clear.
        let referenceSlot = ComparisonPhotoSlot(image: initialReference)
        let testSlot = ComparisonPhotoSlot()
        _reference = StateObject(wrappedValue: referenceSlot)
        _testShot = StateObject(wrappedValue: testSlot)
    }

    private var hasBothPhotos: Bool { reference.image != nil && testShot.image != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    introduction
                    ViewThatFits(in: .horizontal) {
                        if !dynamicType.isAccessibilitySize {
                            HStack(alignment: .top, spacing: 12) {
                                importControls(reference, selection: $referenceSelection, role: .reference)
                                    .frame(minWidth: 260)
                                importControls(testShot, selection: $testSelection, role: .testShot)
                                    .frame(minWidth: 260)
                            }
                        }
                        VStack(spacing: 12) {
                            importControls(reference, selection: $referenceSelection, role: .reference)
                            importControls(testShot, selection: $testSelection, role: .testShot)
                        }
                    }

                    if hasBothPhotos {
                        if dynamicType.isAccessibilitySize {
                            layoutPicker.pickerStyle(.menu)
                        } else {
                            layoutPicker.pickerStyle(.segmented)
                        }
                    }

                    if hasBothPhotos && mode == .wipe {
                        wipeComparison
                    } else {
                        sideBySideComparison
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compare direction, shadow edges, fill and color.")
                            .font(.subheadline.weight(.medium))
                        Text("Each photo keeps its aspect ratio in an equal canvas. Outlines mark image bounds; empty bands are not cropped. Photos are not automatically aligned or exposure-matched. Differences in framing, pose and processing can also change their appearance.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    privacyNote
                    if reference.image != nil || testShot.image != nil || reference.isLoading || testShot.isLoading {
                        Button(role: .destructive) { clearSession() } label: {
                            Label("Clear both photos", systemImage: "trash")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("clearComparisonPhotos")
                    }
                }
                .padding(16)
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Test-shot comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { closeSession(); dismiss() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("closePhotoComparison")
                }
            }
            .onChange(of: referenceSelection) { _, item in
                guard !sessionClosed, let item else { return }
                referenceSelection = nil
                reference.load(item)
            }
            .onChange(of: testSelection) { _, item in
                guard !sessionClosed, let item else { return }
                testSelection = nil
                testShot.load(item)
            }
        }
        .background {
            ComparisonSessionDismissalObserver(onDismiss: closeSession)
                .allowsHitTesting(false)
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reference and test shot").font(.title2.weight(.semibold))
            Text("Choose a lighting reference and a photograph from your setup, then inspect them side by side or drag the wipe.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var layoutPicker: some View {
        Picker("Comparison layout", selection: $mode) {
            ForEach(ComparisonMode.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .frame(minHeight: 44)
        .accessibilityIdentifier("photoComparisonMode")
    }

    private func importControls(_ slot: ComparisonPhotoSlot, selection: Binding<PhotosPickerItem?>,
                                role: ComparisonPhotoRole) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(role.title).font(.headline)
            PhotosPicker(selection: selection, matching: .images, preferredItemEncoding: .current) {
                Label(slot.image == nil ? "Choose \(role.pickerName)" : "Replace \(role.pickerName)",
                      systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("chooseComparison\(role.identifier)")

            if slot.isLoading {
                ProgressView(slot.image == nil ? "Preparing \(role.pickerName)…" : "Preparing replacement…")
                    .accessibilityIdentifier("comparison\(role.identifier)Loading")
                Button { slot.cancelImport() } label: {
                    Label(slot.image == nil ? "Cancel import" : "Cancel replacement", systemImage: "xmark")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("cancelComparison\(role.identifier)")
            }
            if slot.image != nil {
                Button(role: .destructive) {
                    selection.wrappedValue = nil
                    slot.clear()
                } label: {
                    Label("Remove \(role.pickerName)", systemImage: "trash")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("removeComparison\(role.identifier)")
            }
            if let failure = slot.failure {
                Label(failure, systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("comparison\(role.identifier)Error")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var sideBySideComparison: some View {
        Group {
            if dynamicType.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    photoPanel(reference, role: .reference)
                    photoPanel(testShot, role: .testShot)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    photoPanel(reference, role: .reference)
                    photoPanel(testShot, role: .testShot)
                }
            }
        }
        .accessibilityIdentifier("photoComparisonSideBySide")
    }

    private func photoPanel(_ slot: ComparisonPhotoSlot, role: ComparisonPhotoRole) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(role.title).font(.subheadline.weight(.semibold))
            GeometryReader { geometry in
                ZStack {
                    Color(white: 0.06)
                    if scenePhase != .active && slot.image != nil {
                        concealedPhoto
                    } else if let image = slot.image {
                        fittedPhoto(image, role: role, size: geometry.size)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo").font(.title2)
                            Text("No \(role.pickerName) selected").font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(.white.opacity(0.8)).padding(12)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .privacySensitive()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(scenePhase == .active ? "\(role.title) photograph" : "\(role.title) photo hidden")
            .accessibilityValue(slot.image == nil ? "No photo selected" : slot.pixelDescription)
            .accessibilityIdentifier("comparison\(role.identifier)Image")
            Text(slot.image == nil ? "Choose a still photograph." : slot.pixelDescription)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wipeComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Reference · left").font(.subheadline.weight(.semibold))
                    Spacer(minLength: 12)
                    Text("Test shot · right").font(.subheadline.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reference · left")
                    Text("Test shot · right")
                }.font(.subheadline.weight(.semibold))
            }
            GeometryReader { geometry in
                let width = geometry.size.width
                let wipeX = width * CGFloat(wipeFraction)
                ZStack(alignment: .topLeading) {
                    Color(white: 0.06)
                    if scenePhase != .active {
                        concealedPhoto.frame(width: width, height: geometry.size.height)
                    } else if let referenceImage = reference.image, let testImage = testShot.image {
                        fittedPhoto(testImage, role: .testShot, size: geometry.size)
                        // Each layer includes its own opaque canvas. Letterboxing
                        // must not reveal the other photo on the wrong wipe side.
                        ZStack {
                            Color(white: 0.06)
                            fittedPhoto(referenceImage, role: .reference, size: geometry.size)
                        }
                        .frame(width: width, height: geometry.size.height)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: wipeX)
                        }
                        Rectangle().fill(.white)
                            .frame(width: 2, height: geometry.size.height)
                            .position(x: wipeX, y: geometry.size.height / 2)
                            .allowsHitTesting(false)
                        Image(systemName: "arrow.left.and.right")
                            .font(.body.weight(.semibold)).foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.85), in: Circle())
                            .overlay { Circle().stroke(.white, lineWidth: 1) }
                            .frame(width: 44, height: geometry.size.height)
                            .contentShape(Rectangle())
                            .position(x: min(max(wipeX, 22), max(22, width - 22)), y: geometry.size.height / 2)
                            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("comparisonWipe"))
                                .onChanged { value in
                                    guard width > 0 else { return }
                                    wipeFraction = Double(min(max(value.location.x / width, 0), 1))
                                })
                            .accessibilityHidden(true)
                    }
                }
                .coordinateSpace(name: "comparisonWipe")
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .privacySensitive()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(scenePhase == .active ? "Reference and test shot wipe comparison" : "Comparison photos hidden")
            .accessibilityIdentifier("photoComparisonWipe")

            VStack(alignment: .leading, spacing: 4) {
                Text("Wipe position").font(.subheadline.weight(.medium))
                Slider(value: $wipeFraction, in: 0...1)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Wipe position")
                    .accessibilityValue("\(Int((wipeFraction * 100).rounded())) percent reference canvas visible")
                    .accessibilityHint("Increase to reveal more of the reference on the left.")
                    .accessibilityIdentifier("photoComparisonWipePosition")
                Text("Drag the divider or adjust the slider. Dashed outline: reference bounds. Solid outline: test-shot bounds.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func fittedPhoto(_ image: UIImage, role: ComparisonPhotoRole, size: CGSize) -> some View {
        let imageSize = image.size
        let scale = min(size.width / max(imageSize.width, 1), size.height / max(imageSize.height, 1))
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return Image(uiImage: image).resizable()
            .frame(width: width, height: height)
            .overlay {
                Rectangle().strokeBorder(.white.opacity(0.85), style: StrokeStyle(
                    lineWidth: 1, dash: role == .reference ? [6, 4] : []))
            }
            .position(x: size.width / 2, y: size.height / 2)
            .frame(width: size.width, height: size.height)
            .privacySensitive()
            .accessibilityHidden(true)
    }

    private var concealedPhoto: some View {
        Label("Photos hidden while inactive", systemImage: "lock.fill")
            .font(.caption).foregroundStyle(.white)
            .multilineTextAlignment(.center).padding(12)
    }

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Session only", systemImage: "lock.shield").font(.headline)
            Text("Imports use reduced SDR sRGB copies with original photo metadata removed. This comparison keeps photos in memory and clears them when you close it. Photos are not included in saved projects or PDF exports. The system picker may retrieve an iCloud original. Your originals are never modified.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func clearSession() {
        referenceSelection = nil
        testSelection = nil
        reference.clear()
        testShot.clear()
        wipeFraction = 0.5
        mode = .sideBySide
    }

    private func closeSession() {
        guard !sessionClosed else { return }
        sessionClosed = true
        clearSession()
    }
}

/// SwiftUI disappearance also occurs when a nested picker or sheet covers a
/// session. Only a completed dismissal of this controller's ancestor releases
/// the photos; a cancelled interactive swipe must retain them.
@MainActor
struct ComparisonSessionDismissalObserver: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.onDismiss = onDismiss
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.onDismiss = onDismiss
    }

    final class Controller: UIViewController {
        var onDismiss: (() -> Void)?
        private var dismissalStarted = false

        private var ancestorIsBeingDismissed: Bool {
            var ancestor: UIViewController? = self
            while let current = ancestor {
                if current.isBeingDismissed { return true }
                ancestor = current.parent
            }
            return false
        }

        override func loadView() {
            view = UIView(frame: .zero)
            view.isUserInteractionEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            dismissalStarted = ancestorIsBeingDismissed
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            if dismissalStarted || ancestorIsBeingDismissed { onDismiss?() }
            dismissalStarted = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            dismissalStarted = false
        }
    }
}

private enum ComparisonMode: String, CaseIterable, Identifiable {
    case sideBySide = "Side by side"
    case wipe = "Wipe"
    var id: Self { self }
}

private enum ComparisonPhotoRole: Equatable {
    case reference, testShot
    var title: String { self == .reference ? "Reference" : "Test shot" }
    var pickerName: String { self == .reference ? "reference" : "test shot" }
    var identifier: String { self == .reference ? "Reference" : "TestShot" }
}

/// Each slot owns its task and generation. An obsolete provider completion can
/// neither replace an image nor clear the loading state of a newer import.
@MainActor
private final class ComparisonPhotoSlot: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var failure: String?
    private var requestID = UUID()
    private var importTask: Task<Void, Never>?

    init(image: UIImage? = nil) { self.image = image }

    var pixelDescription: String {
        guard let image else { return "" }
        let width = image.cgImage?.width ?? Int(image.size.width * image.scale)
        let height = image.cgImage?.height ?? Int(image.size.height * image.scale)
        return "\(width) × \(height) px · session only"
    }

    func load(_ item: PhotosPickerItem) {
        cancelImport()
        let token = requestID
        isLoading = true
        importTask = Task { [weak self] in
            defer {
                if self?.requestID == token {
                    self?.isLoading = false
                    self?.importTask = nil
                }
            }
            do {
                let transferred = try await item.loadTransferable(type: ReferencePhoto.self)
                guard let self, !Task.isCancelled, self.requestID == token else { return }
                guard let photo = transferred, let replacement = UIImage(data: photo.png) else {
                    throw ReferenceImportError.unreadable
                }
                guard !Task.isCancelled, self.requestID == token else { return }
                self.image = replacement
                self.failure = nil
            } catch is CancellationError {
                // Provider cancellation leaves any previous image intact.
            } catch {
                guard let self, !Task.isCancelled, self.requestID == token else { return }
                let detail = (error as? ReferenceImportError)?.errorDescription ??
                    "The photo is unavailable. Check Photos or choose another local image."
                self.failure = self.image == nil ? detail :
                    "Replacement failed. Your previous photo is still open. \(detail)"
            }
        }
    }

    func cancelImport() {
        requestID = UUID()
        importTask?.cancel()
        importTask = nil
        isLoading = false
        failure = nil
    }

    func clear() {
        cancelImport()
        image = nil
    }

    deinit { importTask?.cancel() }
}
