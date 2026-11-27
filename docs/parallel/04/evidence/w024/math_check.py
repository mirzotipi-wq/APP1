import math

RADIUS = 0.22
MARGIN_SCALE = 32 * 2**-23


def slopes(distance):
    margin = MARGIN_SCALE * distance
    inner, outer = max(0, RADIUS - margin), RADIUS + margin
    return (
        inner * inner / (distance * distance - inner * inner),
        outer * outer / (distance * distance - outer * outer),
    )


def interval_count(width, distance, focal):
    height = width * 2 // 3
    half_w, half_h = 18 / focal, 12 / focal
    inner_q, outer_q = slopes(distance)
    total, duplicate_centers = 0, 0

    def indices(lower, upper):
        index_margin = 32 * 2**-52 * width
        first = max(0, math.ceil(math.nextafter(width * (lower / half_w + 1) / 2 - 0.5, -math.inf) - index_margin))
        last = min(width - 1, math.floor(math.nextafter(width * (upper / half_w + 1) / 2 - 0.5, math.inf) + index_margin))
        return (first, last) if first <= last else None

    for y in range(height):
        py = (1 - 2 * (y + 0.5) / height) * half_h
        squared_y = py * py
        slope_margin = 32 * 2**-52 * max(outer_q, squared_y)
        outer_x2 = outer_q - squared_y
        if outer_x2 < -slope_margin:
            continue
        outer_x = math.sqrt(max(0, outer_x2 + slope_margin))
        inner_x = math.sqrt(max(0, inner_q - squared_y - slope_margin))
        negative, positive = indices(-outer_x, -inner_x), indices(inner_x, outer_x)
        if negative:
            total += negative[1] - negative[0] + 1
        if positive:
            total += positive[1] - positive[0] + 1
            if negative:
                overlap = max(0, min(negative[1], positive[1]) - max(negative[0], positive[0]) + 1)
                total -= overlap
                duplicate_centers += overlap
    return total, duplicate_centers


def direct_count(width, distance, focal):
    height = width * 2 // 3
    half_w, half_h = 18 / focal, 12 / focal
    inner_q, outer_q = slopes(distance)
    total = 0
    for y in range(height):
        py = (1 - 2 * (y + 0.5) / height) * half_h
        for x in range(width):
            px = (2 * (x + 0.5) / width - 1) * half_w
            total += inner_q <= px * px + py * py <= outer_q
    return total


cases = {(width, distance, focal) for width in range(24, 193, 3)
         for distance in (0.2700001, 1.0, 20.0) for focal in (14.0, 50.0, 200.0)}
# Solve for distances placing a pixel center on either shell boundary, then
# perturb each solution one representable Double in both directions.
for width in (24, 27, 51, 99, 165, 192):
    height = width * 2 // 3
    for focal in (14.0, 50.0, 200.0):
        for x, y in ((width // 2, height // 6), (width // 4, height // 3), (0, 0)):
            px = (2 * (x + 0.5) / width - 1) * 18 / focal
            py = (1 - 2 * (y + 0.5) / height) * 12 / focal
            radial = math.sqrt(px * px + py * py)
            tangent = radial / math.sqrt(1 + radial * radial)
            for sign in (-1, 0, 1):
                distance = RADIUS / (tangent - sign * MARGIN_SCALE)
                for candidate in (math.nextafter(distance, -math.inf), distance, math.nextafter(distance, math.inf)):
                    if RADIUS + 0.05 < candidate <= 20:
                        cases.add((width, candidate, focal))

extras, duplicates = 0, 0
for width, distance, focal in sorted(cases):
    actual, overlap = interval_count(width, distance, focal)
    expected = direct_count(width, distance, focal)
    assert actual >= expected, (width, distance, focal, actual, expected)
    extras += actual - expected
    duplicates += overlap
    budget = width * (width * 2 // 3) // 510
    assert (actual > budget) == (actual * 510 > width * (width * 2 // 3))
assert duplicates > 0, "Odd-width overlapping center ranges were not exercised"
assert interval_count(24, 3, 161.27198111190464)[0] > 24 * 16 // 510
print(f"PASS: {len(cases)} cases; analytic counts never below direct enumeration; {extras} conservative extras; {duplicates} overlapping center counts removed; integer budget comparison matches exact ratio.")
