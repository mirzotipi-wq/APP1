function runEvidence() {
  const min = Number.MIN_VALUE;
  const normal = 2 ** -1022;
  function adjacent(value, offset) {
    const view = new DataView(new ArrayBuffer(8));
    view.setFloat64(0, value, false);
    view.setBigUint64(0, view.getBigUint64(0, false) + BigInt(offset), false);
    return view.getFloat64(0, false);
  }
  const cases = [];
  for (const count of [1, 64, 1024]) {
    const boundary = normal * count;
    const candidates = [0, min, 2*min, 31*min, 32*min, 33*min, 63*min, 64*min, 65*min,
      1023*min, 1024*min, 1025*min, normal/2, normal, adjacent(boundary,-1),
      boundary, adjacent(boundary,1), 1e-40, 900];
    for (const original of candidates) {
      const perSample = original / count;
      const scaled = original > 0 && (perSample === 0 || perSample < normal);
      const normalized = scaled ? 1 / count : perSample;
      const outputScale = scaled ? original : 1;
      cases.push({count, original, perSample, scaled, packed: Math.fround(normalized * outputScale),
        doubleEqual: Object.is(perSample, normalized * outputScale),
        floatEqual: Object.is(Math.fround(perSample), Math.fround(normalized * outputScale))});
    }
  }
  function area(grid, original) {
    const count = grid * grid, perSample = original / count;
    let direct = 0, normalized = 0;
    for (let row=0; row<grid; row++) {
      const y = ((row+0.5)/grid-0.5)*0.1;
      for (let col=0; col<grid; col++) {
        const x = ((col+0.5)/grid-0.5)*0.1;
        const r2 = x*x+y*y+0.1*0.1;
        const cosine = 0.1 / Math.sqrt(r2);
        direct += perSample * cosine * cosine / r2;
        normalized += (1/count) * cosine * cosine / r2;
      }
    }
    return {grid, original, sampleCount: count, perSample, packed: Math.fround(perSample),
      directLux: direct, unitOutputLux: normalized, groupScaledLux: normalized * original,
      receiverOutsideAreaGuard: 0.1*0.1 >= 0.05*0.05};
  }
  const near = [0, min].map(original => ({
    original,
    activeByOriginalDouble: original > 0,
    activeByPackedFloat: Math.fround(original / 64) > 0,
    samples: original > 0 ? 64 : 0,
    areas: original > 0 ? 1 : 0,
    originalSourceAreaGuardRejects: original > 0 && 0.049*0.049 < 0.05*0.05
  }));
  const result = {
    sourceSHA: "c9ff1a71c173774e7b7c794e475f8bdf5d633853",
    method: "JavaScript Number (binary64), Math.fround (binary32); arithmetic transcription, not Swift/Metal execution.",
    packingCases: cases.length,
    allDoubleProductsEqualBaseline: cases.every(c => c.doubleEqual),
    allPackedValuesEqualBaseline: cases.every(c => c.floatEqual),
    cases,
    fullFaceTinyRectangles: [area(8,min), area(32,min)],
    nearFieldActivity: near
  };
  if (!result.allDoubleProductsEqualBaseline || !result.allPackedValuesEqualBaseline) throw new Error("Packing mismatch");
  if (!result.fullFaceTinyRectangles.every(c => c.directLux === 0 && c.groupScaledLux > 0 && c.receiverOutsideAreaGuard)) throw new Error("Tiny-lux probe failed");
  if (near[0].originalSourceAreaGuardRejects || !near[1].originalSourceAreaGuardRejects || near[1].activeByPackedFloat) throw new Error("Activity probe failed");
  return result;
}
process.stdout.write(JSON.stringify(runEvidence(), null, 2) + '\n');
