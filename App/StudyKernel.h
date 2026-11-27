#ifndef KEYFILL_STUDY_KERNEL_H
#define KEYFILL_STUDY_KERNEL_H

// Shared Float32 math for the Metal compute implementation and the portable
// host parity harness. Host execution is not evidence of GPU execution.
#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#define KF_DEVICE device
#define KF_THREAD thread
#else
#define KF_DEVICE
#define KF_THREAD
#endif

inline float3 kfXYZ(float4 v) { return float3(v.x, v.y, v.z); }
inline float kfSaturate(float v) { return clamp(v, 0.0f, 1.0f); }
inline bool kfFinite(float3 v) { return isfinite(v.x) && isfinite(v.y) && isfinite(v.z); }
inline uchar4 kfInvalid() { return uchar4(255, 0, 255, 0); }

inline float kfSphereHit(float3 origin, float3 ray, float radius, float minimum) {
    // Use the closest point on the ray instead of subtracting two large
    // squared distances. At a 20 m camera distance, b*b-c loses enough
    // Float32 precision to perturb the surface and produce false shadows.
    // Keep the length term: a normalized Float32 ray is not exactly unit.
    const float lengthSquared = dot(ray, ray);
    const float centerT = -dot(origin, ray) / lengthSquared;
    const float3 closest = origin + ray * centerT;
    const float discriminant = radius * radius - dot(closest, closest);
    if (discriminant < 0.0f) return INFINITY;
    const float root = sqrt(discriminant / lengthSquared);
    const float nearT = centerT - root, farT = centerT + root;
    if (nearT >= minimum) return nearT;
    return farT >= minimum ? farT : INFINITY;
}

inline bool kfInPanel(float3 p, float extent) {
    return abs(p.x) <= extent && abs(p.z) <= extent;
}

inline bool kfOccluded(float3 origin, float3 ray, float distance, float radius, float extent) {
    const float epsilon = 1e-5f;
    if (kfSphereHit(origin, ray, radius, epsilon) < distance - epsilon) return true;
    if (abs(ray.y) > 1e-12f) {
        const float t = (-radius - origin.y) / ray.y;
        if (t >= epsilon && t < distance - epsilon && kfInPanel(origin + ray * t, extent)) return true;
    }
    return false;
}

// pi * BRDF, with the same direct diffuse/GGX/Smith/Schlick model as Swift.
inline float kfResponse(float3 n, float3 l, float3 v, float nl, bool sphere) {
    if (!sphere) return 0.30f;
    const float nv = max(0.0f, dot(n, v));
    const float3 sum = l + v;
    if (nv <= 0.0f || dot(sum, sum) <= 0.0f) return 0.0f;
    const float3 h = normalize(sum);
    const float nh = kfSaturate(dot(n, h)), vh = kfSaturate(dot(v, h));
    const float roughness = 0.32f, alpha = roughness * roughness, a2 = alpha * alpha;
    const float d = nh * nh * (a2 - 1.0f) + 1.0f;
    const float distributionTimesPi = a2 / (d * d);
    const float denominator = 2.0f * (nl * sqrt(nv * nv * (1.0f - a2) + a2)
                                    + nv * sqrt(nl * nl * (1.0f - a2) + a2));
    const float fresnel = 0.04f + 0.96f * pow(1.0f - vh, 5.0f);
    return 0.18f * (1.0f - fresnel)
        + (denominator > 0.0f ? distributionTimesPi * fresnel / denominator : 0.0f);
}

// Positive receiver incidence in the normalized emitter square. One hemisphere
// plus two column planes creates at most seven vertices; eight slots are shared
// with the Swift two-hemisphere contract. Read/write buffers never overlap.
inline uint kfClipStudyPolygon(KF_THREAD const float3 *input, uint count, float3 plane,
                                KF_THREAD float3 *output) {
    if (count == 0) return 0;
    uint result = 0;
    float3 previous = input[count-1];
    float previousDistance = plane.x + plane.y*previous.x + plane.z*previous.y;
    for (uint i=0; i<count; ++i) {
        const float3 current = input[i];
        const float distance = plane.x + plane.y*current.x + plane.z*current.y;
        if ((previousDistance < 0.0f && distance > 0.0f) || (previousDistance > 0.0f && distance < 0.0f)) {
            const float t = previousDistance/(previousDistance-distance);
            output[result++] = previous+(current-previous)*t;
        }
        if (distance >= 0.0f) output[result++] = current;
        previous = current; previousDistance = distance;
    }
    return result;
}

