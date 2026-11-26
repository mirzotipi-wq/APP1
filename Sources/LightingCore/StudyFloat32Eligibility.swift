import Foundation

/// Conservative routing for the optional sphere/panel Float32 backend.
/// This is a numerical-domain decision, not a physical rendering guarantee.
public enum StudyFloat32Eligibility {
    public static let maximumRelativeDistanceMeters = 20.0
    /// An engineering guard band around discontinuous near-field masks. This
    /// is deliberately larger than the observed micrometer-scale drift, but
    /// is not a proved error bound for every GPU or floating-point operation.
    public static let surfaceMarginMeters = 0.001

    public static func supports(_ scene: LightingScene) -> Bool {
        supports(scene, width: 192)
    }

    public static func supports(_ scene: LightingScene, width: Int) -> Bool {
        guard width >= 24, width <= 192, width.isMultiple(of: 3) else { return false }
        guard (try? scene.validated()) != nil,
              let geometry = StudyGeometry(center: scene.subject),
              let camera = CameraFraming(scene: scene),
              camera.position.y > geometry.panelY + 0.01,
              camera.subjectDistanceMeters > geometry.radius + CameraFraming.minimumDepthMeters,
              camera.subjectDistanceMeters <= maximumRelativeDistanceMeters,
              scene.lights.allSatisfy({ $0.candela == 0 || $0.position.distance(to: scene.subject) <= maximumRelativeDistanceMeters }),
              silhouetteShellFitsBudget(geometry: geometry, camera: camera, width: width)
        else { return false }

        let panel = visiblePanelBounds(geometry: geometry, camera: camera)
        let subject = vector(scene.subject)
        for light in scene.lights where light.candela > 0 {
            let source = vector(light.position) - subject
            let optics = light.effectiveOptics
            if optics.kind == .rectangle {
                guard let frame = StudioPhotometry.frame(for: light, subject: scene.subject) else { return false }
                let right = vector(frame.right), up = vector(frame.up)
                let halfWidth = optics.widthMeters / 2, halfHeight = optics.heightMeters / 2
                let guardDistance = max(0.05, max(optics.widthMeters, optics.heightMeters) / 4)

                // The closest point on the emitting face to the sphere center
                // gives a conservative separation from the whole sphere.
                let x = clamp(dot(-source, right), -halfWidth, halfWidth)
                let y = clamp(dot(-source, up), -halfHeight, halfHeight)
                let closest = source + right * x + up * y
                let sphereSeparation = max(0, length(closest) - geometry.radius)
                guard sphereSeparation > guardDistance + surfaceMarginMeters else { return false }

                if let panel {
                    let extents = absolute(right) * halfWidth + absolute(up) * halfHeight
                    guard panel.distance(to: source, halfExtents: extents) > guardDistance + surfaceMarginMeters
                    else { return false }
                }
            } else {
                if optics.kind == .directional,
                   StudioPhotometry.frame(for: light, subject: scene.subject) == nil { return false }
                let sphereSeparation = abs(length(source) - geometry.radius)
                guard sphereSeparation > 0.05 + surfaceMarginMeters else { return false }
                if let panel, panel.distance(to: source, halfExtents: .zero) <= 0.05 + surfaceMarginMeters {
                    return false
                }
            }
        }
        return true
    }

    /// The distance-scaled margin is an engineering allowance for Float32
    /// ray/sphere classification drift, not a proved numerical error bound.
    /// Spending at most 1/510 of the pixels on possible silhouette changes
    /// reserves half an 8-bit channel level of worst-case mean error for them,
    /// leaving budget for other drift without proving total GPU agreement.
    private static func silhouetteShellFitsBudget(geometry: StudyGeometry, camera: CameraFraming, width: Int) -> Bool {
        // EmitterFrame's near-vertical x-axis fallback need not be exactly
        // perpendicular to forward. The radial shell assumes an orthogonal
        // camera basis, so keep that narrow non-axial cone on the CPU. An
        // exactly vertical view still has an orthogonal basis and is allowed.
        guard hypot(camera.forward.x, camera.forward.z) > 1e-12 ||
                (camera.forward.x == 0 && camera.forward.z == 0) else { return false }
        let distance = camera.subjectDistanceMeters
        let margin = 32 * Double(Float.ulpOfOne) * distance
        let innerRadius = max(0, geometry.radius - margin)
        let outerRadius = geometry.radius + margin
        guard outerRadius < distance else { return false }

        // The camera targets the center. For sensor slopes px, py, the
        // tangent circle of radius R satisfies px² + py² = R² / (D² - R²).
        func squaredSlope(_ radius: Double) -> Double {
            let radiusSquared = radius * radius
            return radiusSquared / (distance * distance - radiusSquared)
        }
        let innerSquaredSlope = squaredSlope(innerRadius)
        let outerSquaredSlope = squaredSlope(outerRadius)
        let height = width * 2 / 3
        let pixelBudget = width * height / 510
        let halfWidth = CameraLens.sensorWidthMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let halfHeight = CameraLens.sensorHeightMillimeters / (2 * camera.lens.focalLengthMillimeters)

        func pixelRange(_ lower: Double, _ upper: Double) -> ClosedRange<Int>? {
            // Invert px = (2 * (x + 0.5) / width - 1) * halfWidth.
            // Allow Double roundoff through sqrt and the inverse transform,
            // then round outward to retain centers on an interval edge.
            let indexMargin = 32 * Double.ulpOfOne * Double(width)
            let firstIndex = (Double(width) * (lower / halfWidth + 1) / 2 - 0.5).nextDown
            let lastIndex = (Double(width) * (upper / halfWidth + 1) / 2 - 0.5).nextUp
            let first = max(0, ceil(firstIndex - indexMargin))
            let last = min(Double(width - 1), floor(lastIndex + indexMargin))
            guard first <= last else { return nil }
            return Int(first)...Int(last)
        }

        var potentialPixels = 0
        for y in 0..<height {
            let py = (1 - 2 * (Double(y) + 0.5) / Double(height)) * halfHeight
            let squaredY = py * py
            // Separate Double-roundoff padding keeps a tangent row from
            // disappearing through a tiny negative squared-slope difference.
            let slopeMargin = 32 * Double.ulpOfOne * max(outerSquaredSlope, squaredY)
            let outerSquaredX = outerSquaredSlope - squaredY
            guard outerSquaredX >= -slopeMargin else { continue }
            let outerX = sqrt(max(0, outerSquaredX + slopeMargin))
            let innerX = sqrt(max(0, innerSquaredSlope - squaredY - slopeMargin))
            let negative = pixelRange(-outerX, -innerX)
            let positive = pixelRange(innerX, outerX)
            if let negative {
                potentialPixels += negative.upperBound - negative.lowerBound + 1
            }
            if let positive {
                potentialPixels += positive.upperBound - positive.lowerBound + 1
                if let negative {
                    // When innerX is zero, both intervals can contain the
                    // odd-width center pixel. Count their integer union.
                    let overlapFirst = max(negative.lowerBound, positive.lowerBound)
                    let overlapLast = min(negative.upperBound, positive.upperBound)
                    potentialPixels -= max(0, overlapLast - overlapFirst + 1)
                }
            }
            if potentialPixels > pixelBudget { return false }
        }
        return true
    }

