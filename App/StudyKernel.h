#ifndef KEYFILL_STUDY_KERNEL_H
#define KEYFILL_STUDY_KERNEL_H

// Shared Float32 math for the Metal compute implementation and the portable
// host parity harness. Host execution is not evidence of GPU execution.
#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#define KF_DEVICE device
#else
#define KF_DEVICE
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
    const float3 origin = kfXYZ(parameters[0]), forward = kfXYZ(parameters[1]);
    const float3 right = kfXYZ(parameters[2]), up = kfXYZ(parameters[3]);
    const float radius = parameters[2].w, extent = parameters[3].w;
    const uint sampleCount = (uint)parameters[5].x, areaCount = (uint)parameters[5].y;
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
    for (uint i=0; i<sampleCount; ++i) {
        const float4 source = samples[3*i], axis = samples[3*i+1], color = samples[3*i+2];
        const float3 delta = kfXYZ(source)-p;
        const float r2 = dot(delta,delta);
        if (r2 < 0.0025f) return kfInvalid();
        const float3 wi = delta/sqrt(r2);
        const float nl = kfSaturate(dot(n,wi));
        if (nl == 0.0f) continue;
        const float emitted = axis.w == 0.0f ? 1.0f : kfSaturate(-dot(kfXYZ(axis),wi));
        if (emitted == 0.0f) continue;
        const float3 segment = kfXYZ(source)-shadowOrigin;
        const float distance = sqrt(dot(segment,segment));
        if (kfOccluded(shadowOrigin,segment/distance,distance,radius,extent)) continue;
        const float lux = source.w*emitted*nl/r2;
        xyz += kfXYZ(color)*(lux*kfResponse(n,wi,-ray,nl,sphere)/1000.0f);
    }
    return kfDisplay(xyz,parameters[4]);
}

#undef KF_DEVICE
#endif
