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

/// Captions have their own layout; the 44pt controls stay on the exact world
/// projection. Semantic caption fonts and their measured sizes scale together.
struct StudioPlanMarkers: View {
    let markers: [StudioPlanMarker]
    let gridTitle: String
    @ScaledMetric(relativeTo: .caption2) private var captionPointSize: CGFloat = 11
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width, height = geometry.size.height
            let font = UIFont.systemFont(ofSize: captionPointSize, weight: .semibold)
            let headerFont = UIFont.monospacedSystemFont(ofSize: captionPointSize, weight: .medium)
            let headerHeight = (gridTitle as NSString).boundingRect(
                with: CGSize(width: max(1, width - 20), height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: headerFont], context: nil).height
            let measures = markers.map { measure($0.name, font: font, width: width) }
            let items = markers.indices.map { index in
                StudioPlanLabelLayout.Item(anchorX: Double(markers[index].anchor.x),
                                           anchorY: Double(markers[index].anchor.y),
                                           captionWidth: Double(measures[index].size.width),
                                           captionHeight: Double(measures[index].size.height),
                                           isSelected: markers[index].selected)
            }
            let layout = StudioPlanLabelLayout(items: items, width: Double(width), height: Double(height),
                                               reservedTop: Double(ceil(headerHeight) + 22))
            let needsNotice = layout == nil || (layout?.omittedCaptionCount ?? 0) > 0 ||
                !(layout?.crowdedMarkerIndices.isEmpty ?? true) || measures.contains(where: \.shortened)
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
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1).truncationMode(.tail).foregroundStyle(.white)
                            .frame(width: max(0, CGFloat(frame.width) - 8),
                                   height: max(0, CGFloat(frame.height) - 4))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(.black.opacity(0.8), in: Capsule())
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
                Text(gridTitle)
                    .font(.caption2.monospaced().weight(.medium))
                    .foregroundStyle(.white)
                    .background(StudioPalette.planBackground)
                    .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }
            .preference(key: StudioPlanLabelNoticeKey.self, value: needsNotice)
        }
    }

    private struct Measurement { let size: CGSize; let shortened: Bool }

    private func measure(_ name: String, font: UIFont, width: CGFloat) -> Measurement {
        // Callers pass the existing bounded StudioDisplayName label. Do not
        // measure raw imported names, which may contain long combining runs.
        let intrinsic = (name as NSString).size(withAttributes: [.font: font])
        let scale = max(1, displayScale)
        let textWidth = ceil(intrinsic.width * scale) / scale
        let textHeight = ceil(intrinsic.height * scale) / scale
        let maximumWidth = max(1, min(128, width - 16))
        return .init(size: CGSize(width: min(textWidth + 8, maximumWidth), height: textHeight + 4),
                     shortened: textWidth + 8 > maximumWidth)
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
