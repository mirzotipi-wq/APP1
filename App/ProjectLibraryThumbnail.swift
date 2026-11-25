import SwiftUI
import LightingCore

/// A saved rig's overhead positions, independent of the current editor. Every
/// marker stays at its authored location; coincident equipment is not spread
/// apart. This small schematic does not render lighting or retain image data.
struct ProjectLibraryThumbnail: View {
    private let snapshot: Snapshot?

    init(scene: LightingScene) {
        snapshot = Snapshot(scene: scene)
    }

    var body: some View {
        Group {
            if let snapshot {
                Canvas { context, size in
                    guard let projection = snapshot.bounds.overheadFit(
                        width: Double(size.width), height: Double(size.height),
                        padding: 10, minimumSpanMeters: 2) else { return }
                    draw(snapshot, projection: projection, size: size, in: &context)
                }
            } else {
                Image(systemName: "exclamationmark.circle").foregroundStyle(.secondary)
            }
        }
        .frame(width: 64, height: 56)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ snapshot: Snapshot, projection: StudioOverheadProjection,
                      size: CGSize, in context: inout GraphicsContext) {
        func point(_ position: Position) -> CGPoint {
            let projected = projection.project(position)
            return .init(x: CGFloat(projected.x), y: CGFloat(projected.y))
        }

        // The existing projection bounds grid generation. A thumbnail needs
        // at most five lines per axis even for a rig spanning hundreds of meters.
        if let grid = projection.grid(maximumLinesPerAxis: 5) {
            var path = Path()
            for x in grid.verticalWorldCoordinates {
                let column = point(.init(x: x, y: 0, z: projection.center.z)).x
                path.move(to: .init(x: column, y: 0))
                path.addLine(to: .init(x: column, y: size.height))
            }
            for z in grid.horizontalWorldCoordinates {
                let row = point(.init(x: projection.center.x, y: 0, z: z)).y
                path.move(to: .init(x: 0, y: row))
                path.addLine(to: .init(x: size.width, y: row))
            }
            context.stroke(path, with: .color(.primary.opacity(0.12)), lineWidth: 0.5)
        }

        let subject = point(snapshot.scene.subject)
        let camera = point(snapshot.scene.camera)
        var sightLine = Path()
        sightLine.move(to: camera)
        sightLine.addLine(to: subject)
        context.stroke(sightLine, with: .color(.primary.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 0.75, dash: [2, 2]))

        for light in snapshot.scene.lights {
            let center = point(light.position)
            let optics = light.effectiveOptics
            if optics.kind.isAimed {
                var aim = Path()
                aim.move(to: center)
                aim.addLine(to: point(light.target(subject: snapshot.scene.subject)))
                context.stroke(aim, with: .color(.primary.opacity(0.25)), lineWidth: 0.75)
            }
            if optics.kind == .rectangle,
               let frame = StudioPhotometry.frame(for: light, subject: snapshot.scene.subject) {
                var face = Path()
                for (index, corner) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)].enumerated() {
                    let horizontal = corner.0 * optics.widthMeters / 2
                    let vertical = corner.1 * optics.heightMeters / 2
                    let position = Position(
                        x: light.position.x + frame.right.x * horizontal + frame.up.x * vertical,
                        y: light.position.y + frame.right.y * horizontal + frame.up.y * vertical,
                        z: light.position.z + frame.right.z * horizontal + frame.up.z * vertical)
                    if index == 0 { face.move(to: point(position)) }
                    else { face.addLine(to: point(position)) }
                }
                face.closeSubpath()
                context.fill(face, with: .color(.orange.opacity(0.18)))
                context.stroke(face, with: .color(.primary.opacity(0.55)), lineWidth: 0.75)
            }
            let marker = Path(CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            context.fill(marker, with: .color(light.candela > 0 ? .orange : Color(uiColor: .secondarySystemBackground)))
            context.stroke(marker, with: .color(.primary), lineWidth: 0.75)
        }

        // Point the camera glyph toward the subject where its horizontal aim
        // exists. A vertical/coincident aim uses only the neutral triangle glyph.
        let dx = subject.x - camera.x, dy = subject.y - camera.y
        let distance = hypot(dx, dy)
        let forward = distance > 0 ? CGPoint(x: dx / distance, y: dy / distance) : CGPoint(x: 0, y: -1)
        let right = CGPoint(x: -forward.y, y: forward.x)
        var cameraMarker = Path()
        cameraMarker.move(to: .init(x: camera.x + forward.x * 4.5, y: camera.y + forward.y * 4.5))
        cameraMarker.addLine(to: .init(x: camera.x - forward.x * 3 + right.x * 3.5,
                                       y: camera.y - forward.y * 3 + right.y * 3.5))
        cameraMarker.addLine(to: .init(x: camera.x - forward.x * 3 - right.x * 3.5,
                                       y: camera.y - forward.y * 3 - right.y * 3.5))
        cameraMarker.closeSubpath()
        context.fill(cameraMarker, with: .color(.primary))
        context.stroke(cameraMarker, with: .color(Color(uiColor: .secondarySystemBackground)), lineWidth: 0.75)

        let subjectMarker = Path(ellipseIn: .init(x: subject.x - 3.5, y: subject.y - 3.5, width: 7, height: 7))
        context.fill(subjectMarker, with: .color(.primary))
        context.stroke(subjectMarker, with: .color(Color(uiColor: .secondarySystemBackground)), lineWidth: 0.75)
    }

    private struct Snapshot {
        let scene: LightingScene
        let bounds: StudioSceneBounds

        init?(scene: LightingScene) {
            // Saved scenes permit at most 12 lights. Do not traverse an invalid
            // oversized collection, or revalidate raw legacy names for drawing.
            guard scene.lights.count <= 12 else { return nil }
            let lights = scene.lights.map { light in
                var drawingLight = light
                drawingLight.name = "Light"
                return drawingLight
            }
            // Only geometry and light optics affect this plan. Excluding room
            // notes and long names keeps work bounded by twelve lights and up
            // to forty-eight rectangular face corners, not document text.
            let drawingScene = LightingScene(subject: scene.subject, camera: scene.camera, lights: lights)
            guard let bounds = try? StudioSceneBounds(scene: drawingScene) else { return nil }
            self.scene = drawingScene
            self.bounds = bounds
        }
    }
}