struct KFStudySlice { float x; float lower; float upper; float weight; };

// Exact column area and centroid x, with vertical samples inside the lit region.
// As the clipped face fills the rectangle, this tends to the original midpoint
// grid. No full/partial cell switches between incompatible quadrature rules.
inline KFStudySlice kfStudyAreaSlice(KF_THREAD const float3 *polygon, uint count, float3 plane,
                                    uint col, uint grid, float minimum, float maximum) {
    const float a = minimum+(maximum-minimum)*(float)col/(float)grid;
    const float b = minimum+(maximum-minimum)*(float)(col+1)/(float)grid;
    const float3 zero = float3(0.0f,0.0f,0.0f);
    float3 left[8] = {zero,zero,zero,zero,zero,zero,zero,zero};
    float3 column[8] = {zero,zero,zero,zero,zero,zero,zero,zero};
    const uint leftCount = kfClipStudyPolygon(polygon,count,float3(-a,1.0f,0.0f),left);
    const uint columnCount = kfClipStudyPolygon(left,leftCount,float3(b,-1.0f,0.0f),column);
    if (columnCount < 3) return {0.0f,0.0f,0.0f,0.0f};
    const float3 anchor = column[0];
    float twiceArea = 0.0f, momentX = 0.0f;
    for (uint i=1; i+1<columnCount; ++i) {
        const float3 u = column[i]-anchor, v = column[i+1]-anchor;
        const float cross = abs(u.x*v.y-u.y*v.x);
        twiceArea += cross;
        momentX += cross*(u.x+v.x)/3.0f;
    }
    if (twiceArea <= 0.0f) return {0.0f,0.0f,0.0f,0.0f};
    const float x = clamp(anchor.x+momentX/twiceArea,a,b);
    const float atX = plane.x+plane.y*x;
    float lower = -1.0f, upper = 1.0f;
    if (plane.z > 0.0f) lower = max(lower,-atX/plane.z);
    else if (plane.z < 0.0f) upper = min(upper,-atX/plane.z);
    else if (atX <= 0.0f) return {0.0f,0.0f,0.0f,0.0f};
    if (lower >= upper) return {0.0f,0.0f,0.0f,0.0f};
    return {x,lower,upper,twiceArea*(float)grid/8.0f};
}

struct KFStudyIncident { float3 direction; float nl; float lux; bool valid; };
inline KFStudyIncident kfStudyIncident(float3 source, float candela, float4 axis, float3 p, float3 n) {
    const float3 delta = source-p;
    const float r2 = dot(delta,delta);
    if (r2 < 0.0025f) return {float3(0.0f,0.0f,0.0f),0.0f,0.0f,false};
    const float3 wi = delta/sqrt(r2);
    const float nl = kfSaturate(dot(n,wi));
    const float emitted = axis.w == 0.0f ? 1.0f : kfSaturate(-dot(kfXYZ(axis),wi));
    return {wi,nl,candela*emitted*nl/r2,true};
}

struct KFStudyContribution { float3 xyz; bool valid; };
inline KFStudyContribution kfStudyContribution(float3 source, float candela, float4 axis, float3 color,
                                               float3 p, float3 n, float3 view, float3 shadowOrigin,
                                               float radius, float extent, bool sphere) {
    const KFStudyIncident incident = kfStudyIncident(source,candela,axis,p,n);
    if (!incident.valid) return {float3(0.0f,0.0f,0.0f),false};
    if (incident.lux == 0.0f) return {float3(0.0f,0.0f,0.0f),true};
    const float3 segment = source-shadowOrigin;
    const float distance = sqrt(dot(segment,segment));
    if (kfOccluded(shadowOrigin,segment/distance,distance,radius,extent))
        return {float3(0.0f,0.0f,0.0f),true};
    return {color*(incident.lux*kfResponse(n,incident.direction,view,incident.nl,sphere)/1000.0f),true};
}