    private struct Bounds {
        let low: SIMD3<Double>
        let high: SIMD3<Double>

        /// AABB separation is a lower bound on actual shape separation. It can
        /// route additional corner/rotated cases to CPU, never prove clearance
        /// from a larger distance than the actual shapes have.
        func distance(to center: SIMD3<Double>, halfExtents: SIMD3<Double>) -> Double {
            var separation = SIMD3<Double>.zero
            for axis in 0..<3 {
                separation[axis] = max(0, max(low[axis] - center[axis] - halfExtents[axis],
                                               center[axis] - halfExtents[axis] - high[axis]))
            }
            return length(separation)
        }
    }

    /// Clip the real finite panel against the camera frustum. Its conservative
    /// AABB avoids rejecting ordinary close-up rigs merely because a source
    /// approaches a distant, invisible part of the panel. Every plane's padding
    /// is scaled by its normal length, so it represents the same meter margin.
    private static func visiblePanelBounds(geometry: StudyGeometry, camera: CameraFraming) -> Bounds? {
        let extent = geometry.panelHalfExtent, y = -geometry.radius
        var polygon: [SIMD3<Double>] = [
            .init(-extent, y, -extent), .init(extent, y, -extent),
            .init(extent, y, extent), .init(-extent, y, extent)
        ]
        let origin = vector(camera.position) - vector(geometry.center)
        let forward = vector(camera.forward), right = vector(camera.right), up = vector(camera.up)
        let halfWidth = CameraLens.sensorWidthMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let halfHeight = CameraLens.sensorHeightMillimeters / (2 * camera.lens.focalLengthMillimeters)
        let planes: [(SIMD3<Double>, Double)] = [
            (forward, CameraFraming.minimumDepthMeters),
            (forward * halfWidth + right, 0), (forward * halfWidth - right, 0),
            (forward * halfHeight + up, 0), (forward * halfHeight - up, 0)
        ]
        for (normal, minimum) in planes {
            guard !polygon.isEmpty else { return nil }
            let padding = surfaceMarginMeters * length(normal)
            func signedDistance(_ point: SIMD3<Double>) -> Double {
                dot(point - origin, normal) - minimum + padding
            }
            var clipped: [SIMD3<Double>] = []
            var previous = polygon.last!
            var previousDistance = signedDistance(previous)
            for current in polygon {
                let currentDistance = signedDistance(current)
                if (previousDistance >= 0) != (currentDistance >= 0) {
                    let t = previousDistance / (previousDistance - currentDistance)
                    clipped.append(previous + (current - previous) * t)
                }
                if currentDistance >= 0 { clipped.append(current) }
                previous = current; previousDistance = currentDistance
            }
            polygon = clipped
        }
        guard let first = polygon.first else { return nil }
        var low = first, high = first
        for point in polygon.dropFirst() {
            for axis in 0..<3 {
                low[axis] = min(low[axis], point[axis])
                high[axis] = max(high[axis], point[axis])
            }
        }
        return Bounds(low: low, high: high)
    }

    private static func vector(_ point: Position) -> SIMD3<Double> { .init(point.x, point.y, point.z) }
    private static func vector(_ direction: UnitDirection) -> SIMD3<Double> { .init(direction.x, direction.y, direction.z) }
    private static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
    private static func length(_ value: SIMD3<Double>) -> Double { sqrt(dot(value, value)) }
    private static func absolute(_ value: SIMD3<Double>) -> SIMD3<Double> { .init(abs(value.x), abs(value.y), abs(value.z)) }
    private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double { min(high, max(low, value)) }
}
