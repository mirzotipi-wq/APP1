import SwiftUI
import CoreGraphics
import Foundation
import LightingCore

/// The bounded direct-light study is deliberately distinct from the illustrative
/// SceneKit views. A serialized worker validates Metal against CPU before use.
struct ReferenceStudyPreview: View {
    let scene: LightingScene
    var subject: StudySubject = .sphere
    @State private var frame: Frame?

    private struct Request: Equatable {
        let scene: LightingScene
        let subject: StudySubject
    }
    private var request: Request { .init(scene: scene, subject: subject) }
    private var imageLabel: String {
        subject == .sphere ? "Rendered neutral sphere and panel" : "Rendered neutral mannequin bust"
    }

    private struct Frame {
        let request: Request
        let image: CGImage?
        let unsupportedPixels: Int
        let backend: StudyBackend?
        let message: String?
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Color.black
                if let frame, frame.request == request {
                    if let image = frame.image {
                        let width = min(geometry.size.width, geometry.size.height * 1.5)
                        Image(image, scale: 1, orientation: .up, label: Text(imageLabel))
                            .resizable().interpolation(.medium)
                            .frame(width: width, height: width / 1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel(imageLabel)
                            .accessibilityIdentifier("studyPreview")
                        if let backend = frame.backend {
                            Text(backend.rawValue).font(.caption2.monospaced())
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(6).background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 6))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .padding(8).accessibilityIdentifier("studyBackend")
                        }
                        if frame.unsupportedPixels > 0 {
                            Label("\(frame.unsupportedPixels) unsupported pixels (magenta). Move the lights farther away.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(8).background(.black.opacity(0.85))
                                .accessibilityIdentifier("studyWarning")
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle").font(.title2)
                            Text("Study unavailable").font(.headline)
                            Text(frame.message ?? "Check camera and lighting geometry.").font(.caption)
                        }
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white).padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("studyUnavailable")
                    }
                } else {
                    ProgressView("Rendering light study")
                        .tint(.white).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier("studyLoading")
                }
            }
        }
        .task(id: request) {
            let snapshot = request
            do { try await Task.sleep(nanoseconds: 80_000_000) } catch { return }
            do {
                let rendered = try await StudyRenderEngine.shared.render(scene: snapshot.scene, subject: snapshot.subject)
                guard !Task.isCancelled else { return }
                let study = rendered.image
                let image = Self.makeImage(study)
                frame = Frame(request: snapshot, image: image, unsupportedPixels: study.unsupportedPixels,
                              backend: rendered.backend,
                              message: image == nil ? "The rendered image could not be displayed." : nil)
            } catch {
                guard !Task.isCancelled else { return }
                let message: String
                switch error as? StudyError {
                case .invalidCamera: message = "Move the camera above the panel and away from the subject."
                case .invalidEmitter: message = "Check the aiming direction of each active light."
                default: message = "Check the camera, light positions, and preview settings."
                }
                frame = Frame(request: snapshot, image: nil, unsupportedPixels: 0, backend: nil, message: message)
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
