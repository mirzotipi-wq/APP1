import LightingCore
import PhotosUI
import SwiftUI
import UIKit

/// An explicitly ephemeral comparison. Closing it discards the app's image derivative;
/// the original in Photos and the saved lighting project remain unchanged.
struct ReferenceComparisonView: View {
    let scene: LightingScene
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicType
    @State private var selection: PhotosPickerItem?
    @State private var requestID = UUID()
    @State private var reference: UIImage?
    @State private var loading = false
    @State private var failure: String?
    @State private var sizeDescription = ""
    @State private var importTask: Task<Void, Never>?

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
                            Button(role: .destructive) { clear() } label: {
                                Label(loading ? "Cancel" : "Remove", systemImage: loading ? "xmark" : "trash")
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
                    VStack(alignment: .leading, spacing: 7) {
                        Label("On-device comparison", systemImage: "lock.shield").font(.headline)
                        Text("Key & Fill keeps a reduced, metadata-free copy in memory only. Closing this view or removing the photo discards that copy. It is not included in saved projects or PDF exports. Photos may retrieve an iCloud original through the system picker. Your original is never modified.")
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
                if let reference {
                    Image(uiImage: reference).resizable().scaledToFit()
                        .accessibilityLabel("Imported reference photograph")
                        .accessibilityIdentifier("importedReference")
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
            Text("CURRENT LIGHT STUDY").font(.caption.weight(.semibold)).tracking(1.2)
            ReferenceStudyPreview(scene: scene).frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Direct light only · uncalibrated relative preview")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @MainActor private func load(_ item: PhotosPickerItem, token: UUID) {
        importTask?.cancel()
        importTask = Task {
            do {
                guard let photo = try await item.loadTransferable(type: ReferencePhoto.self),
                      let image = UIImage(data: photo.png) else { throw ReferenceImportError.unreadable }
                guard !Task.isCancelled, requestID == token else { return }
                reference = image
                sizeDescription = "\(photo.width) × \(photo.height) px · session only"
                loading = false
            } catch {
                guard !Task.isCancelled, requestID == token else { return }
                failure = (error as? ReferenceImportError)?.errorDescription ??
                    "The photo is unavailable. Check Photos or choose another local image."
                loading = false
            }
        }
    }

    @MainActor private func clear() {
        requestID = UUID()
        importTask?.cancel()
        importTask = nil
        selection = nil
        reference = nil
        sizeDescription = ""
        failure = nil
        loading = false
    }
}
