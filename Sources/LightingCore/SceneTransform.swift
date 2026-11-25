import Foundation

public enum SceneTransformError: Error, Equatable, LocalizedError {
    case invalidTransform, undefinedCameraDirection, outsideSupportedScene

    public var errorDescription: String? {
        switch self {
        case .invalidTransform: return "Enter finite position or rotation values."
        case .undefinedCameraDirection: return "Move the camera horizontally away from the subject before mirroring the lights."
        case .outsideSupportedScene: return "This move would place part of the setup outside the supported scene. Nothing was moved."
        }
    }
}

/// Atomic transforms preserve source identity, photometric settings and room context.
public enum SceneTransform {
    /// Rotates lights about the original subject, optionally mirrors them across
    /// the camera's center plane, then moves the whole setup to the destination.
    /// Only the input and completed arrangement must fit the supported scene;
    /// an intermediate rotation or reflection may temporarily leave its bounds.
    public static func arranged(_ source: LightingScene, subjectAt destination: Position,
                                rotatingLightsByDegrees angle: Double = 0,
                                mirroringLights mirror: Bool = false) throws -> LightingScene {
        guard destination.x.isFinite, destination.y.isFinite, destination.z.isFinite,
              angle.isFinite else { throw SceneTransformError.invalidTransform }
        var scene = try source.validated()
        let center = scene.subject
        let degrees = angle.truncatingRemainder(dividingBy: 360)
        let (c, s) = rotationComponents(degrees: degrees)
        var diagonal = 1.0, cross = 0.0
        if mirror {
            let dx = scene.camera.x - center.x, dz = scene.camera.z - center.z
            guard hypot(dx, dz) > 1e-9 else { throw SceneTransformError.undefinedCameraDirection }
            // Exact axis and diagonal planes remain signed coordinate swaps.
            if dx == 0 { diagonal = -1 }
            else if dz == 0 { diagonal = 1 }
            else if dx == dz { diagonal = 0; cross = 1 }
            else if dx == -dz { diagonal = 0; cross = -1 }
            else {
                let squaredDistance = dx * dx + dz * dz
                diagonal = (dx * dx - dz * dz) / squaredDistance
                cross = 2 * (dx * dz) / squaredDistance
            }
        }
        func shifted(_ p: Position) -> Position {
            .init(x: affineSum([destination.x, p.x, -center.x]),
                  y: affineSum([destination.y, p.y, -center.y]),
                  z: affineSum([destination.z, p.z, -center.z]))
        }
        func arrangedPosition(_ p: Position) -> Position {
            // Carry the original coordinate terms through the linear operations.
            // Rounding a displacement, intermediate world position or translation
            // first can turn a valid final boundary point into an outside value.
            let x = [p.x, -center.x], z = [p.z, -center.z]
            var needsExactProducts = false
            let rotatedX = scaledTerms(x, by: c, needsExact: &needsExactProducts)
                + scaledTerms(z, by: s, needsExact: &needsExactProducts)
            let rotatedZ = scaledTerms(x, by: -s, needsExact: &needsExactProducts)
                + scaledTerms(z, by: c, needsExact: &needsExactProducts)
            let finalX = mirror
                ? scaledTerms(rotatedX, by: diagonal, needsExact: &needsExactProducts)
                    + scaledTerms(rotatedZ, by: cross, needsExact: &needsExactProducts) : rotatedX
            let finalZ = mirror
                ? scaledTerms(rotatedX, by: cross, needsExact: &needsExactProducts)
                    + scaledTerms(rotatedZ, by: -diagonal, needsExact: &needsExactProducts) : rotatedZ
            func exactCoordinate(_ destination: Double, first: Double, second: Double) -> Double {
                // Expand the original expression, including both linear maps.
                // Its coefficients are the computed Doubles, not ideal real trig.
                var products = [[destination]]
                products += x.map { [$0, c, first] }
                products += z.map { [$0, s, first] }
                products += x.map { [$0, -s, second] }
                products += z.map { [$0, c, second] }
                return exactProductSum(products)
            }
            let horizontalX = needsExactProducts
                ? exactCoordinate(destination.x, first: mirror ? diagonal : 1, second: mirror ? cross : 0)
                : affineSum([destination.x] + finalX)
            let horizontalZ = needsExactProducts
                ? exactCoordinate(destination.z, first: mirror ? cross : 0, second: mirror ? -diagonal : 1)
                : affineSum([destination.z] + finalZ)
            return .init(x: horizontalX,
                         y: affineSum([destination.y, p.y, -center.y]),
                         z: horizontalZ)
        }
        scene.camera = shifted(scene.camera)
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = arrangedPosition(light.position)
            if let target = light.optics?.aimTarget { next.optics?.aimTarget = arrangedPosition(target) }
            if mirror, let roll = next.optics?.rollDegrees { next.optics?.rollDegrees = -roll }
            if degrees != 0 || mirror {
                Self.adjustVerticalRoll(from: light, to: &next, subject: center,
                                        nextSubject: destination) { direction in
                    let x = c * direction.x + s * direction.z
                    let z = -s * direction.x + c * direction.z
                    guard mirror else { return .init(x: x, y: direction.y, z: z) }
                    // Reflection reverses handedness, so reverse the width axis
                    // as in the standalone mirror without changing the rectangle.
                    return .init(x: -(diagonal * x + cross * z), y: -direction.y,
                                 z: -(cross * x - diagonal * z))
                }
            }
            return next
        }
        scene.subject = destination
        return try validatedResult(scene)
    }

    public static func translated(_ source: LightingScene, by offset: Position) throws -> LightingScene {
        guard offset.x.isFinite, offset.y.isFinite, offset.z.isFinite else {
            throw SceneTransformError.invalidTransform
        }
        var scene = try source.validated()
        translate(&scene, by: offset)
        return try validatedResult(scene)
    }

    private static func translate(_ scene: inout LightingScene, by offset: Position) {
        func shifted(_ p: Position) -> Position {
            .init(x: p.x + offset.x, y: p.y + offset.y, z: p.z + offset.z)
        }
        scene.subject = shifted(scene.subject)
        scene.camera = shifted(scene.camera)
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = shifted(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = shifted(target) }
            return next
        }
    }

    /// Rotates lights and their explicit aims about the subject's vertical axis.
    /// The camera and measured subject position stay fixed.
    public static func rotatingLights(_ source: LightingScene, byDegrees angle: Double) throws -> LightingScene {
        guard angle.isFinite else { throw SceneTransformError.invalidTransform }
        var scene = try source.validated()
        rotateLights(&scene, byDegrees: angle)
        return try validatedResult(scene)
    }

    private static func rotateLights(_ scene: inout LightingScene, byDegrees angle: Double) {
        let degrees = angle.truncatingRemainder(dividingBy: 360)
        guard degrees != 0 else { return }
        let (c, s) = rotationComponents(degrees: degrees)
        let center = scene.subject
        func rotated(_ p: Position) -> Position {
            let x = p.x - center.x, z = p.z - center.z
            return .init(x: center.x + c * x + s * z, y: p.y,
                         z: center.z - s * x + c * z)
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = rotated(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = rotated(target) }
            Self.adjustVerticalRoll(from: light, to: &next, subject: center) { direction in
                .init(x: c * direction.x + s * direction.z, y: direction.y,
                      z: -s * direction.x + c * direction.z)
            }
            return next
        }
    }

    private static func rotationComponents(degrees: Double) -> (Double, Double) {
        // Exact quarter turns must not push an on-boundary coordinate outside
        // the supported range through a small trigonometric residual.
        switch degrees {
        case 0: return (1, 0)
        case 90, -270: return (0, 1)
        case -90, 270: return (0, -1)
        case 180, -180: return (-1, 0)
        default:
            let radians = degrees * .pi / 180
            return (cos(radians), sin(radians))
        }
    }

    /// Reflects lighting across the camera's vertical center plane.
    public static func mirroringLights(_ source: LightingScene) throws -> LightingScene {
        var scene = try source.validated()
        try mirrorLights(&scene)
        return try validatedResult(scene)
    }

    private static func mirrorLights(_ scene: inout LightingScene) throws {
        let center = scene.subject
        let dx = scene.camera.x - center.x, dz = scene.camera.z - center.z
        let horizontalDistance = hypot(dx, dz)
        guard horizontalDistance > 1e-9 else { throw SceneTransformError.undefinedCameraDirection }
        // The reflection plane is vertical even when the camera is tilted.
        // The unnormalized form also keeps axis-aligned and diagonal camera
        // planes exact, avoiding square-root roundoff at the scene boundary.
        let squaredDistance = dx * dx + dz * dz
        let diagonal = (dx * dx - dz * dz) / squaredDistance
        let cross = 2 * (dx * dz) / squaredDistance
        func reflectedDirection(_ p: Position) -> Position {
            .init(x: diagonal * p.x + cross * p.z, y: p.y,
                  z: cross * p.x - diagonal * p.z)
        }
        func mirrored(_ p: Position) -> Position {
            // Use exact axis/diagonal formulas only for exact camera directions.
            // They avoid cancelling the source against its displacement and
            // preserve an axis-aligned plane's unchanged coordinate verbatim.
            if dx == 0 {
                return .init(x: 2 * center.x - p.x, y: p.y, z: p.z)
            }
            if dz == 0 {
                return .init(x: p.x, y: p.y, z: 2 * center.z - p.z)
            }
            if dx == dz {
                return .init(x: affineSum([p.z, center.x, -center.z]), y: p.y,
                             z: affineSum([p.x, center.z, -center.x]))
            }
            if dx == -dz {
                return .init(x: affineSum([-p.z, center.x, center.z]), y: p.y,
                             z: affineSum([-p.x, center.z, center.x]))
            }
            let x = p.x - center.x, z = p.z - center.z
            return .init(x: p.x + ((diagonal - 1) * x + cross * z), y: p.y,
                         z: p.z + (cross * x - (diagonal + 1) * z))
        }
        scene.lights = scene.lights.map { light in
            var next = light
            next.position = mirrored(light.position)
            if let target = next.optics?.aimTarget { next.optics?.aimTarget = mirrored(target) }
            if let roll = next.optics?.rollDegrees { next.optics?.rollDegrees = -roll }
            Self.adjustVerticalRoll(from: light, to: &next, subject: center) { direction in
                let reflected = reflectedDirection(direction)
                // A reflection reverses handedness; negating the width axis
                // restores the emitter normal without changing its rectangle.
                return .init(x: -reflected.x, y: -reflected.y, z: -reflected.z)
            }
            return next
        }
    }

    /// Keep representable product residuals alongside the original terms. A
    /// product with bits below 2^-1074 needs the integer fallback: even FMA cannot
    /// retain its whole residual. Signed coordinate swaps stay on the fast path.
    private static func scaledTerms(_ terms: [Double], by factor: Double,
                                    needsExact: inout Bool) -> [Double] {
        if factor == 0 { return [] }
        if factor == 1 { return terms }
        if factor == -1 { return terms.map { -$0 } }
        let factorExponent = binaryFactor(factor).exponent
        return terms.flatMap { term -> [Double] in
            if term != 0, binaryFactor(term).exponent + factorExponent < -1074 {
                needsExact = true
            }
            let product = term * factor
            let residual = (-product).addingProduct(term, factor)
            return [residual, product]
        }
    }

    /// Exact finite binary decomposition; a nonzero significand is odd, so its
    /// exponent identifies the lowest set bit without counting padding zeros.
    private static func binaryFactor(_ value: Double) -> (significand: UInt64, exponent: Int, negative: Bool) {
        let bits = value.bitPattern
        let encodedExponent = Int((bits >> 52) & 0x7ff)
        var significand = bits & 0x000f_ffff_ffff_ffff
        if encodedExponent != 0 { significand |= 1 << 52 }
        guard significand != 0 else { return (0, 0, false) }
        let trailing = significand.trailingZeroBitCount
        significand >>= trailing
        return (significand, (encodedExponent == 0 ? -1074 : encodedExponent - 1075) + trailing,
                bits >> 63 != 0)
    }

    /// Rare underflow path for an arrangement coordinate: at most nine terms,
    /// with at most three binary64 factors each. Products reach down to 2^-3222.
    /// Finite destinations and bounded scene/coefficient inputs need at most 67
    /// UInt64 limbs, including four carry bits. Only the final result is rounded,
    /// to nearest-even on the normal or subnormal binary64 lattice.
    private static func exactProductSum(_ terms: [[Double]]) -> Double {
        precondition(terms.count <= 9 && terms.allSatisfy { $0.count <= 3 })
        var products: [(words: [UInt64], exponent: Int, negative: Bool)] = []
        for factors in terms {
            var words: [UInt64] = [1]
            var exponent = 0, negative = false, isZero = false
            for factor in factors {
                precondition(factor.isFinite)
                let part = binaryFactor(factor)
                if part.significand == 0 { isZero = true; break }
                exponent += part.exponent
                negative = negative != part.negative
                var carry: UInt64 = 0
                for index in words.indices {
                    let multiplied = words[index].multipliedFullWidth(by: part.significand)
                    let (low, overflow) = multiplied.low.addingReportingOverflow(carry)
                    words[index] = low
                    carry = multiplied.high + (overflow ? 1 : 0)
                }
                if carry != 0 { words.append(carry) }
            }
            if !isZero { products.append((words, exponent, negative)) }
        }
        guard let origin = products.map({ $0.exponent }).min() else { return 0 }
        let highest = products.map {
            $0.exponent + 64 * $0.words.count - $0.words.last!.leadingZeroBitCount
        }.max()!
        let wordCount = (highest - origin + 4 + 63) / 64
        precondition((1...67).contains(wordCount), "Arrangement accumulator capacity exceeded")
        var positive = [UInt64](repeating: 0, count: wordCount)
        var negative = positive
        func add(_ value: UInt64, at start: Int, to target: inout [UInt64]) {
            var carry = value, index = start
            while carry != 0 {
                precondition(target.indices.contains(index), "Arrangement accumulator overflow")
                let (sum, overflow) = target[index].addingReportingOverflow(carry)
                target[index] = sum
                carry = overflow ? 1 : 0
                index += 1
            }
        }
        for product in products {
            let shift = product.exponent - origin
            let offset = shift / 64, bits = shift % 64
            for (index, word) in product.words.enumerated() {
                if product.negative {
                    add(word << bits, at: offset + index, to: &negative)
                    if bits != 0 { add(word >> (64 - bits), at: offset + index + 1, to: &negative) }
                } else {
                    add(word << bits, at: offset + index, to: &positive)
                    if bits != 0 { add(word >> (64 - bits), at: offset + index + 1, to: &positive) }
                }
            }
        }
        guard let difference = positive.indices.reversed().first(where: { positive[$0] != negative[$0] })
        else { return 0 }
        let isNegative = negative[difference] > positive[difference]
        var magnitude = isNegative ? negative : positive
        let smaller = isNegative ? positive : negative
        var borrow: UInt64 = 0
        for index in magnitude.indices {
            let (difference, firstBorrow) = magnitude[index].subtractingReportingOverflow(smaller[index])
            let (value, secondBorrow) = difference.subtractingReportingOverflow(borrow)
            magnitude[index] = value
            borrow = firstBorrow || secondBorrow ? 1 : 0
        }
        precondition(borrow == 0)
        let topWord = magnitude.indices.reversed().first { magnitude[$0] != 0 }!
        let topBit = topWord * 64 + 63 - magnitude[topWord].leadingZeroBitCount
        let discarded = max(0, max(topBit - 52, -1074 - origin))
        func word(at index: Int) -> UInt64 { magnitude.indices.contains(index) ? magnitude[index] : 0 }
        func bit(at index: Int) -> Bool { word(at: index / 64) & (1 << (index % 64)) != 0 }
        func hasBits(below count: Int) -> Bool {
            let wholeWords = count / 64, remaining = count % 64
            if magnitude.prefix(wholeWords).contains(where: { $0 != 0 }) { return true }
            return remaining != 0 && word(at: wholeWords) & ((1 << remaining) - 1) != 0
        }
        let offset = discarded / 64, bits = discarded % 64
        var rounded = word(at: offset) >> bits
        if bits != 0 { rounded |= word(at: offset + 1) << (64 - bits) }
        precondition(rounded < 1 << 53)
        if discarded > 0, bit(at: discarded - 1),
           hasBits(below: discarded - 1) || rounded & 1 != 0 {
            rounded += 1
        }
        // This integer is exactly representable; the scaling is also exact after
        // the explicit rounding above, including a carry into the normal range.
        return Double(sign: isNegative ? .minus : .plus, exponent: origin + discarded,
                      significand: Double(rounded))
    }

    /// Sum the affine terms once, retaining every addition residual. Even a
    /// tiny remaining term can decide which side of a halfway result is correct.
    private static func affineSum(_ terms: [Double]) -> Double {
        func sum(_ a: Double, _ b: Double) -> (value: Double, residual: Double) {
            let value = a + b
            let part = value - a
            return (value, (a - (value - part)) + (b - part))
        }
        var partials: [Double] = []
        for var term in terms {
            var count = 0
            for partial in partials {
                let combined = sum(term, partial)
                if combined.residual != 0 {
                    partials[count] = combined.residual
                    count += 1
                }
                term = combined.value
            }
            partials.removeSubrange(count..<partials.count)
            if term != 0 { partials.append(term) }
        }
        guard var result = partials.popLast() else { return 0 }
        var residual = 0.0
        while let partial = partials.popLast() {
            let combined = sum(result, partial)
            result = combined.value
            residual = combined.residual
            if residual != 0 { break }
        }
        // At a halfway result, a remaining term with the residual's sign
        // selects the adjacent value. The exact-step check distinguishes
        // this tie from a residual that must leave the rounded sum alone.
        if let remaining = partials.last,
           (residual > 0 && remaining > 0) || (residual < 0 && remaining < 0) {
            let step = 2 * residual
            let adjacent = result + step
            if adjacent - result == step { result = adjacent }
        }
        return result
    }

    private static func validatedResult(_ scene: LightingScene) throws -> LightingScene {
        guard let validated = try? scene.validated() else { throw SceneTransformError.outsideSupportedScene }
        return validated
    }

    /// World-up frames rotate covariantly except at their vertical fallback.
    /// Reconstruct only that case, preserving entered rolls elsewhere.
    private static func adjustVerticalRoll(from light: StudioLight, to next: inout StudioLight,
                                           subject: Position, nextSubject: Position? = nil,
                                           transform: (Position) -> Position) {
        guard light.effectiveOptics.kind == .rectangle,
              let original = transformFrame(source: light.position, target: light.target(subject: subject),
                                            rollDegrees: light.effectiveOptics.effectiveRollDegrees),
              let baseline = transformFrame(source: next.position,
                                            target: next.target(subject: nextSubject ?? subject)),
              hypot(original.normal.x, original.normal.z) <= 1e-12 ||
                hypot(baseline.normal.x, baseline.normal.z) <= 1e-12 else { return }
        let right = transform(.init(x: original.right.x, y: original.right.y, z: original.right.z))
        let cosine = right.x * baseline.right.x + right.y * baseline.right.y + right.z * baseline.right.z
        let sine = right.x * baseline.up.x + right.y * baseline.up.y + right.z * baseline.up.z
        let roll = atan2(sine, cosine) * 180 / .pi
        if roll != 0 || next.optics?.rollDegrees != nil { next.optics?.rollDegrees = roll }
    }

    /// Emitter orientation depends on direction, not world position. Intermediate
    /// arrangement coordinates may be outside the scene, so rebase only that case
    /// into a bounded direction before asking the shared frame for its basis.
    private static func transformFrame(source: Position, target: Position,
                                       rollDegrees: Double = 0) -> EmitterFrame? {
        if source.isValid, target.isValid {
            return EmitterFrame(source: source, target: target, rollDegrees: rollDegrees)
        }
        let x = target.x - source.x, y = target.y - source.y, z = target.z - source.z
        let scale = max(abs(x), max(abs(y), abs(z)))
        guard scale.isFinite, scale > 0 else { return nil }
        return EmitterFrame(source: .init(x: 0, y: 0, z: 0),
                            target: .init(x: x / scale, y: y / scale, z: z / scale),
                            rollDegrees: rollDegrees)
    }
}
