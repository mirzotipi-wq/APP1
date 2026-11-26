import Foundation
import LightingCore
#if canImport(SwiftUI) && canImport(CoreGraphics)
import SwiftUI
import CoreGraphics
#endif

/// The publication seam has no dependency on a GPU or on image conversion.
/// Tests can finish a noncooperative renderer after a newer request has won.
struct StudyPreviewOutput: Sendable {
    let image: StudyImage
    let backendLabel: String
}

@MainActor final class StudyPreviewPipeline<DisplayImage> {
    struct Completion {
        let image: DisplayImage?
        let unsupportedPixels: Int
        let backendLabel: String?
        let message: String?
    }

    private var current: UUID?

    /// Begin even when reusing a completed frame: an A → B → A switch must
    /// invalidate B without requiring another render of the cached A image.
    /// A cancelled caller gets an unused ticket without superseding live work.
    func begin() -> UUID {
        let ticket = UUID()
        guard !Task.isCancelled else { return ticket }
        current = ticket
        return ticket
    }

    func invalidate() { current = nil }

    func load(ticket: UUID,
              render: () async throws -> StudyPreviewOutput,
              convert: (StudyImage) -> DisplayImage?,
              publish: (Completion) -> Void) async {
        guard current == ticket, !Task.isCancelled else { return }
        do {
            let output = try await render()
            guard current == ticket, !Task.isCancelled else { return }
            let image = convert(output.image)
            guard current == ticket, !Task.isCancelled else { return }
            publish(.init(image: image, unsupportedPixels: image == nil ? 0 : output.image.unsupportedPixels,
                          backendLabel: image == nil ? nil : output.backendLabel,
                          message: image == nil ? "The rendered image could not be displayed." : nil))
        } catch {
            guard current == ticket, !Task.isCancelled, !(error is CancellationError),
                  (error as? StudyError) != .cancelled else { return }
            let message: String
            switch error as? StudyError {
            case .invalidCamera: message = "Move the camera above the panel and away from the subject."
            case .invalidEmitter: message = "Check the aiming direction of each active light."
            default: message = "Check the camera, light positions, and preview settings."
            }
            publish(.init(image: nil, unsupportedPixels: 0, backendLabel: nil, message: message))
        }
    }
}

#if canImport(SwiftUI) && canImport(CoreGraphics)

/// The bounded direct-light study is deliberately distinct from the illustrative
/// SceneKit views. A serialized worker validates Metal against CPU before use.
@MainActor struct ReferenceStudyPreview: View {
    let scene: LightingScene
    var subject: StudySubject = .sphere
    @Environment(\.scenePhase) private var scenePhase
    @State private var frame: Frame?
    @State private var attempt = UUID()
    @State private var pipeline = StudyPreviewPipeline<CGImage>()

    private struct Request: Equatable {
        let scene: LightingScene
        let subject: StudySubject

        init(scene: LightingScene, subject: StudySubject) {
            // Measured-room placement does not participate in this direct-light
            // study. Keep its snapshot and identity independent of room edits,
            // retaining the complete light optics, camera and preview settings.
            var renderScene = scene
            renderScene.placementRoom = nil
            self.scene = renderScene
            self.subject = subject
        }
    }
    private var request: Request { .init(scene: scene, subject: subject) }
    // Changing to nil cancels in-flight work while inactive; foregrounding
    // starts the latest scene/subject request without discarding a valid frame.
    private var activeRequest: Request? { scenePhase == .active ? request : nil }
    private struct Work: Equatable {
        let request: Request?
        let attempt: UUID
    }
    private var work: Work { .init(request: activeRequest, attempt: attempt) }
    private var imageLabel: String {
        subject == .sphere ? "Rendered neutral sphere and panel" : "Rendered neutral mannequin bust"
    }