inline float3 kfBradford(float3 v) {
    return float3(0.8951f*v.x + 0.2664f*v.y - 0.1614f*v.z,
                  -0.7502f*v.x + 1.7135f*v.y + 0.0367f*v.z,
                  0.0389f*v.x - 0.0685f*v.y + 1.0296f*v.z);
}
inline float3 kfInverseBradford(float3 v) {
    return float3(0.9869929f*v.x - 0.1470543f*v.y + 0.1599627f*v.z,
                  0.4323053f*v.x + 0.5183603f*v.y + 0.0492912f*v.z,
                  -0.0085287f*v.x + 0.0400428f*v.y + 0.9684867f*v.z);
}
inline float kfCompression(float t, float channel, float luminance) {
    const float delta = channel - luminance;
    if (delta > 0.0f) return min(t, (1.0f - luminance) / delta);
    if (delta < 0.0f) return min(t, -luminance / delta);
    return t;
}
inline unsigned char kfEncode(float component, float luminance, float t) {
    const float x = kfSaturate(luminance + t * (component - luminance));
    const float display = x <= 0.0031308f ? 12.92f*x : 1.055f*pow(x, 1.0f/2.4f)-0.055f;
    return (unsigned char)floor(kfSaturate(display)*255.0f + 0.5f);
}
inline uchar4 kfDisplay(float3 xyz, float4 transform) {
    const float3 adapted = kfInverseBradford(kfBradford(xyz) * kfXYZ(transform)) * transform.w;
    const float3 rgb = float3(3.24096994f*adapted.x - 1.53738318f*adapted.y - 0.49861076f*adapted.z,
                              -0.96924364f*adapted.x + 1.87596750f*adapted.y + 0.04155506f*adapted.z,
                              0.05563008f*adapted.x - 0.20397696f*adapted.y + 1.05697151f*adapted.z);
    if (!kfFinite(rgb) || !isfinite(adapted.y) || adapted.y < 0.0f) return kfInvalid();
    if (adapted.y == 0.0f) return uchar4(0,0,0,255);
    const float luminance = adapted.y / (1.0f + adapted.y);
    const float3 tone = rgb / (1.0f + adapted.y);
    float t = kfCompression(1.0f, tone.x, luminance);
    t = kfCompression(t, tone.y, luminance);
    t = kfCompression(t, tone.z, luminance);
    return uchar4(kfEncode(tone.x,luminance,t), kfEncode(tone.y,luminance,t), kfEncode(tone.z,luminance,t), 255);
}

