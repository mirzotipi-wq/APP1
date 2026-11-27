import LightingCore
import SwiftUI

/// Presents the session's current feature without adding a second route owner.
@MainActor
struct StudioFeatureSheets: ViewModifier {
    let session: StudioSession
    let onReferenceApplied: () -> Void

    func body(content: Content) -> some View {
        content.background {
            if let feature = session.feature {
                let context = feature.context
                Color.clear
                    .sheet(isPresented: presentationBinding(for: context), onDismiss: {
                        session.finishFeature(context)
                    }) {
                        destination(for: feature)
                            .disabled(session.isBusy)
                    }
                    .id(context.id)
            }
        }
    }

    private func presentationBinding(for context: StudioFeatureContext) -> Binding<Bool> {
        Binding(get: {
            guard let current = session.feature else { return false }
            return current.id == context.id && current.isPresented
        }, set: { presented in
            // A sheet may retire only its own live receipt. A late true write
            // cannot reopen it, and an old dismissal cannot retire a new owner.
            guard !presented else { return }
            session.retireFeature(context)
        })
    }

    @ViewBuilder
    private func destination(for feature: StudioFeaturePresentation) -> some View {
        let context = feature.context
        switch feature.destination {
        case .reference:
            ReferenceComparisonView(scene: context.scene) { next in
                guard session.applyFeatureScene(next, from: context) else {
                    return false
                }
                onReferenceApplied()
                return true
            }
        case .arrangement:
            SceneArrangementView(scene: context.scene) { next in
                session.applyFeatureScene(next, from: context)
            }
        case let .targetLux(lightID):
            if let light = context.scene.lights.first(where: { $0.id == lightID }) {
                LightTargetLuxView(light: light, scene: context.scene) { adjusted in
                    session.applyFeatureLight(adjusted, from: context)
                }
            }
        case .room:
            ManualRoomPlacementView(scene: session.scene,
                onRemove: { session.applyFeatureRoom(nil, from: context) },
                onClose: { session.retireFeature(context) },
                onChange: { session.applyFeatureRoom($0, from: context) })
        case .ar:
            // AR owns its nested manual sheet. Its local close callback must
            // leave this outer receipt active for further room edits.
            ARPlacementView(scene: session.scene,
                onRoomRemove: { session.applyFeatureRoom(nil, from: context) },
                onClose: { session.retireFeature(context) },
                onRoomChange: { session.applyFeatureRoom($0, from: context) })
        }
    }

}
