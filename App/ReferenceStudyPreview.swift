import SwiftUI
import CoreGraphics
import Foundation
import LightingCore

/// The bounded CPU reference study is deliberately distinct from the illustrative
/// SceneKit views. All rendering happens on a worker, with stale results discarded.
struct ReferenceStudyPreview: View {
    let scene: LightingScene
    @State private var frame: Frame?

    private struct Frame {
        let scene: LightingScene
        let image: CGImage?
        let unsupportedPixels: Int
        let message: String?
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Color.black
                if let frame, frame.scene == scene {
                    if let image = frame.image {
                        let width = min(geometry.size.width, geometry.size.height * 1.5)
                        Image(decorative: image, scale: 1, orientation: .up)
                            .resizable().interpolation(.medium)
                            .frame(width: width, height: width / 1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel("Rendered neutral sphere and panel")
                            .accessibilityIdentifier("studyPreview")
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
        .task(id: scene) {
            let snapshot = scene
            do { try await Task.sleep(nanoseconds: 80_000_000) } catch { return }
            let task = Task.detached(priority: .userInitiated) {
                Result { try ReferenceStudyRenderer.render(scene: snapshot, width: 192,
                                                           isCancelled: { Task.isCancelled }) }
            }
            let result = await withTaskCancellationHandler(operation: {
                await task.value
            }, onCancel: {
                task.cancel()
            })
            guard !Task.isCancelled else { return }
            switch result {
            case .success(let study):
                let image = Self.makeImage(study)
                frame = Frame(scene: snapshot, image: image, unsupportedPixels: study.unsupportedPixels,
                              message: image == nil ? "The rendered image could not be displayed." : nil)
            case .failure(let error):
                let message: String
                switch error as? StudyError {
                case .invalidCamera: message = "Move the camera above the panel and away from the subject."
                case .invalidEmitter: message = "Check the aiming direction of each active light."
                default: message = "Check the camera, light positions, and preview settings."
                }
                frame = Frame(scene: snapshot, image: nil, unsupportedPixels: 0, message: message)
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
