import LightingCore
import SwiftUI
import UIKit

struct StudioPlanMarker: Identifiable {
    let id: String
    let anchor: CGPoint
    let name: String
    let icon: String
    let color: Color
    let selected: Bool
    let accessibilityLabel: String
    var accessibilityIdentifier = ""
    var action: (() -> Void)?
    var onDragChanged: ((CGSize) -> Void)? = nil
    var onDragEnded: (() -> Void)? = nil
}

struct StudioPlanLabelNoticeKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

struct StudioPlanGridTitleKey: PreferenceKey {
    static let defaultValue = "OVERHEAD"
    static func reduce(value: inout String, nextValue: () -> String) { value = nextValue() }
}

/// Captions have their own layout; the 44pt controls stay on the exact world
/// projection. Semantic caption fonts and their measured sizes scale together.
struct StudioPlanMarkers: View {
    let markers: [StudioPlanMarker]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width, height = geometry.size.height
            let font = captionFont
            let measures = markers.map { measure($0.name, font: font, width: width) }
            let items = markers.indices.map { index in
                StudioPlanLabelLayout.Item(anchorX: Double(markers[index].anchor.x),
                                           anchorY: Double(markers[index].anchor.y),
                                           captionWidth: Double(measures[index].width),
                                           captionHeight: Double(measures[index].height),
                                           isSelected: markers[index].selected)
            }
            let layout = StudioPlanLabelLayout(items: items, width: Double(width), height: Double(height),
                                               reservedTop: 8)
            let needsNotice = layout == nil || (layout?.omittedCaptionCount ?? 0) > 0 ||
                !(layout?.crowdedMarkerIndices.isEmpty ?? true)
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    guard let layout else { return }
                    for index in markers.indices {
                        guard let frame = layout.captionFrames[index] else { continue }
                        let anchor = markers[index].anchor
                        let end = CGPoint(x: min(max(Double(anchor.x), frame.x), frame.maxX),
                                          y: min(max(Double(anchor.y), frame.y), frame.maxY))
                        var leader = Path()
                        leader.move(to: anchor); leader.addLine(to: end)
                        context.stroke(leader, with: .color(markers[index].color.opacity(0.45)), lineWidth: 0.75)
                    }
                }
                .accessibilityHidden(true).allowsHitTesting(false)
                ForEach(Array(markers.enumerated()), id: \.element.id) { index, marker in
                    if let frame = layout?.captionFrames[index] {
                        Text(marker.name)
                            .font(Font(font))
                            .lineLimit(nil)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: max(1, CGFloat(frame.width) - 8))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                            .position(x: CGFloat(frame.centerX), y: CGFloat(frame.centerY))
                            // The caption is displaced from the marker's action
                            // frame; expose the visible text at its own location.
                            .allowsHitTesting(false)
                    }
                }
                ForEach(markers) { marker in
                    StudioPlanMarkerControl(marker: marker)
                        .position(marker.anchor)
                        // Coincident equipment is never separated cosmetically.
                        // Keep the selected icon on top; all lights remain in the list.
                        .zIndex(marker.selected ? 2 : 1)
                }
            }
            .preference(key: StudioPlanLabelNoticeKey.self, value: needsNotice)
        }
    }

    private var captionFont: UIFont {
        // Resolve the semantic style using this view's actual Dynamic Type
        // traits. Rendering and measurement use this same font instance.
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(preferredContentSizeCategory: contentSizeCategory),
            UITraitCollection(legibilityWeight: legibilityWeight == .bold ? .bold : .regular)
        ])
        let preferred = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traits)
        let weight: UIFont.Weight = legibilityWeight == .bold ? .bold : .semibold
        let descriptor = preferred.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight.rawValue]
        ])
        return UIFont(descriptor: descriptor, size: preferred.pointSize)
    }

    private var contentSizeCategory: UIContentSizeCategory {
        switch dynamicTypeSize {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }

    private func measure(_ name: String, font: UIFont, width: CGFloat) -> CGSize {
        // Callers pass the existing bounded StudioDisplayName label. Do not
        // measure raw imported names, which may contain long combining runs.
        let intrinsic = (name as NSString).size(withAttributes: [.font: font])
        let scale = max(1, displayScale)
        let standard = UIFont.preferredFont(forTextStyle: .caption2,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let maximumWidth = max(9, min(128 * font.pointSize / standard.pointSize, width - 16))
        let textWidth = max(1, min(ceil(intrinsic.width * scale) / scale, maximumWidth - 8))
        let bounds = (name as NSString).boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font], context: nil)
        let textHeight = ceil(max(font.lineHeight, bounds.height) * scale) / scale
        // Only the width constrains Text. Its height remains intrinsic, and a
        // full multiline caption that cannot fit activates the visible list notice.
        return CGSize(width: textWidth + 8, height: textHeight + 4)
    }
}

