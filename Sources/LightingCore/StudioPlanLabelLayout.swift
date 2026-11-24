import Foundation

/// Bounded caption placement for the live overhead plan. Equipment anchors
/// never move. A caption that cannot fit is explicitly absent, rather than
/// covering equipment or suggesting that equipment moved to its label.
public struct StudioPlanLabelLayout: Equatable, Sendable {
    public static let maximumMarkers = 14 // Subject, camera and twelve lights.
    public static let markerDiameter = 44.0

    public struct Item: Equatable, Sendable {
        public let anchorX: Double
        public let anchorY: Double
        public let captionWidth: Double
        public let captionHeight: Double
        public let isSelected: Bool

        public init(anchorX: Double, anchorY: Double, captionWidth: Double,
                    captionHeight: Double, isSelected: Bool = false) {
            self.anchorX = anchorX; self.anchorY = anchorY
            self.captionWidth = captionWidth; self.captionHeight = captionHeight
            self.isSelected = isSelected
        }
    }

    public struct Rect: Equatable, Sendable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double
        public var maxX: Double { x + width }
        public var maxY: Double { y + height }
        public var centerX: Double { x + width / 2 }
        public var centerY: Double { y + height / 2 }

        public func intersects(_ other: Self, gap: Double = 0) -> Bool {
            x < other.maxX + gap && maxX + gap > other.x &&
                y < other.maxY + gap && maxY + gap > other.y
        }
    }

    /// Arrays keep input order; selection changes placement priority only.
    public let markerFrames: [Rect]
    public let captionFrames: [Rect?]
    public let crowdedMarkerIndices: [Int]
    public var omittedCaptionCount: Int { captionFrames.filter { $0 == nil }.count }

    public init?(items: [Item], width: Double, height: Double, reservedTop: Double = 32) {
        guard items.count <= Self.maximumMarkers,
              [width, height, reservedTop].allSatisfy(\.isFinite),
              width > 0, height > 0, reservedTop >= 0,
              items.allSatisfy({ item in
                  [item.anchorX, item.anchorY, item.captionWidth, item.captionHeight].allSatisfy(\.isFinite) &&
                      item.captionWidth > 0 && item.captionHeight > 0
              }) else { return nil }
        let radius = Self.markerDiameter / 2
        let markers = items.map { Rect(x: $0.anchorX - radius, y: $0.anchorY - radius,
                                       width: Self.markerDiameter, height: Self.markerDiameter) }
        guard markers.allSatisfy({ [$0.x, $0.y, $0.maxX, $0.maxY].allSatisfy(\.isFinite) }) else { return nil }
        self.markerFrames = markers
        self.crowdedMarkerIndices = items.indices.filter { i in
            items.indices.contains { j in j != i && markers[i].intersects(markers[j]) }
        }
        var placed = [Rect?](repeating: nil, count: items.count)
        let margin = 8.0, gap = 4.0
        let top = max(margin, reservedTop)
        let order = items.indices.sorted {
            if items[$0].isSelected != items[$1].isSelected { return items[$0].isSelected }
            return $0 < $1
        }
        for index in order {
            let item = items[index], w = item.captionWidth, h = item.captionHeight
            guard w <= width - 2 * margin, h <= height - top - margin else { continue }
            let x = item.anchorX, y = item.anchorY, offset = radius + gap
            // Prefer a familiar adjacent caption before using a leader line.
            var candidates = [
                Rect(x: x - w / 2, y: y + offset, width: w, height: h),
                Rect(x: x - w / 2, y: y - offset - h, width: w, height: h),
                Rect(x: x + offset, y: y - h / 2, width: w, height: h),
                Rect(x: x - offset - w, y: y - h / 2, width: w, height: h),
                Rect(x: x + offset, y: y + offset, width: w, height: h),
                Rect(x: x - offset - w, y: y + offset, width: w, height: h),
                Rect(x: x + offset, y: y - offset - h, width: w, height: h),
                Rect(x: x - offset - w, y: y - offset - h, width: w, height: h)
            ]
            // Fixed 9x7 search, independent of canvas pixels or name length.
            // Stable distance ordering keeps equally good placements repeatable.
            var fallback: [Rect] = []
            for row in 0..<7 {
                for column in 0..<9 {
                    fallback.append(Rect(x: margin + (width - 2 * margin - w) * Double(column) / 8,
                                         y: top + (height - top - margin - h) * Double(row) / 6,
                                         width: w, height: h))
                }
            }
            let sortedFallback = fallback.enumerated().sorted { a, b in
                let da = hypot(a.element.centerX - x, a.element.centerY - y)
                let db = hypot(b.element.centerX - x, b.element.centerY - y)
                return da == db ? a.offset < b.offset : da < db
            }.map(\.element)
            candidates += sortedFallback
            placed[index] = candidates.first { candidate in
                candidate.x >= margin && candidate.y >= top &&
                    candidate.maxX <= width - margin && candidate.maxY <= height - margin &&
                    !markers.contains { candidate.intersects($0, gap: gap) } &&
                    !placed.compactMap({ $0 }).contains { candidate.intersects($0, gap: gap) }
            }
        }
        self.captionFrames = placed
    }
}