    private struct Frame {
        let request: Request
        let image: CGImage?
        let unsupportedPixels: Int
        let backendLabel: String?
        let message: String?
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Color.black
                // A previous scene may remain visible while it updates, but a
                // different subject or an old error must never stand in for it.
                if let frame,
                   frame.request == request || (frame.image != nil && frame.request.subject == subject) {
                    let isCurrent = frame.request == request
                    if let image = frame.image {
                        let width = min(geometry.size.width, geometry.size.height * 1.5)
                        let updateStatus = activeRequest == nil ? "Light study paused" : "Updating light study"
                        let label = isCurrent ? imageLabel : "Previous render. \(imageLabel). \(updateStatus)."
                        Image(image, scale: 1, orientation: .up, label: Text(label))
                            .resizable().interpolation(.medium)
                            .frame(width: width, height: width / 1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel(label)
                            .accessibilityIdentifier(isCurrent ? "studyPreview" : "studyPreviousPreview")
                        if isCurrent, let backendLabel = frame.backendLabel {
                            Text(backendLabel).font(.caption2.monospaced())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(6).background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 6))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .padding(8).accessibilityIdentifier("studyBackend")
                        }
                        if isCurrent, frame.unsupportedPixels > 0 {
                            Label("\(frame.unsupportedPixels) unsupported pixels (magenta). Move the lights farther away.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(8).background(.black.opacity(0.85))
                                .accessibilityIdentifier("studyWarning")
                        }
                        if !isCurrent {
                            Group {
                                if activeRequest == nil {
                                    Text("Light study paused")
                                } else {
                                    ProgressView("Updating light study")
                                        .controlSize(.small)
                                }
                            }
                                .font(.caption.weight(.medium))
                                .tint(.white).foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                                .padding(8)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                .accessibilityLabel(updateStatus)
                                .accessibilityValue("Showing the previous scene")
                                .accessibilityIdentifier(activeRequest == nil ? "studyPaused" : "studyUpdating")
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle").font(.title2)
                                    .accessibilityHidden(true)
                                Text("Study unavailable").font(.headline)
                                Text(frame.message ?? "Check camera and lighting geometry.").font(.caption)
                                Button { attempt = UUID() } label: {
                                    Text("Retry light study").frame(minHeight: 44)
                                }
                                    .buttonStyle(.bordered)
                                    .accessibilityIdentifier("studyRetry")
                            }
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white).padding(24)
                            .frame(maxWidth: .infinity)
                        }
                        .defaultScrollAnchor(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("studyUnavailable")
                    }
                } else if activeRequest == nil {
                    Text("Light study paused")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("studyPaused")
                } else {
                    ProgressView("Rendering light study")
                        .tint(.white).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("studyLoading")
                }
            }
        }
        .onDisappear { pipeline.invalidate() }
        .task(id: work) {
            guard !Task.isCancelled else { return }
            let ticket = pipeline.begin()
            guard let snapshot = activeRequest else { return }
            // A quick switch back to a completed request can reuse its pixels.
            // Failed frames remain retryable when this view appears again.
            if let frame, frame.request == snapshot, frame.image != nil { return }
            // A new attempt shows loading, not an obsolete failure. Retrying
            // never edits the scene or changes its cache identity.
            if frame?.request == snapshot { frame = nil }
            do { try await Task.sleep(nanoseconds: 80_000_000) } catch { return }
            await pipeline.load(ticket: ticket, render: {
                let rendered = try await StudyRenderEngine.shared.render(scene: snapshot.scene, subject: snapshot.subject)
                return .init(image: rendered.image, backendLabel: rendered.backend.rawValue)
            }, convert: Self.makeImage) { completion in
                frame = Frame(request: snapshot, image: completion.image, unsupportedPixels: completion.unsupportedPixels,
                              backendLabel: completion.backendLabel, message: completion.message)
            }
        }
    }

    private static func makeImage(_ study: StudyImage) -> CGImage? {
        guard study.rgba.count == study.width * study.height * 4,
              let provider = CGDataProvider(data: study.rgba as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGImage(width: study.width, height: study.height,
                       bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: study.width * 4,
                       space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
#endif