inline uchar4 kfStudyPixel(KF_DEVICE const float4 *parameters,
                           KF_DEVICE const float4 *samples,
                           KF_DEVICE const float4 *areas,
                           uint width, uint height, uint x, uint y) {
    if (width < 24 || width > 192 || width % 3 != 0 || height != width * 2 / 3
        || x >= width || y >= height) return kfInvalid();
    // Validate packed metadata before integer conversion or buffer indexing.
    const float rawSampleCount = parameters[5].x, rawAreaCount = parameters[5].y;
    if (!isfinite(rawSampleCount) || rawSampleCount < 0.0f || rawSampleCount > 768.0f
        || floor(rawSampleCount) != rawSampleCount
        || !isfinite(rawAreaCount) || rawAreaCount < 0.0f || rawAreaCount > 12.0f
        || floor(rawAreaCount) != rawAreaCount) return kfInvalid();
    const float rawGrid = parameters[5].w;
    if (rawGrid != 8.0f) return kfInvalid();
    const uint sampleCount = (uint)rawSampleCount, areaCount = (uint)rawAreaCount;
    const uint grid = (uint)rawGrid;
    const float3 origin = kfXYZ(parameters[0]), forward = kfXYZ(parameters[1]);
    const float3 right = kfXYZ(parameters[2]), up = kfXYZ(parameters[3]);
    const float radius = parameters[2].w, extent = parameters[3].w;
    const float px = (2.0f*((float)x+0.5f)/(float)width-1.0f) * parameters[0].w;
    const float py = (1.0f-2.0f*((float)y+0.5f)/(float)height) * parameters[1].w;
    const float3 ray = normalize(forward + right*px + up*py);
    const float minimum = parameters[5].z / dot(ray,forward);
    const float sphereT = kfSphereHit(origin,ray,radius,minimum);
    float planeT = INFINITY;
    if (ray.y < -1e-12f) {
        const float t = (-radius-origin.y)/ray.y;
        if (t >= minimum && kfInPanel(origin+ray*t,extent)) planeT = t;
    }
    const bool sphere = sphereT < planeT;
    if (!sphere && !isfinite(planeT)) return uchar4(18,20,24,255);
    const float3 p = origin + ray*(sphere ? sphereT : planeT);
    const float3 n = sphere ? normalize(p) : float3(0.0f,1.0f,0.0f);
    const float3 shadowOrigin = p+n*1e-5f;
    for (uint i=0; i<areaCount; ++i) {
        const float4 center = areas[3*i], ar = areas[3*i+1], au = areas[3*i+2];
        const float3 delta = p-kfXYZ(center);
        const float ax = clamp(dot(delta,kfXYZ(ar)),-ar.w,ar.w);
        const float ay = clamp(dot(delta,kfXYZ(au)),-au.w,au.w);
        const float3 separation = delta-kfXYZ(ar)*ax-kfXYZ(au)*ay;
        if (dot(separation,separation) < center.w*center.w) return kfInvalid();
    }
    float3 xyz = float3(0.0f,0.0f,0.0f);
    for (uint i=0; i<sampleCount;) {
        const float4 source = samples[3*i], axis = samples[3*i+1], color = samples[3*i+2];
        if (color.w == 0.0f) {
            const KFStudyContribution c = kfStudyContribution(kfXYZ(source),source.w,axis,kfXYZ(color),
                                                            p,n,-ray,shadowOrigin,radius,extent,sphere);
            if (!c.valid) return kfInvalid();
            xyz += c.xyz;
            ++i;
            continue;
        }
        if (!isfinite(color.w) || color.w < 1.0f || color.w > (float)areaCount
            || floor(color.w) != color.w) return kfInvalid();
        const uint areaIndex = (uint)color.w-1;
        if (areaIndex >= areaCount || i+grid*grid > sampleCount) return kfInvalid();
        const float4 center = areas[3*areaIndex], ar = areas[3*areaIndex+1], au = areas[3*areaIndex+2];
        const float3 plane = float3(dot(n,kfXYZ(center)-p),dot(n,kfXYZ(ar))*ar.w,dot(n,kfXYZ(au))*au.w);
        const float span = abs(plane.y)+abs(plane.z);
        if (plane.x >= span) {
            for (uint offset=0; offset<grid*grid; ++offset) {
                const float4 full = samples[3*(i+offset)];
                const KFStudyContribution c = kfStudyContribution(kfXYZ(full),full.w,axis,kfXYZ(color),
                                                                p,n,-ray,shadowOrigin,radius,extent,sphere);
                if (!c.valid) return kfInvalid();
                xyz += c.xyz;
            }
        } else if (plane.x > -span) {
            const float3 square[4] = {float3(-1.0f,-1.0f,0.0f),float3(1.0f,-1.0f,0.0f),
                                     float3(1.0f,1.0f,0.0f),float3(-1.0f,1.0f,0.0f)};
            const float3 zero = float3(0.0f,0.0f,0.0f);
            float3 polygon[8] = {zero,zero,zero,zero,zero,zero,zero,zero};
            const uint count = kfClipStudyPolygon(square,4,plane,polygon);
            if (count >= 3) {
                float minimum = polygon[0].x, maximum = minimum;
                for (uint j=1; j<count; ++j) { minimum = min(minimum,polygon[j].x); maximum = max(maximum,polygon[j].x); }
                for (uint col=0; col<grid; ++col) {
                    const KFStudySlice slice = kfStudyAreaSlice(polygon,count,plane,col,grid,minimum,maximum);
                    if (slice.weight == 0.0f) continue;
                    for (uint row=0; row<grid; ++row) {
                        const float sy = slice.lower+(slice.upper-slice.lower)*((float)row+0.5f)/(float)grid;
                        const float3 position = kfXYZ(center)+kfXYZ(ar)*(slice.x*ar.w)+kfXYZ(au)*(sy*au.w);
                        const KFStudyContribution c = kfStudyContribution(position,source.w*slice.weight,axis,kfXYZ(color),
                                                                        p,n,-ray,shadowOrigin,radius,extent,sphere);
                        if (!c.valid) return kfInvalid();
                        xyz += c.xyz;
                    }
                }
            }
        }
        i += grid*grid;
    }
    return kfDisplay(xyz,parameters[4]);
}

#undef KF_DEVICE
#undef KF_THREAD
#endif
