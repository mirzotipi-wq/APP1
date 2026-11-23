#include "StudyKernel.h"

kernel void keyfillStudy(device const float4 *parameters [[buffer(0)]],
                         device const float4 *samples [[buffer(1)]],
                         device const float4 *areas [[buffer(2)]],
                         device uchar4 *rgba [[buffer(3)]],
                         constant uint2 &dimensions [[buffer(4)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= dimensions.x || gid.y >= dimensions.y) return;
    rgba[gid.y * dimensions.x + gid.x] = kfStudyPixel(parameters,samples,areas,
                                                     dimensions.x,dimensions.y,gid.x,gid.y);
}