/// ForEach supplies the stable marker identity, so a moving anchor does not
/// replace the gesture's state or its captured completion callback.
private struct StudioPlanMarkerControl: View {
    let marker: StudioPlanMarker
    @Environment(\.isEnabled) private var isEnabled
    @GestureState private var dragRecognized = false
    @State private var dragInProgress = false
    @State private var dragChange: ((CGSize) -> Void)?
    @State private var dragCompletion: (() -> Void)?

    var body: some View {
        control
            .accessibilityLabel(marker.accessibilityLabel)
            .accessibilityIdentifier(marker.accessibilityIdentifier)
            .accessibilityAddTraits(marker.selected ? .isSelected : [])
            .allowsHitTesting(isEnabled)
            .onChange(of: dragInProgress && !dragRecognized) { _, needsCompletion in
                // GestureState also resets when the system cancels a gesture;
                // include ownership so a start and cancel in one render still
                // closes the transaction even if no true state was rendered.
                if needsCompletion { finishDrag() }
            }
            .onChange(of: marker.onDragChanged != nil) { _, enabled in
                if !enabled { finishDrag() }
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { finishDrag() }
            }
            .onDisappear { finishDrag() }
    }

    @ViewBuilder private var control: some View {
        if marker.onDragChanged != nil {
            markerIcon
                // Exclusive recognition preserves taps while preventing a drag
                // from also activating the marker. A selected marker owns its
                // drag; simultaneous recognition would also move the scroll view
                // before the parent can disable scrolling for this transaction.
                .highPriorityGesture(dragGesture.exclusively(before:
                    TapGesture().onEnded {
                        if isEnabled { marker.action?() }
                    }))
                .accessibilityAddTraits(marker.action == nil ? [] : .isButton)
                .accessibilityHint("Use the position controls below to move this light precisely.")
                .accessibilityAction {
                    if isEnabled { marker.action?() }
                }
        } else if let action = marker.action {
            Button(action: action) { markerIcon }.buttonStyle(.plain)
        } else {
            markerIcon
        }
    }

    private var dragGesture: some Gesture {
        // Global translation stays stable while the projected marker itself
        // moves. The parent converts this cumulative offset using a frozen scale.
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .updating($dragRecognized) { _, recognized, _ in recognized = true }
            .onChanged { value in
                guard isEnabled else { finishDrag(); return }
                if !dragInProgress {
                    guard let changed = marker.onDragChanged else { return }
                    dragInProgress = true
                    // A project copy can retain these marker IDs. Keep value
                    // writes paired with the generation captured at drag begin.
                    dragChange = changed
                    dragCompletion = marker.onDragEnded
                }
                dragChange?(value.translation)
            }
            .onEnded { value in
                if isEnabled && dragInProgress { dragChange?(value.translation) }
                finishDrag()
            }
    }

    private func finishDrag() {
        guard dragInProgress else { return }
        // Clear ownership before invoking the parent: completion may remove this
        // marker, disable dragging, or change the scene synchronously.
        dragInProgress = false
        let completion = dragCompletion
        dragChange = nil
        dragCompletion = nil
        completion?()
    }

    private var markerIcon: some View {
        Image(systemName: marker.icon)
            .font(.system(size: 17, weight: .medium)).foregroundStyle(marker.color)
            .frame(width: 34, height: 34)
            .background(marker.selected ? marker.color.opacity(0.25) : Color.black.opacity(0.65), in: Circle())
            .overlay { Circle().strokeBorder(marker.color.opacity(marker.selected ? 1 : 0.45),
                                             lineWidth: marker.selected ? 2 : 1) }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}
