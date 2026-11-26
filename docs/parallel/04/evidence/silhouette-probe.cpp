// Executes the shipped shared Float32 kernel. The independent Double geometry
// below transcribes the no-light CPU intersection equations; this is NOT a
// Swift renderer run, a six-fixture parity pass, or actual Metal execution.
#define main keyfill_existing_host_harness_main
#include "../../../../scripts/verify-kernel-host.cpp"
#undef main
#include <iomanip>

int main() {
    constexpr uint width = 24, height = 16;
    const double focal = 161.27198111190464, distance = 3, radius = 0.22;
    const double halfWidth = 36 / (2 * focal), halfHeight = 24 / (2 * focal);
    const float4 parameters[] = {
        {0, 0, float(distance), float(halfWidth)}, {0, 0, -1, float(halfHeight)},
        {1, 0, 0, float(radius)}, {0, 1, 0, 3}, {1, 1, 1, 1}, {0, 0, 0.05f, 8}
    };
    const float4 unused[] = {{0, 0, 0, 0}};
    uint mismatches = 0, maximum = 0, outliers = 0, invalid = 0;
    uint64_t total = 0;
    for (uint y = 0; y < height; ++y) for (uint x = 0; x < width; ++x) {
        const double px = (2 * (double(x) + 0.5) / width - 1) * halfWidth;
        const double py = (1 - 2 * (double(y) + 0.5) / height) * halfHeight;
        const double magnitude = std::sqrt(px * px + py * py + 1);
        const double rx = px / magnitude, ry = py / magnitude, rz = -1 / magnitude;
        const double minimum = 0.05 / -rz;
        const double b = distance * rz, c = distance * distance - radius * radius;
        const double discriminant = b * b - c;
        double sphereT = INFINITY, planeT = INFINITY;
        if (discriminant >= 0) {
            const double near = -b - std::sqrt(discriminant), far = -b + std::sqrt(discriminant);
            if (near >= minimum) sphereT = near;
            else if (far >= minimum) sphereT = far;
        }
        if (ry < -1e-12) {
            const double t = -radius / ry;
            if (t >= minimum && std::abs(rx * t) <= 3 && std::abs(distance + rz * t) <= 3) planeT = t;
        }
        const bool hit = std::isfinite(sphereT) || std::isfinite(planeT);
        const uchar4 reference = hit ? uchar4(0, 0, 0, 255) : uchar4(18, 20, 24, 255);
        const uchar4 candidate = kfStudyPixel(parameters, unused, unused, width, height, x, y);
        const uint e[] = {uint(std::abs(int(reference.x) - candidate.x)), uint(std::abs(int(reference.y) - candidate.y)), uint(std::abs(int(reference.z) - candidate.z))};
        if (e[0] || e[1] || e[2]) {
            ++mismatches;
            std::cout << "pixel=" << x << "," << y << " double-discriminant=" << std::setprecision(17) << discriminant << " reference=" << int(reference.x) << "," << int(reference.y) << "," << int(reference.z) << " shared=" << int(candidate.x) << "," << int(candidate.y) << "," << int(candidate.z) << "\n";
        }
        for (uint error : e) { total += error; maximum = std::max(maximum, error); outliers += error > 4; }
        invalid += candidate.w == 0;
    }
    const double channels = double(width) * height * 3;
    std::cout << "shared-kernel-vs-independent-double-geometry: pixels=" << mismatches << " mean=" << total / channels << " max=" << maximum << " fraction-over-4=" << outliers / channels << " invalid=" << invalid << "\n";
    // A successful reproduction exits zero, without pretending parity passed.
    return mismatches == 2 && outliers / channels > 0.005 ? 0 : 1;
}
